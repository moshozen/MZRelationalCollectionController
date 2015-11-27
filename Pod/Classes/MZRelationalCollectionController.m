//
//  MZRelationalCollectionController.m
//
//  Created by Mat Trudel on 2014-10-15.
//  Copyright (c) 2014 Moshozen Inc. All rights reserved.
//

#import "MZRelationalCollectionController.h"

#import "NSPredicate+KeypathExtraction.h"

static const void *sortChangeContext = @"sortChangeContext";
static const void *filteringPredicateContext = @"filteringPredicateContext";

@interface MZRelationalCollectionController ()
@property id object;
@property NSString *relation;
@property NSPredicate *filteringPredicate;
@property NSArray *sortDescriptors;
@property NSArray *observedChildKeyPaths;
@property NSMutableArray *mutableCollection;
@property NSIndexSet *lastExchangedIndexSet;
@end

@implementation MZRelationalCollectionController

+ (instancetype)collectionControllerForRelation:(NSString *)key onObject:(id)object filteredBy:(NSPredicate *)filteringPredicate sortedBy:(NSArray *)sortDescriptors observingChildKeyPaths:(NSArray *)childKeyPaths delegate:(id<MZRelationalCollectionControllerDelegate>)delegate {
    return [[self alloc] initWithRelation:key onObject:object filteredBy:filteringPredicate sortedBy:sortDescriptors observingChildKeyPaths:childKeyPaths delegate:delegate];
}

- (instancetype)initWithRelation:(NSString *)key onObject:(id)object filteredBy:(NSPredicate *)filteringPredicate sortedBy:(NSArray *)sortDescriptors observingChildKeyPaths:(NSArray *)childKeyPaths delegate:(id<MZRelationalCollectionControllerDelegate>)delegate {
    if (self = [super init]) {
        self.object = object;
        self.relation = key;
        self.filteringPredicate = filteringPredicate ?: [NSPredicate predicateWithValue:YES];
        self.sortDescriptors = sortDescriptors;
        self.observedChildKeyPaths = childKeyPaths;
        self.delegate = delegate;
        [self.object addObserver:self forKeyPath:key options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew context:nil];
    }
    return self;
}

- (void)dealloc {
    for (id obj in [self.object valueForKey:self.relation]) {
        [self stopObservingRelationObject:obj];
    }
    for (id obj in self.collection) {
        [self stopObservingCollectionObject:obj];
    }
    [self.object removeObserver:self forKeyPath:self.relation];
}

#pragma mark - Accessors

- (NSArray *)collection {
    return self.mutableCollection;
}

#pragma mark - Change handling

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if (object == self.object) {
        [self handleChangeToRootObject:change];
    }
    if (context == filteringPredicateContext) { // Safe to compare pointers since it's a const
        [self handleChangeToFilterKeypathsFromObject:object];
    }
    if (context == sortChangeContext) { // Safe to compare pointers since it's a const
        [self handleChangeToSortOrderFromCollectionObject:object];
    }
    if (object != self.object && context == nil) {
        [self handleChangeToCollectionObject:object forKeyPath:keyPath change:change];
    }
}

