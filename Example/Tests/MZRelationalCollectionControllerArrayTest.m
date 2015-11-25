//
//  MZRelationalCollectionControllerArrayTest.m
//
//  Created by Mat Trudel on 2014-10-15.
//  Copyright (c) 2014 Moshozen Inc. All rights reserved.
//

@import XCTest;

#import <MZRelationalCollectionController/MZRelationalCollectionController.h>

#import "ArrayArtist.h"
#import "Album.h"

@interface MZRelationalCollectionControllerArrayTest : XCTestCase
@property ArrayArtist *artist;
@property MZRelationalCollectionController *controller;
@end

@implementation MZRelationalCollectionControllerArrayTest

- (void)setUp {
  [super setUp];
  self.artist = [ArrayArtist new];
  self.controller = [MZRelationalCollectionController collectionControllerForRelation:@"albums"
                                                                             onObject:self.artist
                                                                           filteredBy:[NSPredicate predicateWithFormat:@"liveAlbum != YES"]
                                                                             sortedBy:@[[NSSortDescriptor sortDescriptorWithKey:@"releaseDate" ascending:YES]]
                                                               observingChildKeyPaths:@[@"title"]
                                                                             delegate:nil];
}

@end

@interface MZRelationalCollectionControllerMembershipArrayTest : MZRelationalCollectionControllerArrayTest
@end

@implementation MZRelationalCollectionControllerMembershipArrayTest

- (void)testAssignment {
  Album *album = [Album new];
  [self.artist setAlbums:@[album]];

  XCTAssertEqualObjects(self.controller.collection, @[album]);
}

- (void)testReassignment {
  Album *album = [Album new];
  [self.artist setAlbums:@[album]];
  [self.artist setAlbums:@[]];

  XCTAssertEqualObjects(self.controller.collection, @[]);
}

- (void)testNilReassignment {
  Album *album = [Album new];
  [self.artist setAlbums:@[album]];
  [self.artist setAlbums:nil];

  XCTAssertEqualObjects(self.controller.collection, @[]);
}

- (void)testSorting {
  Album *album1 = [Album new];
  album1.releaseDate = [NSDate dateWithTimeIntervalSinceNow:0];
  Album *album2 = [Album new];
  album2.releaseDate = [NSDate dateWithTimeIntervalSinceNow:1];
  Album *album3 = [Album new];
  album3.releaseDate = [NSDate dateWithTimeIntervalSinceNow:2];

  [self.artist setAlbums:@[album1, album2, album3]];

  NSArray *expected = @[album1, album2, album3];
  XCTAssertEqualObjects(self.controller.collection, expected);
}

- (void)testDynamicSorting {
  Album *album1 = [Album new];
  album1.releaseDate = [NSDate dateWithTimeIntervalSinceNow:0];
  Album *album2 = [Album new];
  album2.releaseDate = [NSDate dateWithTimeIntervalSinceNow:1];
  Album *album3 = [Album new];
  album3.releaseDate = [NSDate dateWithTimeIntervalSinceNow:2];

  [self.artist setAlbums:@[album1, album2, album3]];

  album1.releaseDate = [NSDate dateWithTimeIntervalSinceNow:3];

  NSArray *expected = @[album2, album3, album1];
  XCTAssertEqualObjects(self.controller.collection, expected);
}

- (void)testInsertion {
  Album *album1 = [Album new];
  album1.releaseDate = [NSDate dateWithTimeIntervalSinceNow:0];
  Album *album3 = [Album new];
  album3.releaseDate = [NSDate dateWithTimeIntervalSinceNow:2];

  [self.artist setAlbums:@[album1, album3]];

  Album *album2 = [Album new];
  album2.releaseDate = [NSDate dateWithTimeIntervalSinceNow:1];

  [[self.artist mutableArrayValueForKey:@"albums"] addObject:album2];

  NSArray *expected = @[album1, album2, album3];
  XCTAssertEqualObjects(self.controller.collection, expected);
}

