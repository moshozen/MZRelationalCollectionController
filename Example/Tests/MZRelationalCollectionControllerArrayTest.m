//
//  MZRelationalCollectionControllerTest.m
//
//  Created by Mat Trudel on 2014-10-15.
//  Copyright (c) 2014 Moshozen Inc. All rights reserved.
//

@import XCTest;

#import "MZRelationalCollectionController.h"

#import "MZArrayProject.h"
#import "MZTask.h"

@interface MZRelationalCollectionControllerArrayTest : XCTestCase
@property MZArrayProject *project;
@property MZRelationalCollectionController *controller;
@end

@implementation MZRelationalCollectionControllerArrayTest

- (void)setUp {
  [super setUp];
  self.project = [[MZArrayProject alloc] init];
  self.controller = [MZRelationalCollectionController collectionControllerForRelation:@"tasks"
                                                                             onObject:self.project
                                                                           filteredBy:[NSPredicate predicateWithFormat:@"hidden != YES"]
                                                                             sortedBy:@[[NSSortDescriptor sortDescriptorWithKey:@"index" ascending:YES]]
                                                               observingChildKeyPaths:@[@"title", @"descrption"]];
}

@end

@interface MZRelationalCollectionControllerArrayMembershipTest : MZRelationalCollectionControllerArrayTest
@end

@implementation MZRelationalCollectionControllerArrayMembershipTest

- (void)testAssignment {
  MZTask *task = [[MZTask alloc] init];
  [self.project setTasks:@[task]];

  XCTAssertEqualObjects(self.controller.collection, @[task]);
}

- (void)testReassignment {
  MZTask *task = [[MZTask alloc] init];
  [self.project setTasks:@[task]];
  [self.project setTasks:@[]];

  XCTAssertEqualObjects(self.controller.collection, @[]);
}

- (void)testNilReassignment {
  MZTask *task = [[MZTask alloc] init];
  [self.project setTasks:@[task]];
  [self.project setTasks:nil];

  XCTAssertEqualObjects(self.controller.collection, @[]);
}

- (void)testSorting {
  MZTask *task1 = [[MZTask alloc] init];
  task1.index = @1;
  MZTask *task2 = [[MZTask alloc] init];
  task2.index = @2;
  MZTask *task3 = [[MZTask alloc] init];
  task3.index = @3;

  [self.project setTasks:@[task1, task2, task3]];

  NSArray *expected = @[task1, task2, task3];
  XCTAssertEqualObjects(self.controller.collection, expected);
}

- (void)testDynamicSorting {
  MZTask *task1 = [[MZTask alloc] init];
  task1.index = @1;
  MZTask *task2 = [[MZTask alloc] init];
  task2.index = @2;
  MZTask *task3 = [[MZTask alloc] init];
  task3.index = @3;
  [self.project setTasks:@[task1, task2, task3]];

  task1.index = @4;

  NSArray *expected = @[task2, task3, task1];
  XCTAssertEqualObjects(self.controller.collection, expected);
}

- (void)testInsertion {
  MZTask *task1 = [[MZTask alloc] init];
  task1.index = @1;
  MZTask *task3 = [[MZTask alloc] init];
  task3.index = @3;
  [self.project setTasks:@[task1, task3]];

  MZTask *task2 = [[MZTask alloc] init];
  task2.index = @2;
  [[self.project mutableArrayValueForKey:@"tasks"] addObject:task2];

  NSArray *expected = @[task1, task2, task3];
  XCTAssertEqualObjects(self.controller.collection, expected);
}

- (void)testDeletion {
  MZTask *task1 = [[MZTask alloc] init];
  task1.index = @1;
  MZTask *task2 = [[MZTask alloc] init];
  task2.index = @2;
  MZTask *task3 = [[MZTask alloc] init];
  task3.index = @3;
  [self.project setTasks:@[task1, task2, task3]];

  [[self.project mutableArrayValueForKey:@"tasks"] removeObject:task2];

  NSArray *expected = @[task1, task3];
  XCTAssertEqualObjects(self.controller.collection, expected);
}

- (void)testDeletionOfFilteredObject {
  MZTask *task1 = [[MZTask alloc] init];
  task1.index = @1;
  MZTask *task2 = [[MZTask alloc] init];
  task2.index = @2;
  task2.hidden = @YES;
  [self.project setTasks:@[task1, task2]];

  [[self.project mutableArrayValueForKey:@"tasks"] removeObject:task2];

  NSArray *expected = @[task1];
  XCTAssertEqualObjects(self.controller.collection, expected);
}