- (void)handleChangeToRootObject:(NSDictionary *)change {
    if ([change[NSKeyValueChangeKindKey] integerValue] == NSKeyValueChangeSetting) {
        if ([change[NSKeyValueChangeOldKey] conformsToProtocol:@protocol(NSFastEnumeration)]) {
            for (id oldObj in change[NSKeyValueChangeOldKey]) {
                [self stopObservingRelationObject:oldObj];
            }
        }
        for (id oldObj in self.collection) {
            [self stopObservingCollectionObject:oldObj];
        }
        if ([[self.object valueForKey:self.relation] isKindOfClass:[NSSet class]]) {
            self.mutableCollection = [[[[self.object valueForKey:self.relation] filteredSetUsingPredicate:self.filteringPredicate] sortedArrayUsingDescriptors:self.sortDescriptors] mutableCopy];
        } else if ([[self.object valueForKey:self.relation] isKindOfClass:[NSArray class]]) {
            self.mutableCollection = [[[[self.object valueForKey:self.relation] filteredArrayUsingPredicate:self.filteringPredicate] sortedArrayUsingDescriptors:self.sortDescriptors] mutableCopy];
        } else {
            // In this case, the only valid condition is the relation being nil. Any other type of collection is unsupported
            NSAssert([self.object valueForKey:self.relation] == nil, @"Encountered a relation collection of unsupported type: %@", [self.object valueForKey:self.relation]);
            self.mutableCollection = [NSMutableArray array];
        }
        for (id obj in self.collection) {
            [self startObservingCollectionObject:obj];
        }
        for (id obj in [self.object valueForKey:self.relation]) {
            [self startObservingRelationObject:obj];
        }
    } else if ([change[NSKeyValueChangeKindKey] integerValue] == NSKeyValueChangeInsertion) {
        if ([self.delegate respondsToSelector:@selector(relationalCollectionControllerWillChangeContent:)]) {
            [self.delegate relationalCollectionControllerWillChangeContent:self];
        }
        NSArray *newObjects;
        if ([change[NSKeyValueChangeNewKey] isKindOfClass:[NSSet class]]) {
            newObjects = [[change[NSKeyValueChangeNewKey] filteredSetUsingPredicate:self.filteringPredicate] allObjects];
        } else if ([change[NSKeyValueChangeNewKey] isKindOfClass:[NSArray class]]) {
            newObjects = [change[NSKeyValueChangeNewKey] filteredArrayUsingPredicate:self.filteringPredicate];
        }
        [self.mutableCollection addObjectsFromArray:newObjects];
        [self.mutableCollection sortUsingDescriptors:self.sortDescriptors];
        for (id newObject in newObjects) {
            [self startObservingCollectionObject:newObject];
            if ([self.delegate respondsToSelector:@selector(relationalCollectionController:insertedObject:atIndex:)]) {
                [self.delegate relationalCollectionController:self insertedObject:newObject atIndex:[self.mutableCollection indexOfObject:newObject]];
            }
        }
        if ([change[NSKeyValueChangeNewKey] conformsToProtocol:@protocol(NSFastEnumeration)]) {
            for (id obj in change[NSKeyValueChangeNewKey]) {
                [self startObservingRelationObject:obj];
            }
        }
        if ([self.delegate respondsToSelector:@selector(relationalCollectionControllerDidChangeContent:)]) {
            [self.delegate relationalCollectionControllerDidChangeContent:self];
        }
    } else if ([change[NSKeyValueChangeKindKey] integerValue] == NSKeyValueChangeRemoval) {
        if ([self.delegate respondsToSelector:@selector(relationalCollectionControllerWillChangeContent:)]) {
            [self.delegate relationalCollectionControllerWillChangeContent:self];
        }
        NSArray *oldObjects;
        if ([change[NSKeyValueChangeOldKey] isKindOfClass:[NSSet class]]) {
            oldObjects = [change[NSKeyValueChangeOldKey] allObjects];
        } else if ([change[NSKeyValueChangeOldKey] isKindOfClass:[NSArray class]]) {
            oldObjects = change[NSKeyValueChangeOldKey];
        }
        NSMutableDictionary *oldIndexMap = [NSMutableDictionary dictionary];

        for (id oldObject in oldObjects) {
            [self stopObservingRelationObject:oldObject];
            if ([self.mutableCollection containsObject:oldObject]) {
                [oldIndexMap setObject:oldObject forKey:@([self.mutableCollection indexOfObject:oldObject])];
                [self stopObservingCollectionObject:oldObject];
            }
        }
        [self.mutableCollection removeObjectsInArray:oldObjects];
        if ([self.delegate respondsToSelector:@selector(relationalCollectionController:removedObject:atIndex:)]) {
            for (NSNumber *oldIndex in oldIndexMap) {
                [self.delegate relationalCollectionController:self removedObject:oldIndexMap[oldIndex] atIndex:oldIndex.integerValue];
            }
        }
        if ([self.delegate respondsToSelector:@selector(relationalCollectionControllerDidChangeContent:)]) {
            [self.delegate relationalCollectionControllerDidChangeContent:self];
        }
    } else if ([change[NSKeyValueChangeKindKey] integerValue] == NSKeyValueChangeReplacement) {
        if (!self.sortDescriptors) {
            if (self.lastExchangedIndexSet) {
                NSAssert(self.lastExchangedIndexSet.count == 1,  @"Can't (yet) handle cases where NSArray exchanges involve more than 1 item");
                if ([self.delegate respondsToSelector:@selector(relationalCollectionControllerWillChangeContent:)]) {
                    [self.delegate relationalCollectionControllerWillChangeContent:self];
                }
                NSUInteger oldIndex = self.lastExchangedIndexSet.firstIndex;
                NSUInteger newIndex = [change[NSKeyValueChangeIndexesKey] firstIndex];
                id object = [change[NSKeyValueChangeNewKey] firstObject];
                [self.mutableCollection exchangeObjectAtIndex:oldIndex withObjectAtIndex:newIndex];
                if ([self.delegate respondsToSelector:@selector(relationalCollectionController:movedObject:fromIndex:toIndex:)]) {
                    [self.delegate relationalCollectionController:self movedObject:object fromIndex:oldIndex toIndex:newIndex];
                }
                self.lastExchangedIndexSet = nil;
                if ([self.delegate respondsToSelector:@selector(relationalCollectionControllerDidChangeContent:)]) {
                    [self.delegate relationalCollectionControllerDidChangeContent:self];
                }
            } else {
                self.lastExchangedIndexSet = change[NSKeyValueChangeIndexesKey];
            }
        }
    }
}

