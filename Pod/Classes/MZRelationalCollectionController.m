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
@property (nonatomic, strong) id object;
@property (nonatomic, strong) NSString *relation;
@property (nonatomic, strong) NSPredicate *filteringPredicate;
@property (nonatomic, strong) NSArray *sortDescriptors;
@property (nonatomic, strong) NSArray *observedChildKeyPaths;
@property (nonatomic, strong) NSMutableArray *mutableCollection;
@end

@implementation MZRelationalCollectionController

+ (instancetype)collectionControllerForRelation:(NSString *)key onObject:(id)object filteredBy:(NSPredicate *)filteringPredicate sortedBy:(NSArray *)sortDescriptors observingChildKeyPaths:(NSArray *)childKeyPaths {
  return [[self alloc] initWithRelation:key onObject:object filteredBy:filteringPredicate sortedBy:sortDescriptors observingChildKeyPaths:childKeyPaths];
}

- (instancetype)initWithRelation:(NSString *)key onObject:(id)object filteredBy:(NSPredicate *)filteringPredicate sortedBy:(NSArray *)sortDescriptors observingChildKeyPaths:(NSArray *)childKeyPaths {
  if (self = [super init]) {
    NSAssert([object valueForKey:key] == nil || [[object valueForKey:key] isKindOfClass:[NSSet class]], @"MZRelationalCollectionController only handles set relations (for now)");
    self.object = object;
    self.relation = key;
    self.filteringPredicate = filteringPredicate ?: [NSPredicate predicateWithValue:YES];
    self.sortDescriptors = sortDescriptors;
    self.observedChildKeyPaths = childKeyPaths;
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
  } else if (context == sortChangeContext) { // Safe to compare pointers since it's a const
    [self handleChangeToSortOrderFromCollectionObject:object];
  } else if (context == filteringPredicateContext) { // Safe to compare pointers since it's a const
    [self handleChangeToFilterKeypathsFromObject:object];
  } else {
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
    self.mutableCollection = [[[[self.object valueForKey:self.relation] filteredSetUsingPredicate:self.filteringPredicate] sortedArrayUsingDescriptors:self.sortDescriptors] mutableCopy];
    for (id obj in [self.object valueForKey:self.relation]) {
      [self startObservingRelationObject:obj];
    }
    for (id obj in self.collection) {
      [self startObservingCollectionObject:obj];
    }
  } else if ([change[NSKeyValueChangeKindKey] integerValue] == NSKeyValueChangeInsertion) {
    if ([change[NSKeyValueChangeNewKey] conformsToProtocol:@protocol(NSFastEnumeration)]) {
      for (id obj in change[NSKeyValueChangeNewKey]) {
        [self startObservingRelationObject:obj];
      }
    }
    NSSet *newObjects = [change[NSKeyValueChangeNewKey] filteredSetUsingPredicate:self.filteringPredicate];
    [self.mutableCollection addObjectsFromArray:newObjects.allObjects];
    [self.mutableCollection sortUsingDescriptors:self.sortDescriptors];

    if ([self.delegate respondsToSelector:@selector(relationalCollectionControllerWillChangeContent:)]) {
      [self.delegate relationalCollectionControllerWillChangeContent:self];
    }
    for (id newObject in newObjects) {
      [self startObservingCollectionObject:newObject];
      if ([self.delegate respondsToSelector:@selector(relationalCollectionController:insertedObject:atIndex:)]) {
        [self.delegate relationalCollectionController:self insertedObject:newObject atIndex:[self.mutableCollection indexOfObject:newObject]];
      }
    }
    if ([self.delegate respondsToSelector:@selector(relationalCollectionControllerDidChangeContent:)]) {
      [self.delegate relationalCollectionControllerDidChangeContent:self];
    }
  } else if ([change[NSKeyValueChangeKindKey] integerValue] == NSKeyValueChangeRemoval) {
    NSSet *oldObjects = change[NSKeyValueChangeOldKey];
    NSMutableDictionary *oldIndexMap = [NSMutableDictionary dictionary];

    for (id oldObject in oldObjects) {
      [self stopObservingRelationObject:oldObject];
      if ([self.mutableCollection containsObject:oldObject]) {
        [oldIndexMap setObject:oldObject forKey:@([self.mutableCollection indexOfObject:oldObject])];
        [self stopObservingCollectionObject:oldObject];
      }
    }
    [self.mutableCollection removeObjectsInArray:oldObjects.allObjects];
    if ([self.delegate respondsToSelector:@selector(relationalCollectionControllerWillChangeContent:)]) {
      [self.delegate relationalCollectionControllerWillChangeContent:self];
    }
    if ([self.delegate respondsToSelector:@selector(relationalCollectionController:removedObject:atIndex:)]) {
      for (NSNumber *oldIndex in oldIndexMap) {
        [self.delegate relationalCollectionController:self removedObject:oldIndexMap[oldIndex] atIndex:oldIndex.integerValue];
      }
    }
    if ([self.delegate respondsToSelector:@selector(relationalCollectionControllerDidChangeContent:)]) {
      [self.delegate relationalCollectionControllerDidChangeContent:self];
    }
  }
}