- (void)testPredicateFilteringOnChangeOut {
  MZTask *task1 = [[MZTask alloc] init];
  task1.index = @1;
  MZTask *task2 = [[MZTask alloc] init];
  task2.index = @2;
  [self.project setTasks:@[task1, task2]];

  task1.hidden = @YES;

  NSArray *expected = @[task2];
  XCTAssertEqualObjects(self.controller.collection, expected);
}

- (void)testPredicateFilteringOnInsertion {
  MZTask *task1 = [[MZTask alloc] init];
  task1.index = @1;
  [self.project setTasks:@[task1]];

  MZTask *task2 = [[MZTask alloc] init];
  task2.index = @2;
  task2.hidden = @YES;
  [[self.project mutableArrayValueForKey:@"tasks"] addObject:task2];

  NSArray *expected = @[task1];
  XCTAssertEqualObjects(self.controller.collection, expected);
}

- (void)testPredicateFilteringOnChangeIn {
  MZTask *task1 = [[MZTask alloc] init];
  task1.index = @1;
  MZTask *task2 = [[MZTask alloc] init];
  task2.index = @2;
  task2.hidden = @YES;
  [self.project setTasks:@[task1, task2]];

  task2.hidden = @NO;

  NSArray *expected = @[task1, task2];
  XCTAssertEqualObjects(self.controller.collection, expected);
}

@end

@interface MZRelationalCollectionControllerDelegateArrayTest : MZRelationalCollectionControllerArrayTest <MZRelationalCollectionControllerDelegate>
@property NSMutableArray *relationalCollectionControllerWillChangeContentParameters;
@property NSMutableArray *relationalCollectionControllerDidChangeContentParameters;
@property NSMutableArray *relationalCollectionControllerInsertedObjectAtIndexParameters;
@property NSMutableArray *relationalCollectionControllerRemovedObjectAtIndexParameters;
@property NSMutableArray *relationalCollectionControllerMovedObjectFromIndexToIndexParameters;
@property NSMutableArray *relationalCollectionControllerUpdatedObjectAtIndexChangedKeyPathParameters;
@end

@implementation MZRelationalCollectionControllerDelegateArrayTest

- (void)setUp {
  [super setUp];
  self.project.tasks = @[];
  self.controller.delegate = self;
  self.relationalCollectionControllerWillChangeContentParameters = [NSMutableArray array];
  self.relationalCollectionControllerDidChangeContentParameters = [NSMutableArray array];
  self.relationalCollectionControllerInsertedObjectAtIndexParameters = [NSMutableArray array];
  self.relationalCollectionControllerRemovedObjectAtIndexParameters = [NSMutableArray array];
  self.relationalCollectionControllerMovedObjectFromIndexToIndexParameters = [NSMutableArray array];
  self.relationalCollectionControllerUpdatedObjectAtIndexChangedKeyPathParameters = [NSMutableArray array];
}

- (void)testRelationalCollectionControllerWillChangeContent {
  MZTask *task1 = [[MZTask alloc] init];
  task1.index = @1;
  [[self.project mutableArrayValueForKey:@"tasks"] addObject:task1];

  XCTAssertEqual(self.relationalCollectionControllerWillChangeContentParameters.count, 1);
  XCTAssertEqualObjects([self.relationalCollectionControllerWillChangeContentParameters.firstObject firstObject], self.controller);
}

- (void)testRelationalCollectionControllerDidChangeContent {
  MZTask *task1 = [[MZTask alloc] init];
  task1.index = @1;
  [[self.project mutableArrayValueForKey:@"tasks"] addObject:task1];

  XCTAssertEqual(self.relationalCollectionControllerDidChangeContentParameters.count, 1);
  XCTAssertEqualObjects([self.relationalCollectionControllerDidChangeContentParameters.firstObject firstObject], self.controller);
}

- (void)testRelationalCollectionControllerInsertedObjectAtIndex {
  MZTask *task1 = [[MZTask alloc] init];
  task1.index = @1;
  [[self.project mutableArrayValueForKey:@"tasks"] addObject:task1];

  XCTAssertEqual(self.relationalCollectionControllerInsertedObjectAtIndexParameters.count, 1);
  NSArray *expected = @[self.controller, task1, @0];
  XCTAssertEqualObjects(self.relationalCollectionControllerInsertedObjectAtIndexParameters.firstObject, expected);
}

- (void)testRelationalCollectionControllerRemovedObjectAtIndex {
  MZTask *task1 = [[MZTask alloc] init];
  task1.index = @1;
  [self.project setTasks:@[task1]];

  [[self.project mutableArrayValueForKey:@"tasks"] removeObject:task1];

  XCTAssertEqual(self.relationalCollectionControllerRemovedObjectAtIndexParameters.count, 1);
  NSArray *expected = @[self.controller, task1, @0];
  XCTAssertEqualObjects(self.relationalCollectionControllerRemovedObjectAtIndexParameters.firstObject, expected);
}