- (void)handleChangeToSortOrderFromCollectionObject:(id)object {
    if ([self.delegate respondsToSelector:@selector(relationalCollectionControllerWillChangeContent:)]) {
        [self.delegate relationalCollectionControllerWillChangeContent:self];
    }
    NSUInteger oldIndex = [self.mutableCollection indexOfObject:object];
    [self.mutableCollection sortUsingDescriptors:self.sortDescriptors];
    NSUInteger newIndex = [self.mutableCollection indexOfObject:object];
    if (oldIndex != newIndex) {
        if ([self.delegate respondsToSelector:@selector(relationalCollectionController:movedObject:fromIndex:toIndex:)]) {
            [self.delegate relationalCollectionController:self movedObject:object fromIndex:oldIndex toIndex:newIndex];
        }
        if ([self.delegate respondsToSelector:@selector(relationalCollectionControllerDidChangeContent:)]) {
            [self.delegate relationalCollectionControllerDidChangeContent:self];
        }
    }
}

- (void)handleChangeToFilterKeypathsFromObject:(id)object {
    if ([self.collection containsObject:object] && ![self.filteringPredicate evaluateWithObject:object]) {
        if ([self.delegate respondsToSelector:@selector(relationalCollectionControllerWillChangeContent:)]) {
            [self.delegate relationalCollectionControllerWillChangeContent:self];
        }
        NSUInteger oldIndex = [self.mutableCollection indexOfObject:object];
        [self stopObservingCollectionObject:object];
        [self.mutableCollection removeObject:object];
        if ([self.delegate respondsToSelector:@selector(relationalCollectionController:removedObject:atIndex:)]) {
            [self.delegate relationalCollectionController:self removedObject:object atIndex:oldIndex];
        }
        if ([self.delegate respondsToSelector:@selector(relationalCollectionControllerDidChangeContent:)]) {
            [self.delegate relationalCollectionControllerDidChangeContent:self];
        }
    } else if (![self.collection containsObject:object] && [self.filteringPredicate evaluateWithObject:object]) {
        if ([self.delegate respondsToSelector:@selector(relationalCollectionControllerWillChangeContent:)]) {
            [self.delegate relationalCollectionControllerWillChangeContent:self];
        }
        [self.mutableCollection addObject:object];
        [self.mutableCollection sortUsingDescriptors:self.sortDescriptors];
        [self startObservingCollectionObject:object];
        if ([self.delegate respondsToSelector:@selector(relationalCollectionController:insertedObject:atIndex:)]) {
            [self.delegate relationalCollectionController:self insertedObject:object atIndex:[self.mutableCollection indexOfObject:object]];
        }
        if ([self.delegate respondsToSelector:@selector(relationalCollectionControllerDidChangeContent:)]) {
            [self.delegate relationalCollectionControllerDidChangeContent:self];
        }
    }
}

- (void)handleChangeToCollectionObject:(id)object forKeyPath:(NSString *)keyPath change:(NSDictionary *)change {
    NSUInteger index = [self.collection indexOfObject:object];
    if (index != NSNotFound) {
        if ([self.delegate respondsToSelector:@selector(relationalCollectionControllerWillChangeContent:)]) {
            [self.delegate relationalCollectionControllerWillChangeContent:self];
        }
        if ([self.delegate respondsToSelector:@selector(relationalCollectionController:updatedObject:atIndex:changedKeyPath:)]) {
            [self.delegate relationalCollectionController:self updatedObject:object atIndex:index changedKeyPath:keyPath];
        }
        if ([self.delegate respondsToSelector:@selector(relationalCollectionControllerDidChangeContent:)]) {
            [self.delegate relationalCollectionControllerDidChangeContent:self];
        }
    }
}

#pragma mark - Setup and teardown of object observation

- (void)startObservingRelationObject:(id)object {
    for (NSString *keypath in self.childKeyPathsForFilter) {
        [object addObserver:self forKeyPath:keypath options:0 context:(void *)filteringPredicateContext];
    }
}

- (void)stopObservingRelationObject:(id)object {
    for (NSString *keypath in self.childKeyPathsForFilter) {
        [object removeObserver:self forKeyPath:keypath context:(void *)filteringPredicateContext];
    }
}

- (void)startObservingCollectionObject:(id)object {
    for (NSString *keypath in self.observedChildKeyPaths) {
        [object addObserver:self forKeyPath:keypath options:0 context:nil];
    }
    for (NSString *keypath in self.childKeyPathsForSort) {
        [object addObserver:self forKeyPath:keypath options:0 context:(void *)sortChangeContext];
    }
}

- (void)stopObservingCollectionObject:(id)object {
    for (NSString *keypath in self.observedChildKeyPaths) {
        [object removeObserver:self forKeyPath:keypath context:nil];
    }
    for (NSString *keypath in self.childKeyPathsForSort) {
        [object removeObserver:self forKeyPath:keypath context:(void *)sortChangeContext];
    }
}

- (NSSet *)childKeyPathsForFilter {
    return [self.filteringPredicate mz_referencedKeyPaths];
}

- (NSArray *)childKeyPathsForSort {
    return [self.sortDescriptors valueForKey:@"key"];
}

@end
