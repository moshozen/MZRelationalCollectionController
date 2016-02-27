//
//  MZRelationalCollectionControllerTest.m
//
//  Created by Mat Trudel on 2014-10-15.
//  Copyright (c) 2014 Moshozen Inc. All rights reserved.
//

@import XCTest;

#import <MZRelationalCollectionController/MZRelationalCollectionController.h>

#import "Artist.h"
#import "Album.h"

@interface MZRelationalCollectionControllerTest : XCTestCase
@property Artist *artist;
@property MZRelationalCollectionController *controller;
@end

@implementation MZRelationalCollectionControllerTest

- (void)setUp {
    [super setUp];
    self.artist = [Artist new];
}

@end

@interface MZRelationalCollectionControllerMembershipTest : MZRelationalCollectionControllerTest
@end

@implementation MZRelationalCollectionControllerMembershipTest

- (void)setUp {
    [super setUp];
    self.controller = [MZRelationalCollectionController collectionControllerForRelation:@"albums"
                                                                               onObject:self.artist
                                                                             filteredBy:[NSPredicate predicateWithFormat:@"liveAlbum != YES"]
                                                                               sortedBy:@[[NSSortDescriptor sortDescriptorWithKey:@"releaseDate" ascending:YES]]
                                                                 observingChildKeyPaths:@[@"title"]
                                                                               delegate:nil];
}

- (void)testAssignment {
    Album *album = [Album new];
    [self.artist setAlbums:[NSSet setWithObject:album]];

    XCTAssertEqualObjects(self.controller.collection, @[album]);
}

- (void)testReassignment {
    Album *album = [Album new];
    [self.artist setAlbums:[NSSet setWithObject:album]];
    [self.artist setAlbums:[NSSet set]];

    XCTAssertEqualObjects(self.controller.collection, @[]);
}

- (void)testNilReassignment {
    Album *album = [Album new];
    [self.artist setAlbums:[NSSet setWithObject:album]];
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

    [self.artist setAlbums:[NSSet setWithObjects:album1, album2, album3, nil]];

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

    [self.artist setAlbums:[NSSet setWithObjects:album1, album2, album3, nil]];

    album1.releaseDate = [NSDate dateWithTimeIntervalSinceNow:3];

    NSArray *expected = @[album2, album3, album1];
    XCTAssertEqualObjects(self.controller.collection, expected);
}

- (void)testInsertion {
    Album *album1 = [Album new];
    album1.releaseDate = [NSDate dateWithTimeIntervalSinceNow:0];
    Album *album3 = [Album new];
    album3.releaseDate = [NSDate dateWithTimeIntervalSinceNow:2];

    [self.artist setAlbums:[NSSet setWithObjects:album1, album3, nil]];

    Album *album2 = [Album new];
    album2.releaseDate = [NSDate dateWithTimeIntervalSinceNow:1];

    [[self.artist mutableSetValueForKey:@"albums"] addObject:album2];

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

    [self.artist setAlbums:[NSSet setWithObjects:album1, album2, album3, nil]];

    [[self.artist mutableSetValueForKey:@"albums"] removeObject:album2];

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

    [self.artist setAlbums:[NSSet setWithObjects:album1, album2, album3, nil]];

    [[self.artist mutableSetValueForKey:@"albums"] removeObject:album2];

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

    [self.artist setAlbums:[NSSet setWithObjects:album1, album2, album3, nil]];

    album1.liveAlbum = YES;

    NSArray *expected = @[album2, album3];
    XCTAssertEqualObjects(self.controller.collection, expected);
}

- (void)testPredicateFilteringOnInsertion {
    Album *album1 = [Album new];
    album1.releaseDate = [NSDate dateWithTimeIntervalSinceNow:0];
    Album *album3 = [Album new];
    album3.releaseDate = [NSDate dateWithTimeIntervalSinceNow:2];

    [self.artist setAlbums:[NSSet setWithObjects:album1, album3, nil]];

    Album *album2 = [Album new];
    album2.releaseDate = [NSDate dateWithTimeIntervalSinceNow:1];
    album2.liveAlbum = YES;

    [[self.artist mutableSetValueForKey:@"albums"] addObject:album2];

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

    [self.artist setAlbums:[NSSet setWithObjects:album1, album2, album3, nil]];

    album2.liveAlbum = NO;

    NSArray *expected = @[album1, album2, album3];
    XCTAssertEqualObjects(self.controller.collection, expected);
}