- (void)testRelationalCollectionControllerMovedObjectFromIndexToIndex {
  MZTask *task1 = [[MZTask alloc] init];
  task1.index = @1;
  MZTask *task2 = [[MZTask alloc] init];
  task2.index = @2;
  [self.project setTasks:@[task1, task2]];

  task1.index = @3;

  XCTAssertEqual(self.relationalCollectionControllerMovedObjectFromIndexToIndexParameters.count, 1);
  NSArray *expected = @[self.controller, task1, @0, @1];
  XCTAssertEqualObjects(self.relationalCollectionControllerMovedObjectFromIndexToIndexParameters.firstObject, expected);
}

- (void)testRelationalCollectionControllerUpdatedObjectAtIndexChangedKeyPath {
  MZTask *task1 = [[MZTask alloc] init];
  task1.index = @1;
  [self.project setTasks:@[task1]];

  task1.title = @"New Title";

  XCTAssertEqual(self.relationalCollectionControllerUpdatedObjectAtIndexChangedKeyPathParameters.count, 1);
  NSArray *expected = @[self.controller, task1, @0, @"title"];
  XCTAssertEqualObjects(self.relationalCollectionControllerUpdatedObjectAtIndexChangedKeyPathParameters.firstObject, expected);
}

- (void)testRelationalCollectionControllerRemovedObjectAtIndexViaPredicateChangeOut {
  MZTask *task1 = [[MZTask alloc] init];
  task1.index = @1;
  [self.project setTasks:@[task1]];

  task1.hidden = @YES;

  XCTAssertEqual(self.relationalCollectionControllerRemovedObjectAtIndexParameters.count, 1);
  NSArray *expected = @[self.controller, task1, @0];
  XCTAssertEqualObjects(self.relationalCollectionControllerRemovedObjectAtIndexParameters.firstObject, expected);
}

- (void)testNoRelationalCollectionControllerInsertedObjectAtIndexOnPredicateFailureInsertion {
  MZTask *task1 = [[MZTask alloc] init];
  task1.index = @1;
  [self.project setTasks:@[task1]];

  MZTask *task2 = [[MZTask alloc] init];
  task1.index = @2;
  task2.hidden = @YES;
  [[self.project mutableArrayValueForKey:@"tasks"] addObject:task2];

  XCTAssertEqual(self.relationalCollectionControllerInsertedObjectAtIndexParameters.count, 0);
}

- (void)testRelationalCollectionControllerInsertedObjectAtIndexViaPredicateChangeIn {
  MZTask *task1 = [[MZTask alloc] init];
  task1.index = @1;
  MZTask *task2 = [[MZTask alloc] init];
  task2.index = @2;
  task2.hidden = @YES;
  [self.project setTasks:@[task1, task2]];

  task2.hidden = @NO;

  XCTAssertEqual(self.relationalCollectionControllerInsertedObjectAtIndexParameters.count, 1);
  NSArray *expected = @[self.controller, task2, @1];
  XCTAssertEqualObjects(self.relationalCollectionControllerInsertedObjectAtIndexParameters.firstObject, expected);
}

// Delegate methods

- (void)relationalCollectionControllerWillChangeContent:(MZRelationalCollectionController *)controller
{
  [self.relationalCollectionControllerWillChangeContentParameters addObject:@[controller]];
}

- (void)relationalCollectionControllerDidChangeContent:(MZRelationalCollectionController *)controller
{
  [self.relationalCollectionControllerDidChangeContentParameters addObject:@[controller]];
}

- (void)relationalCollectionController:(MZRelationalCollectionController *)controller insertedObject:(id)object atIndex:(NSUInteger)index
{
  [self.relationalCollectionControllerInsertedObjectAtIndexParameters addObject:@[controller, object, @(index)]];
}

- (void)relationalCollectionController:(MZRelationalCollectionController *)controller removedObject:(id)object atIndex:(NSUInteger)index
{
  [self.relationalCollectionControllerRemovedObjectAtIndexParameters addObject:@[controller, object, @(index)]];
}

- (void)relationalCollectionController:(MZRelationalCollectionController *)controller movedObject:(id)object fromIndex:(NSUInteger)fromIndex toIndex:(NSUInteger)toIndex
{
  [self.relationalCollectionControllerMovedObjectFromIndexToIndexParameters addObject:@[controller, object, @(fromIndex), @(toIndex)]];
}

- (void)relationalCollectionController:(MZRelationalCollectionController *)controller updatedObject:(id)object atIndex:(NSUInteger)index changedKeyPath:(NSString *)keyPath
{
  [self.relationalCollectionControllerUpdatedObjectAtIndexChangedKeyPathParameters addObject:@[controller, object, @(index), keyPath]];
}



@end