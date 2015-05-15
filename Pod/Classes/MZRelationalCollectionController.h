//
//  MZRelationalCollectionController.h
//
//  Created by Mat Trudel on 2014-10-15.
//  Copyright (c) 2014 Moshozen Inc. All rights reserved.
//

@import Foundation;

@class MZRelationalCollectionController;

@protocol MZRelationalCollectionControllerDelegate <NSObject>
@optional

- (void)relationalCollectionControllerWillChangeContent:(MZRelationalCollectionController *)controller;
- (void)relationalCollectionControllerDidChangeContent:(MZRelationalCollectionController *)controller;

- (void)relationalCollectionController:(MZRelationalCollectionController *)controller insertedObject:(id)object atIndex:(NSUInteger)index;
- (void)relationalCollectionController:(MZRelationalCollectionController *)controller removedObject:(id)object atIndex:(NSUInteger)index;
- (void)relationalCollectionController:(MZRelationalCollectionController *)controller movedObject:(id)object fromIndex:(NSUInteger)fromIndex toIndex:(NSUInteger)toIndex;
- (void)relationalCollectionController:(MZRelationalCollectionController *)controller updatedObject:(id)object atIndex:(NSUInteger)index changedKeyPath:(NSString *)keyPath;

@end


@interface MZRelationalCollectionController : NSObject
@property (nonatomic, weak) id<MZRelationalCollectionControllerDelegate> delegate;
@property (nonatomic, readonly) id object;
@property (nonatomic, readonly) NSString *relation;
@property (nonatomic, readonly) NSPredicate *filteringPredicate;
@property (nonatomic, readonly) NSArray *sortDescriptors;
@property (nonatomic, readonly) NSArray *observedChildKeyPaths;

@property (nonatomic, readonly) NSArray *collection;

+ (instancetype)collectionControllerForRelation:(NSString *)key
                                       onObject:(id)object
                                     filteredBy:(NSPredicate *)predicate
                                       sortedBy:(NSArray *)sortDescriptors
                         observingChildKeyPaths:(NSArray *)childKeyPaths;

@end