- (void)testPredicateFilteringOnChangeInWhenOverlapsWithSortPredicates {
    NSDate *date = [NSDate date];
    self.controller = [MZRelationalCollectionController collectionControllerForRelation:@"albums"
                                                                               onObject:self.artist
                                                                             filteredBy:[NSPredicate predicateWithFormat:@"releaseDate > %@", [date dateByAddingTimeInterval:1]]
                                                                               sortedBy:@[[NSSortDescriptor sortDescriptorWithKey:@"releaseDate" ascending:YES]]
                                                                 observingChildKeyPaths:@[@"releaseDate"]
                                                                               delegate:nil];

    Album *album1 = [Album new];
    album1.releaseDate = [date dateByAddingTimeInterval:0];
    Album *album2 = [Album new];
    album2.releaseDate = [date dateByAddingTimeInterval:2];

    [self.artist setAlbums:[NSSet setWithObjects:album1, album2, nil]];
    album1.releaseDate = [date dateByAddingTimeInterval:3];

    NSArray *expected = @[album2, album1];
    XCTAssertEqualObjects(self.controller.collection, expected);
}

- (void)testPredicateFilteringOnChangeOutWhenOverlapsWithSortPredicates {
    NSDate *date = [NSDate date];
    self.controller = [MZRelationalCollectionController collectionControllerForRelation:@"albums"
                                                                               onObject:self.artist
                                                                             filteredBy:[NSPredicate predicateWithFormat:@"releaseDate > %@", [date dateByAddingTimeInterval:1]]
                                                                               sortedBy:@[[NSSortDescriptor sortDescriptorWithKey:@"releaseDate" ascending:YES]]
                                                                 observingChildKeyPaths:@[@"releaseDate"]
                                                                               delegate:nil];

    Album *album1 = [Album new];
    album1.releaseDate = [date dateByAddingTimeInterval:2];
    Album *album2 = [Album new];
    album2.releaseDate = [date dateByAddingTimeInterval:3];

    [self.artist setAlbums:[NSSet setWithObjects:album1, album2, nil]];
    album1.releaseDate = [date dateByAddingTimeInterval:1];

    NSArray *expected = @[album2];
    XCTAssertEqualObjects(self.controller.collection, expected);
}

- (void)testWithNoFilterOrSortDescriptors {
    self.controller = [MZRelationalCollectionController collectionControllerForRelation:@"albums"
                                                                               onObject:self.artist
                                                                             filteredBy:nil
                                                                               sortedBy:nil
                                                                 observingChildKeyPaths:nil
                                                                               delegate:nil];
    Album *album1 = [Album new];
    album1.releaseDate = [NSDate dateWithTimeIntervalSinceNow:0];
    Album *album2 = [Album new];
    album2.releaseDate = [NSDate dateWithTimeIntervalSinceNow:1];
    Album *album3 = [Album new];
    album3.releaseDate = [NSDate dateWithTimeIntervalSinceNow:2];

    [self.artist setAlbums:[NSSet setWithObjects:album1, album2, album3, nil]];

    NSSet *expected = [NSSet setWithObjects:album1, album2, album3, nil];
    XCTAssertEqualObjects([NSSet setWithArray:self.controller.collection], expected);
}

- (void)testObjectBasedPredicateFilteringOnObjects {
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
    [self.artist setAlbums:[NSSet setWithObjects:album1, album2, album3, nil]];
    NSArray *expected = @[album2, album3];
    XCTAssertEqualObjects(self.controller.collection, expected);
}

@end

@interface MZRelationalCollectionControllerDelegateTest : MZRelationalCollectionControllerTest <MZRelationalCollectionControllerDelegate>
@property NSMutableArray *delegateCalls;
@end

@implementation MZRelationalCollectionControllerDelegateTest

- (void)setUp {
    [super setUp];
    self.delegateCalls = [NSMutableArray array];
}

// Delegate methods

- (void)relationalCollectionControllerWillChangeContent:(MZRelationalCollectionController *)controller
{
    [self.delegateCalls addObject:@[@"willChange", controller]];
}

- (void)relationalCollectionControllerDidChangeContent:(MZRelationalCollectionController *)controller
{
    [self.delegateCalls addObject:@[@"didChange", controller]];
}

- (void)relationalCollectionControllerReplacedEntireCollection:(MZRelationalCollectionController *)controller
{
    [self.delegateCalls addObject:@[@"replacedEntireCollection", controller]];
}

