//
//  MZRelationalCollectionController.m
//
//  Created by Mat Trudel on 2014-10-15.
//  Copyright (c) 2014 Moshozen Inc. All rights reserved.
//

#import "MZRelationalCollectionController.h"

#import "NSPredicate+KeypathExtraction.h"

@interface MZRelationalCollectionController ()
@property id object;
@property NSString *relation;
@property NSPredicate *filteringPredicate;
@property NSSet *filteringChildKeyPaths;
@property NSArray *sortDescriptors;
@property NSSet *sortChildKeyPaths;
@property NSArray *observedChildKeyPaths;
@property NSSet *childKeysUniqueToCollectionObjects;

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
        self.filteringChildKeyPaths = [self.filteringPredicate mz_referencedKeyPaths];
        self.sortDescriptors = sortDescriptors;
        self.sortChildKeyPaths = [NSSet setWithArray:[sortDescriptors valueForKey:@"key"]];
        self.observedChildKeyPaths = childKeyPaths;
        NSMutableSet *childKeysUniqueToCollectionObjects = [[[NSSet setWithArray:self.observedChildKeyPaths] setByAddingObjectsFromSet:self.sortChildKeyPaths] mutableCopy];
        [childKeysUniqueToCollectionObjects minusSet:self.filteringChildKeyPaths];
        self.childKeysUniqueToCollectionObjects = childKeysUniqueToCollectionObjects;
        [self.object addObserver:self forKeyPath:key options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew context:nil];
        self.delegate = delegate;
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
    } else {
        BOOL collectionChanged = NO;
        if ([self.filteringChildKeyPaths containsObject:keyPath]) {
            collectionChanged = [self handleChangeToFilterKeypathsFromObject:object];
        }
        if (!collectionChanged) {
            if ([self.sortChildKeyPaths containsObject:keyPath]) {
                [self handleChangeToSortOrderFromCollectionObject:object];
            }
            if ([self.observedChildKeyPaths containsObject:keyPath]) {
                [self handleChangeToCollectionObject:object forKeyPath:keyPath change:change];
            }
        }
    }
}

- (void)handleChangeToRootObject:(NSDictionary *)change {
    if ([change[NSKeyValueChangeKindKey] integerValue] == NSKeyValueChangeSetting) {
        [self sendRelationalCollectionControllerWillChangeContent];
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
        [self sendRelationalCollectionControllerReplacedEntireCollection];
        [self sendRelationalCollectionControllerDidChangeContent];
    } else if ([change[NSKeyValueChangeKindKey] integerValue] == NSKeyValueChangeInsertion) {
        [self sendRelationalCollectionControllerWillChangeContent];
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
            [self sendRelationalCollectionControllerInsertedObject:newObject atIndex:[self.mutableCollection indexOfObject:newObject]];
        }
        if ([change[NSKeyValueChangeNewKey] conformsToProtocol:@protocol(NSFastEnumeration)]) {
            for (id obj in change[NSKeyValueChangeNewKey]) {
                [self startObservingRelationObject:obj];
            }
        }
        [self sendRelationalCollectionControllerDidChangeContent];
    } else if ([change[NSKeyValueChangeKindKey] integerValue] == NSKeyValueChangeRemoval) {
        [self sendRelationalCollectionControllerWillChangeContent];
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
        for (NSNumber *oldIndex in oldIndexMap) {
            [self sendRelationalCollectionControllerRemovedObject:oldIndexMap[oldIndex] atIndex:oldIndex.integerValue];
        }
        [self sendRelationalCollectionControllerDidChangeContent];
    } else if ([change[NSKeyValueChangeKindKey] integerValue] == NSKeyValueChangeReplacement) {
        if (!self.sortDescriptors) {
            if (self.lastExchangedIndexSet) {
                NSAssert(self.lastExchangedIndexSet.count == 1,  @"Can't (yet) handle cases where NSArray exchanges involve more than 1 item");
                [self sendRelationalCollectionControllerWillChangeContent];
                NSUInteger oldIndex = self.lastExchangedIndexSet.firstIndex;
                NSUInteger newIndex = [change[NSKeyValueChangeIndexesKey] firstIndex];
                id object = [change[NSKeyValueChangeNewKey] firstObject];
                [self.mutableCollection exchangeObjectAtIndex:oldIndex withObjectAtIndex:newIndex];
                [self sendRelationalCollectionControllerMovedObject:object fromIndex:oldIndex toIndex:newIndex];
                self.lastExchangedIndexSet = nil;
                [self sendRelationalCollectionControllerDidChangeContent];
            } else {
                self.lastExchangedIndexSet = change[NSKeyValueChangeIndexesKey];
            }
        }
    }
}

- (void)handleChangeToSortOrderFromCollectionObject:(id)object {
    [self sendRelationalCollectionControllerWillChangeContent];
    NSUInteger oldIndex = [self.mutableCollection indexOfObject:object];
    [self.mutableCollection sortUsingDescriptors:self.sortDescriptors];
    NSUInteger newIndex = [self.mutableCollection indexOfObject:object];
    if (oldIndex != newIndex) {
        [self sendRelationalCollectionControllerMovedObject:object fromIndex:oldIndex toIndex:newIndex];
    }
    [self sendRelationalCollectionControllerDidChangeContent];
}

