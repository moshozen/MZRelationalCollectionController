//
//  MZAlbumTableViewController.m
//  MZRelationalCollectionController
//
//  Created by Mat Trudel on 2015-11-25.
//  Copyright © 2015 Mat Trudel. All rights reserved.
//

#import "MZAlbumTableViewController.h"

#import <MZRelationalCollectionController/MZRelationalCollectionController.h>

#import "MZTrackEditViewController.h"

#import "Album.h"
#import "Song.h"

@interface MZAlbumTableViewController () <MZRelationalCollectionControllerDelegate>
@property MZRelationalCollectionController *tracksController;
@end

@implementation MZAlbumTableViewController

#pragma mark - UITableViewDelegate & UITableViewDatasource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.tracksController.collection.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"trackCell" forIndexPath:indexPath];
    Song *track = self.tracksController.collection[indexPath.row];
    cell.textLabel.text = track.title;
    cell.detailTextLabel.text = [NSString stringWithFormat:@"%ld seconds", (NSInteger)track.duration];
    return cell;
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return UITableViewCellEditingStyleDelete;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    Song *track = self.tracksController.collection[indexPath.row];
    [[self.album mutableArrayValueForKey:@"tracks"] removeObject:track];
}

#pragma mark - Segues

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"editTrack"]) {
        NSIndexPath *indexPath = [self.tableView indexPathForCell:sender];
        Song *track = self.tracksController.collection[indexPath.row];
        segue.destinationViewController.navigationItem.leftBarButtonItem = nil;
        segue.destinationViewController.navigationItem.rightBarButtonItem = nil;
        segue.destinationViewController.title = @"Edit Track";
        ((MZTrackEditViewController *)segue.destinationViewController).track = track;
    } else if ([segue.identifier isEqualToString:@"newTrack"]) {
        Song *track = [Song new];
        UINavigationController *navigationController = segue.destinationViewController;
        navigationController.viewControllers.firstObject.title = @"New Track";
        ((MZTrackEditViewController *)navigationController.viewControllers.firstObject).track = track;
    }
}

- (IBAction)cancel:(UIStoryboardSegue *)unwindSegue
{
    // NOP
}

- (IBAction)done:(UIStoryboardSegue *)unwindSegue
{
    Song *track = ((MZTrackEditViewController *)unwindSegue.sourceViewController).track;
    [[self.album mutableArrayValueForKey:@"tracks"] addObject:track];
}

#pragma mark - Data management

- (void)setAlbum:(Album *)album
{
    _album = album;;
    self.title = album.title;
    self.tracksController = [MZRelationalCollectionController collectionControllerForRelation:@"tracks"
                                                                                     onObject:self.album
                                                                                   filteredBy:nil
                                                                                     sortedBy:nil
                                                                       observingChildKeyPaths:@[@"title", @"duration"]
                                                                                     delegate:self];
}

#pragma mark - MZRelationalCollectionControllerDelegate

- (void)relationalCollectionControllerWillChangeContent:(MZRelationalCollectionController *)controller
{
    [self.tableView beginUpdates];
}

- (void)relationalCollectionController:(MZRelationalCollectionController *)controller insertedObject:(id)object atIndex:(NSUInteger)index
{
    [self.tableView insertRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:index inSection:0]] withRowAnimation:UITableViewRowAnimationAutomatic];
}

- (void)relationalCollectionController:(MZRelationalCollectionController *)controller removedObject:(id)object atIndex:(NSUInteger)index
{
    [self.tableView deleteRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:index inSection:0]] withRowAnimation:UITableViewRowAnimationAutomatic];
}

- (void)relationalCollectionController:(MZRelationalCollectionController *)controller movedObject:(id)object fromIndex:(NSUInteger)fromIndex toIndex:(NSUInteger)toIndex
{
    [self.tableView moveRowAtIndexPath:[NSIndexPath indexPathForRow:fromIndex inSection:0] toIndexPath:[NSIndexPath indexPathForRow:toIndex inSection:0]];
}

- (void)relationalCollectionController:(MZRelationalCollectionController *)controller updatedObject:(id)object atIndex:(NSUInteger)index changedKeyPath:(NSString *)keyPath
{
    [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:index inSection:0]] withRowAnimation:UITableViewRowAnimationAutomatic];
}

- (void)relationalCollectionControllerDidChangeContent:(MZRelationalCollectionController *)controller
{
    [self.tableView endUpdates];
}

@end