- (void)relationalCollectionController:(MZRelationalCollectionController *)controller insertedObject:(id)object atIndex:(NSUInteger)index
{
    [self.delegateCalls addObject:@[@"insert", controller, object, @(index)]];
}

- (void)relationalCollectionController:(MZRelationalCollectionController *)controller removedObject:(id)object atIndex:(NSUInteger)index
{
    [self.delegateCalls addObject:@[@"remove", controller, object, @(index)]];
}

- (void)relationalCollectionController:(MZRelationalCollectionController *)controller movedObject:(id)object fromIndex:(NSUInteger)fromIndex toIndex:(NSUInteger)toIndex
{
    [self.delegateCalls addObject:@[@"move", controller, object, @(fromIndex), @(toIndex)]];
}

- (void)relationalCollectionController:(MZRelationalCollectionController *)controller updatedObject:(id)object atIndex:(NSUInteger)index changedKeyPath:(NSString *)keyPath
{
    [self.delegateCalls addObject:@[@"update", controller, object, @(index), keyPath]];
}

@end

@interface MZRelationalCollectionControllerMembershipDelegateTest : MZRelationalCollectionControllerDelegateTest
@end

@implementation MZRelationalCollectionControllerMembershipDelegateTest

- (void)setUp {
    [super setUp];
    self.controller = [MZRelationalCollectionController collectionControllerForRelation:@"albums"
                                                                               onObject:self.artist
                                                                             filteredBy:[NSPredicate predicateWithFormat:@"liveAlbum != YES"]
                                                                               sortedBy:@[[NSSortDescriptor sortDescriptorWithKey:@"releaseDate" ascending:YES]]
                                                                 observingChildKeyPaths:@[@"title"]
                                                                               delegate:self];
}

- (void)testRelationalCollectionControllerReplacement {
    Album *album = [Album new];
    album.releaseDate = [NSDate dateWithTimeIntervalSinceNow:0];

    [self.artist setAlbums:[NSSet setWithObject:album]];

    NSArray *expected = @[@[@"willChange", self.controller],
                          @[@"replacedEntireCollection", self.controller],
                          @[@"didChange", self.controller]];
    XCTAssertEqualObjects(self.delegateCalls, expected);
}

- (void)testRelationalCollectionControllerInsertedObjectAtIndex {
    Album *album = [Album new];
    album.releaseDate = [NSDate dateWithTimeIntervalSinceNow:0];

    [[self.artist mutableSetValueForKey:@"albums"] addObject:album];

    NSArray *expected = @[@[@"willChange", self.controller],
                          @[@"insert", self.controller, album, @0],
                          @[@"didChange", self.controller]];
    XCTAssertEqualObjects(self.delegateCalls, expected);
}

- (void)testRelationalCollectionControllerRemovedObjectAtIndex {
    Album *album = [Album new];
    album.releaseDate = [NSDate dateWithTimeIntervalSinceNow:0];

    [self.artist setAlbums:[NSSet setWithObject:album]];

    [[self.artist mutableSetValueForKey:@"albums"] removeObject:album];

    NSArray *expected = @[@[@"willChange", self.controller],
                          @[@"replacedEntireCollection", self.controller],
                          @[@"didChange", self.controller],
                          @[@"willChange", self.controller],
                          @[@"remove", self.controller, album, @0],
                          @[@"didChange", self.controller]];
    XCTAssertEqualObjects(self.delegateCalls, expected);
}

- (void)testRelationalCollectionControllerMovedObjectFromIndexToIndex {
    Album *album1 = [Album new];
    album1.releaseDate = [NSDate dateWithTimeIntervalSinceNow:0];
    Album *album2 = [Album new];
    album2.releaseDate = [NSDate dateWithTimeIntervalSinceNow:1];
    Album *album3 = [Album new];
    album3.releaseDate = [NSDate dateWithTimeIntervalSinceNow:2];

    [self.artist setAlbums:[NSSet setWithObjects:album1, album2, album3, nil]];

    album1.releaseDate = [NSDate dateWithTimeIntervalSinceNow:3];

    NSArray *expected = @[@[@"willChange", self.controller],
                          @[@"replacedEntireCollection", self.controller],
                          @[@"didChange", self.controller],
                          @[@"willChange", self.controller],
                          @[@"move", self.controller, album1, @0, @2],
                          @[@"didChange", self.controller]];
    XCTAssertEqualObjects(self.delegateCalls, expected);
}