- (void)testDeletion {
  Album *album1 = [Album new];
  album1.releaseDate = [NSDate dateWithTimeIntervalSinceNow:0];
  Album *album2 = [Album new];
  album2.releaseDate = [NSDate dateWithTimeIntervalSinceNow:1];
  Album *album3 = [Album new];
  album3.releaseDate = [NSDate dateWithTimeIntervalSinceNow:2];

  [self.artist setAlbums:@[album1, album2, album3]];

  [[self.artist mutableArrayValueForKey:@"albums"] removeObject:album2];

  NSArray *expected = @[album1, album3];
  XCTAssertEqualObjects(self.controller.collection, expected);
}

- (void)testDeletionOfFilteredObject {
  Album *album1 = [Album new];
  album1.releaseDate = [NSDate dateWithTimeIntervalSinceNow:0];
  Album *album2 = [Album new];
  album2.releaseDate = [NSDate dateWithTimeIntervalSinceNow:1];
  album2.liveAlbum = YES;
  Album *album3 = [Album new];
  album3.releaseDate = [NSDate dateWithTimeIntervalSinceNow:2];

  [self.artist setAlbums:@[album1, album2, album3]];

  [[self.artist mutableArrayValueForKey:@"albums"] removeObject:album2];

  NSArray *expected = @[album1, album3];
  XCTAssertEqualObjects(self.controller.collection, expected);
}

- (void)testPredicateFilteringOnChangeOut {
  Album *album1 = [Album new];
  album1.releaseDate = [NSDate dateWithTimeIntervalSinceNow:0];
  Album *album2 = [Album new];
  album2.releaseDate = [NSDate dateWithTimeIntervalSinceNow:1];
  Album *album3 = [Album new];
  album3.releaseDate = [NSDate dateWithTimeIntervalSinceNow:2];

  [self.artist setAlbums:@[album1, album2, album3]];

  album1.liveAlbum = YES;

  NSArray *expected = @[album2, album3];
  XCTAssertEqualObjects(self.controller.collection, expected);
}

- (void)testPredicateFilteringOnInsertion {
  Album *album1 = [Album new];
  album1.releaseDate = [NSDate dateWithTimeIntervalSinceNow:0];
  Album *album3 = [Album new];
  album3.releaseDate = [NSDate dateWithTimeIntervalSinceNow:2];

  [self.artist setAlbums:@[album1, album3]];

  Album *album2 = [Album new];
  album2.releaseDate = [NSDate dateWithTimeIntervalSinceNow:1];
  album2.liveAlbum = YES;

  [[self.artist mutableArrayValueForKey:@"albums"] addObject:album2];

  NSArray *expected = @[album1, album3];
  XCTAssertEqualObjects(self.controller.collection, expected);
}

- (void)testPredicateFilteringOnChangeIn {
  Album *album1 = [Album new];
  album1.releaseDate = [NSDate dateWithTimeIntervalSinceNow:0];
  Album *album2 = [Album new];
  album2.releaseDate = [NSDate dateWithTimeIntervalSinceNow:1];
  album2.liveAlbum = YES;
  Album *album3 = [Album new];
  album3.releaseDate = [NSDate dateWithTimeIntervalSinceNow:2];

  [self.artist setAlbums:@[album1, album2, album3]];

  album2.liveAlbum = NO;

  NSArray *expected = @[album1, album2, album3];
  XCTAssertEqualObjects(self.controller.collection, expected);
}

@end

@interface MZRelationalCollectionControllerParamaterFreeArrayTest : MZRelationalCollectionControllerArrayTest
@end

@implementation MZRelationalCollectionControllerParamaterFreeArrayTest