- (void)handleChangeToSortOrderFromCollectionObject:(id)object {
  NSUInteger oldIndex = [self.mutableCollection indexOfObject:object];
  [self.mutableCollection sortUsingDescriptors:self.sortDescriptors];
  NSUInteger newIndex = [self.mutableCollection indexOfObject:object];
  if (oldIndex != newIndex) {
    if ([self.delegate respondsToSelector:@selector(relationalCollectionControllerWillChangeContent:)]) {
      [self.delegate relationalCollectionControllerWillChangeContent:self];
    }
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
    NSUInteger oldIndex = [self.mutableCollection indexOfObject:object];
    [self stopObservingCollectionObject:object];
    [self.mutableCollection removeObject:object];
    if ([self.delegate respondsToSelector:@selector(relationalCollectionControllerWillChangeContent:)]) {
      [self.delegate relationalCollectionControllerWillChangeContent:self];
    }
    if ([self.delegate respondsToSelector:@selector(relationalCollectionController:removedObject:atIndex:)]) {
      [self.delegate relationalCollectionController:self removedObject:object atIndex:oldIndex];
    }
    if ([self.delegate respondsToSelector:@selector(relationalCollectionControllerDidChangeContent:)]) {
      [self.delegate relationalCollectionControllerDidChangeContent:self];
    }
  } else if (![self.collection containsObject:object] && [self.filteringPredicate evaluateWithObject:object]) {
    [self.mutableCollection addObject:object];
    [self.mutableCollection sortUsingDescriptors:self.sortDescriptors];
    [self startObservingCollectionObject:object];

    if ([self.delegate respondsToSelector:@selector(relationalCollectionControllerWillChangeContent:)]) {
      [self.delegate relationalCollectionControllerWillChangeContent:self];
    }
    if ([self.delegate respondsToSelector:@selector(relationalCollectionController:insertedObject:atIndex:)]) {
      [self.delegate relationalCollectionController:self insertedObject:object atIndex:[self.mutableCollection indexOfObject:object]];
    }
    if ([self.delegate respondsToSelector:@selector(relationalCollectionControllerDidChangeContent:)]) {
      [self.delegate relationalCollectionControllerDidChangeContent:self];
    }
  }
}

- (void)handleChangeToCollectionObject:(id)object forKeyPath:(NSString *)keyPath change:(NSDictionary *)change {
  if ([self.delegate respondsToSelector:@selector(relationalCollectionControllerWillChangeContent:)]) {
    [self.delegate relationalCollectionControllerWillChangeContent:self];
  }
  if ([self.delegate respondsToSelector:@selector(relationalCollectionController:updatedObject:atIndex:changedKeyPath:)]) {
    [self.delegate relationalCollectionController:self updatedObject:object atIndex:[self.collection indexOfObject:object] changedKeyPath:keyPath];
  }
  if ([self.delegate respondsToSelector:@selector(relationalCollectionControllerDidChangeContent:)]) {
    [self.delegate relationalCollectionControllerDidChangeContent:self];
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