- (void)testRelationalCollectionControllerUpdatedObjectAtIndexChangedKeyPath {
    Album *album = [Album new];
    album.releaseDate = [NSDate dateWithTimeIntervalSinceNow:0];

    [self.artist setAlbums:[NSSet setWithObject:album]];

    album.title = @"New Title";

    NSArray *expected = @[@[@"willChange", self.controller],
                          @[@"replacedEntireCollection", self.controller],
                          @[@"didChange", self.controller],
                          @[@"willChange", self.controller],
                          @[@"update", self.controller, album, @0, @"title"],
                          @[@"didChange", self.controller]];
    XCTAssertEqualObjects(self.delegateCalls, expected);
}

- (void)testRelationalCollectionControllerRemovedObjectAtIndexViaPredicateChangeOut {
    Album *album = [Album new];
    album.releaseDate = [NSDate dateWithTimeIntervalSinceNow:0];

    [self.artist setAlbums:[NSSet setWithObject:album]];

    album.liveAlbum = YES;

    NSArray *expected = @[@[@"willChange", self.controller],
                          @[@"replacedEntireCollection", self.controller],
                          @[@"didChange", self.controller],
                          @[@"willChange", self.controller],
                          @[@"remove", self.controller, album, @0],
                          @[@"didChange", self.controller]];
    XCTAssertEqualObjects(self.delegateCalls, expected);
}

- (void)testNoRelationalCollectionControllerInsertedObjectAtIndexOnPredicateFailureInsertion {
    Album *album1 = [Album new];
    album1.releaseDate = [NSDate dateWithTimeIntervalSinceNow:0];

    [self.artist setAlbums:[NSSet setWithObject:album1]];

    Album *album2 = [Album new];
    album2.releaseDate = [NSDate dateWithTimeIntervalSinceNow:1];
    album2.liveAlbum = YES;

    [[self.artist mutableSetValueForKey:@"albums"] addObject:album2];

    NSArray *expected = @[@[@"willChange", self.controller],
                          @[@"replacedEntireCollection", self.controller],
                          @[@"didChange", self.controller],
                          @[@"willChange", self.controller],
                          @[@"didChange", self.controller]];
    XCTAssertEqualObjects(self.delegateCalls, expected);
}

- (void)testRelationalCollectionControllerInsertedObjectAtIndexViaPredicateChangeIn {
    Album *album1 = [Album new];
    album1.releaseDate = [NSDate dateWithTimeIntervalSinceNow:0];
    Album *album2 = [Album new];
    album2.releaseDate = [NSDate dateWithTimeIntervalSinceNow:1];
    album2.liveAlbum = YES;

    [self.artist setAlbums:[NSSet setWithObjects:album1, album2, nil]];

    album2.liveAlbum = NO;

    NSArray *expected = @[@[@"willChange", self.controller],
                          @[@"replacedEntireCollection", self.controller],
                          @[@"didChange", self.controller],
                          @[@"willChange", self.controller],
                          @[@"insert", self.controller, album2, @1],
                          @[@"didChange", self.controller]];
    XCTAssertEqualObjects(self.delegateCalls, expected);
}

@end

@interface MZRelationalCollectionControllerDelegateThreadingTest : MZRelationalCollectionControllerDelegateTest
@property XCTestExpectation *didChangeContentDelegateCallExpectation;
@end

@implementation MZRelationalCollectionControllerDelegateThreadingTest

- (void)relationalCollectionControllerWillChangeContent:(MZRelationalCollectionController *)controller
{
    [self.delegateCalls addObject:@[@"willChange", controller, [NSThread currentThread]]];
}

- (void)relationalCollectionControllerDidChangeContent:(MZRelationalCollectionController *)controller
{
    [self.delegateCalls addObject:@[@"didChange", controller, [NSThread currentThread]]];
    [self.didChangeContentDelegateCallExpectation fulfill];
}

- (void)relationalCollectionControllerReplacedEntireCollection:(MZRelationalCollectionController *)controller
{
    [self.delegateCalls addObject:@[@"replacedEntireCollection", controller, [NSThread currentThread]]];
}

- (void)setUp {
    [super setUp];
    self.controller = [MZRelationalCollectionController collectionControllerForRelation:@"albums"
                                                                               onObject:self.artist
                                                                             filteredBy:[NSPredicate predicateWithFormat:@"liveAlbum != YES"]
                                                                               sortedBy:@[[NSSortDescriptor sortDescriptorWithKey:@"releaseDate" ascending:YES]]
                                                                 observingChildKeyPaths:@[@"title"]
                                                                               delegate:self];
}