- (void)testWithNoParameters {
  Album *album1 = [Album new];
  album1.releaseDate = [NSDate dateWithTimeIntervalSinceNow:0];
  Album *album2 = [Album new];
  album2.releaseDate = [NSDate dateWithTimeIntervalSinceNow:1];
  Album *album3 = [Album new];
  album3.releaseDate = [NSDate dateWithTimeIntervalSinceNow:2];

  self.controller = [MZRelationalCollectionController collectionControllerForRelation:@"albums"
                                                                             onObject:self.artist
                                                                           filteredBy:nil
                                                                             sortedBy:nil
                                                               observingChildKeyPaths:nil
                                                                             delegate:nil];
  [self.artist setAlbums:@[album1, album2, album3]];
  
  NSArray *expected = @[album1, album2, album3];
  XCTAssertEqualObjects(self.controller.collection, expected);
}

@end

@interface MZRelationalCollectionControllerComplexPredicateArrayTest : MZRelationalCollectionControllerArrayTest
@end

@implementation MZRelationalCollectionControllerComplexPredicateArrayTest

- (void)testPredicateFilteringOnObjects {
  Album *album1 = [Album new];
  album1.releaseDate = [NSDate dateWithTimeIntervalSinceNow:0];
  Album *album2 = [Album new];
  album2.releaseDate = [NSDate dateWithTimeIntervalSinceNow:1];
  Album *album3 = [Album new];
  album3.releaseDate = [NSDate dateWithTimeIntervalSinceNow:2];

  self.controller = [MZRelationalCollectionController collectionControllerForRelation:@"albums"
                                                                             onObject:self.artist
                                                                           filteredBy:[NSPredicate predicateWithFormat:@"self != %@", album1]
                                                                             sortedBy:@[[NSSortDescriptor sortDescriptorWithKey:@"releaseDate" ascending:YES]]
                                                               observingChildKeyPaths:@[@"title"]
                                                                             delegate:nil];

  [self.artist setAlbums:@[album1, album2, album3]];
  NSArray *expected = @[album2, album3];
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
  self.artist.albums = @[];
  self.controller.delegate = self;
  self.relationalCollectionControllerWillChangeContentParameters = [NSMutableArray array];
  self.relationalCollectionControllerDidChangeContentParameters = [NSMutableArray array];
  self.relationalCollectionControllerInsertedObjectAtIndexParameters = [NSMutableArray array];
  self.relationalCollectionControllerRemovedObjectAtIndexParameters = [NSMutableArray array];
  self.relationalCollectionControllerMovedObjectFromIndexToIndexParameters = [NSMutableArray array];
  self.relationalCollectionControllerUpdatedObjectAtIndexChangedKeyPathParameters = [NSMutableArray array];
}

- (void)testRelationalCollectionControllerWillChangeContent {
  Album *album = [Album new];
  album.releaseDate = [NSDate dateWithTimeIntervalSinceNow:0];

  [[self.artist mutableArrayValueForKey:@"albums"] addObject:album];

  XCTAssertEqual(self.relationalCollectionControllerWillChangeContentParameters.count, 1);
  XCTAssertEqualObjects([self.relationalCollectionControllerWillChangeContentParameters.firstObject firstObject], self.controller);
}

- (void)testRelationalCollectionControllerDidChangeContent {
  Album *album = [Album new];
  album.releaseDate = [NSDate dateWithTimeIntervalSinceNow:0];

  [[self.artist mutableArrayValueForKey:@"albums"] addObject:album];

  XCTAssertEqual(self.relationalCollectionControllerDidChangeContentParameters.count, 1);
  XCTAssertEqualObjects([self.relationalCollectionControllerDidChangeContentParameters.firstObject firstObject], self.controller);
}

- (void)testRelationalCollectionControllerInsertedObjectAtIndex {
  Album *album = [Album new];
  album.releaseDate = [NSDate dateWithTimeIntervalSinceNow:0];

  [[self.artist mutableArrayValueForKey:@"albums"] addObject:album];

  XCTAssertEqual(self.relationalCollectionControllerInsertedObjectAtIndexParameters.count, 1);
  NSArray *expected = @[self.controller, album, @0];
  XCTAssertEqualObjects(self.relationalCollectionControllerInsertedObjectAtIndexParameters.firstObject, expected);
}