- (BOOL)handleChangeToFilterKeypathsFromObject:(id)object {
    if ([self.collection containsObject:object] && ![self.filteringPredicate evaluateWithObject:object]) {
        [self sendRelationalCollectionControllerWillChangeContent];
        NSUInteger oldIndex = [self.mutableCollection indexOfObject:object];
        [self stopObservingCollectionObject:object];
        [self.mutableCollection removeObject:object];
        [self sendRelationalCollectionControllerRemovedObject:object atIndex:oldIndex];
        [self sendRelationalCollectionControllerDidChangeContent];
        return YES;
    } else if (![self.collection containsObject:object] && [self.filteringPredicate evaluateWithObject:object]) {
        [self sendRelationalCollectionControllerWillChangeContent];
        [self.mutableCollection addObject:object];
        [self.mutableCollection sortUsingDescriptors:self.sortDescriptors];
        [self startObservingCollectionObject:object];
        [self sendRelationalCollectionControllerInsertedObject:object atIndex:[self.mutableCollection indexOfObject:object]];
        [self sendRelationalCollectionControllerDidChangeContent];
        return YES;
    } else {
        return NO;
    }
}

- (void)handleChangeToCollectionObject:(id)object forKeyPath:(NSString *)keyPath change:(NSDictionary *)change {
    NSUInteger index = [self.collection indexOfObject:object];
    if (index != NSNotFound) {
        [self sendRelationalCollectionControllerWillChangeContent];
        [self sendRelationalCollectionControllerUpdatedObject:object atIndex:index changedKeyPath:keyPath];
        [self sendRelationalCollectionControllerDidChangeContent];
    }
}

#pragma mark - Setup and teardown of object observation

- (void)startObservingRelationObject:(id)object {
    for (NSString *keypath in self.filteringChildKeyPaths) {
        [object addObserver:self forKeyPath:keypath options:0 context:nil];
    }
}

- (void)stopObservingRelationObject:(id)object {
    for (NSString *keypath in self.filteringChildKeyPaths) {
        [object removeObserver:self forKeyPath:keypath context:nil];
    }
}

- (void)startObservingCollectionObject:(id)object {
    for (NSString *keypath in self.childKeysUniqueToCollectionObjects) {
        [object addObserver:self forKeyPath:keypath options:0 context:nil];
    }
}

- (void)stopObservingCollectionObject:(id)object {
    for (NSString *keypath in self.childKeysUniqueToCollectionObjects) {
        [object removeObserver:self forKeyPath:keypath context:nil];
    }
}

#pragma mark - Delegate notification

- (void)sendRelationalCollectionControllerWillChangeContent {
    if ([self.delegate respondsToSelector:@selector(relationalCollectionControllerWillChangeContent:)]) {
        [self.delegate relationalCollectionControllerWillChangeContent:self];
    }
}

- (void)sendRelationalCollectionControllerDidChangeContent {
    if ([self.delegate respondsToSelector:@selector(relationalCollectionControllerDidChangeContent:)]) {
        [self.delegate relationalCollectionControllerDidChangeContent:self];
    }
}


- (void)sendRelationalCollectionControllerReplacedEntireCollection {
    if ([self.delegate respondsToSelector:@selector(relationalCollectionControllerReplacedEntireCollection:)]) {
        [self.delegate relationalCollectionControllerReplacedEntireCollection:self];
    }
}

- (void)sendRelationalCollectionControllerInsertedObject:(id)object atIndex:(NSUInteger)index {
    if ([self.delegate respondsToSelector:@selector(relationalCollectionController:insertedObject:atIndex:)]) {
        [self.delegate relationalCollectionController:self insertedObject:object atIndex:index];
    }
}

- (void)sendRelationalCollectionControllerRemovedObject:(id)object atIndex:(NSUInteger)index {
    if ([self.delegate respondsToSelector:@selector(relationalCollectionController:removedObject:atIndex:)]) {
        [self.delegate relationalCollectionController:self removedObject:object atIndex:index];
    }
}

- (void)sendRelationalCollectionControllerMovedObject:(id)object fromIndex:(NSUInteger)fromIndex toIndex:(NSUInteger)toIndex {
    if ([self.delegate respondsToSelector:@selector(relationalCollectionController:movedObject:fromIndex:toIndex:)]) {
        [self.delegate relationalCollectionController:self movedObject:object fromIndex:fromIndex toIndex:toIndex];
    }
}

- (void)sendRelationalCollectionControllerUpdatedObject:(id)object atIndex:(NSUInteger)index changedKeyPath:(NSString *)keyPath {
    if ([self.delegate respondsToSelector:@selector(relationalCollectionController:updatedObject:atIndex:changedKeyPath:)]) {
        [self.delegate relationalCollectionController:self updatedObject:object atIndex:index changedKeyPath:keyPath];
    }
}

@end