- (void)testRelationalCollectionControllerRunningOnBackgroundThread {
    self.didChangeContentDelegateCallExpectation = [self expectationWithDescription:@"That background dispatch has happened"];

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
        XCTAssert(![NSThread isMainThread]);
        Album *album = [Album new];
        album.releaseDate = [NSDate dateWithTimeIntervalSinceNow:0];

        [self.artist setAlbums:[NSSet setWithObject:album]];
    });

    [self waitForExpectationsWithTimeout:5.0 handler:^(NSError *error) {
        if (error) {
            NSLog(@"Timeout Error: %@", error);
        }
    }];

    NSArray *expected = @[@[@"willChange", self.controller, [NSThread mainThread]],
                          @[@"replacedEntireCollection", self.controller, [NSThread mainThread]],
                          @[@"didChange", self.controller, [NSThread mainThread]]];
    XCTAssertEqualObjects(self.delegateCalls, expected);
}

@end
@interface MZRelationalCollectionControllerOverlappingKeypathsDelegateTest : MZRelationalCollectionControllerDelegateTest
@property NSDate *date;
@end

@implementation MZRelationalCollectionControllerOverlappingKeypathsDelegateTest

- (void)setUp {
    [super setUp];
    self.date = [NSDate date];
    self.controller = [MZRelationalCollectionController collectionControllerForRelation:@"albums"
                                                                               onObject:self.artist
                                                                             filteredBy:[NSPredicate predicateWithFormat:@"releaseDate > %@", [self.date dateByAddingTimeInterval:1]]
                                                                               sortedBy:@[[NSSortDescriptor sortDescriptorWithKey:@"releaseDate" ascending:YES]]
                                                                 observingChildKeyPaths:@[@"releaseDate"]
                                                                               delegate:self];
}

- (void)testOverlappingKeypathsOnInsertion {
    Album *album1 = [Album new];
    album1.releaseDate = [self.date dateByAddingTimeInterval:0];
    Album *album2 = [Album new];
    album2.releaseDate = [self.date dateByAddingTimeInterval:1];

    [self.artist setAlbums:[NSSet setWithObjects:album1, album2, nil]];
    album1.releaseDate = [self.date dateByAddingTimeInterval:2];

    NSArray *expected = @[@[@"willChange", self.controller],
                          @[@"replacedEntireCollection", self.controller],
                          @[@"didChange", self.controller],
                          @[@"willChange", self.controller],
                          @[@"insert", self.controller, album1, @0],
                          @[@"didChange", self.controller]];
    XCTAssertEqualObjects(self.delegateCalls, expected);
}

- (void)testOverlappingKeypathsOnDeletion {
    Album *album1 = [Album new];
    album1.releaseDate = [self.date dateByAddingTimeInterval:2];
    Album *album2 = [Album new];
    album2.releaseDate = [self.date dateByAddingTimeInterval:3];

    [self.artist setAlbums:[NSSet setWithObjects:album1, album2, nil]];
    album1.releaseDate = [self.date dateByAddingTimeInterval:1];

    NSArray *expected = @[@[@"willChange", self.controller],
                          @[@"replacedEntireCollection", self.controller],
                          @[@"didChange", self.controller],
                          @[@"willChange", self.controller],
                          @[@"remove", self.controller, album1, @0],
                          @[@"didChange", self.controller]];
    XCTAssertEqualObjects(self.delegateCalls, expected);
}

- (void)testOverlappingKeypathsOnUpdate {
    Album *album1 = [Album new];
    album1.releaseDate = [self.date dateByAddingTimeInterval:2];
    Album *album2 = [Album new];
    album2.releaseDate = [self.date dateByAddingTimeInterval:3];

    [self.artist setAlbums:[NSSet setWithObjects:album1, album2, nil]];
    album1.releaseDate = [self.date dateByAddingTimeInterval:4];

    NSArray *expected = @[@[@"willChange", self.controller],
                          @[@"replacedEntireCollection", self.controller],
                          @[@"didChange", self.controller],
                          @[@"willChange", self.controller],
                          @[@"move", self.controller, album1, @0, @1],
                          @[@"didChange", self.controller],
                          @[@"willChange", self.controller],
                          @[@"update", self.controller, album1, @1, @"releaseDate"],
                          @[@"didChange", self.controller]];
    XCTAssertEqualObjects(self.delegateCalls, expected);
}

@end