- (void)testRelationalCollectionControllerRemovedObjectAtIndex {
  Album *album = [Album new];
  album.releaseDate = [NSDate dateWithTimeIntervalSinceNow:0];

  [self.artist setAlbums:@[album]];

  [[self.artist mutableArrayValueForKey:@"albums"] removeObject:album];

  XCTAssertEqual(self.relationalCollectionControllerRemovedObjectAtIndexParameters.count, 1);
  NSArray *expected = @[self.controller, album, @0];
  XCTAssertEqualObjects(self.relationalCollectionControllerRemovedObjectAtIndexParameters.firstObject, expected);
}

- (void)testRelationalCollectionControllerMovedObjectFromIndexToIndex {
  Album *album1 = [Album new];
  album1.releaseDate = [NSDate dateWithTimeIntervalSinceNow:0];
  Album *album2 = [Album new];
  album2.releaseDate = [NSDate dateWithTimeIntervalSinceNow:1];
  Album *album3 = [Album new];
  album3.releaseDate = [NSDate dateWithTimeIntervalSinceNow:2];

  [self.artist setAlbums:@[album1, album2, album3]];

  album1.releaseDate = [NSDate dateWithTimeIntervalSinceNow:3];

  XCTAssertEqual(self.relationalCollectionControllerMovedObjectFromIndexToIndexParameters.count, 1);
  NSArray *expected = @[self.controller, album1, @0, @2];
  XCTAssertEqualObjects(self.relationalCollectionControllerMovedObjectFromIndexToIndexParameters.firstObject, expected);
}

- (void)testRelationalCollectionControllerUpdatedObjectAtIndexChangedKeyPath {
  Album *album = [Album new];
  album.releaseDate = [NSDate dateWithTimeIntervalSinceNow:0];

  [self.artist setAlbums:@[album]];

  album.title = @"New Title";

  XCTAssertEqual(self.relationalCollectionControllerUpdatedObjectAtIndexChangedKeyPathParameters.count, 1);
  NSArray *expected = @[self.controller, album, @0, @"title"];
  XCTAssertEqualObjects(self.relationalCollectionControllerUpdatedObjectAtIndexChangedKeyPathParameters.firstObject, expected);
}

- (void)testRelationalCollectionControllerRemovedObjectAtIndexViaPredicateChangeOut {
  Album *album = [Album new];
  album.releaseDate = [NSDate dateWithTimeIntervalSinceNow:0];

  [self.artist setAlbums:@[album]];

  album.liveAlbum = YES;

  XCTAssertEqual(self.relationalCollectionControllerRemovedObjectAtIndexParameters.count, 1);
  NSArray *expected = @[self.controller, album, @0];
  XCTAssertEqualObjects(self.relationalCollectionControllerRemovedObjectAtIndexParameters.firstObject, expected);
}

- (void)testNoRelationalCollectionControllerInsertedObjectAtIndexOnPredicateFailureInsertion {
  Album *album1 = [Album new];
  album1.releaseDate = [NSDate dateWithTimeIntervalSinceNow:0];

  [self.artist setAlbums:@[album1]];

  Album *album2 = [Album new];
  album2.releaseDate = [NSDate dateWithTimeIntervalSinceNow:1];
  album2.liveAlbum = YES;

  [[self.artist mutableArrayValueForKey:@"albums"] addObject:album2];

  XCTAssertEqual(self.relationalCollectionControllerInsertedObjectAtIndexParameters.count, 0);
}

- (void)testRelationalCollectionControllerInsertedObjectAtIndexViaPredicateChangeIn {
  Album *album1 = [Album new];
  album1.releaseDate = [NSDate dateWithTimeIntervalSinceNow:0];
  Album *album2 = [Album new];
  album2.releaseDate = [NSDate dateWithTimeIntervalSinceNow:1];
  album2.liveAlbum = YES;

  [self.artist setAlbums:@[album1, album2]];

  album2.liveAlbum = NO;

  XCTAssertEqual(self.relationalCollectionControllerInsertedObjectAtIndexParameters.count, 1);
  NSArray *expected = @[self.controller, album2, @1];
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