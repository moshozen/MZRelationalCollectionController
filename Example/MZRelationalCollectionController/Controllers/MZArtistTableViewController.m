//
//  MZArtistTableViewController.m
//  MZRelationalCollectionController
//
//  Created by Mat Trudel on 2015-11-25.
//  Copyright © 2015 Mat Trudel. All rights reserved.
//

#import "MZArtistTableViewController.h"

#import <MZRelationalCollectionController/MZRelationalCollectionController.h>

#import "MZAlbumTableViewController.h"
#import "MZAlbumEditViewController.h"

#import "Artist.h"
#import "Album.h"

@interface MZArtistTableViewController () <MZRelationalCollectionControllerDelegate>
@property MZRelationalCollectionController *albumsController;
@end

@implementation MZArtistTableViewController

#pragma mark - UITableViewDelegate & UITableViewDatasource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.albumsController.collection.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"albumCell" forIndexPath:indexPath];
    Album *album = self.albumsController.collection[indexPath.row];
    if (album.liveAlbum) {
        cell.textLabel.text = [NSString stringWithFormat:@"%@ (Live)", album.title];
    } else {
        cell.textLabel.text = album.title;
    }
    cell.detailTextLabel.text = [NSString stringWithFormat:@"%ld songs", (unsigned long)album.tracks.count];
    return cell;
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return UITableViewCellEditingStyleDelete;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    Album *album = self.albumsController.collection[indexPath.row];
    [[self.artist mutableSetValueForKey:@"albums"] removeObject:album];
}

#pragma mark - Segues

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"showAlbum"]) {
        NSIndexPath *indexPath = [self.tableView indexPathForCell:sender];
        Album *album = self.albumsController.collection[indexPath.row];
        ((MZAlbumTableViewController *)segue.destinationViewController).album = album;
    } else if ([segue.identifier isEqualToString:@"editAlbum"]) {
        NSIndexPath *indexPath = [self.tableView indexPathForCell:sender];
        Album *album = self.albumsController.collection[indexPath.row];
        segue.destinationViewController.navigationItem.leftBarButtonItem = nil;
        segue.destinationViewController.navigationItem.rightBarButtonItem = nil;
        segue.destinationViewController.title = @"Edit Album";
        ((MZAlbumEditViewController *)segue.destinationViewController).album = album;
    } else if ([segue.identifier isEqualToString:@"newAlbum"]) {
        Album *album = [Album new];
        UINavigationController *navigationController = segue.destinationViewController;
        navigationController.viewControllers.firstObject.title = @"New Album";
        ((MZAlbumEditViewController *)navigationController.viewControllers.firstObject).album = album;
    }
}

- (IBAction)cancel:(UIStoryboardSegue *)unwindSegue
{
    // NOP
}

- (IBAction)done:(UIStoryboardSegue *)unwindSegue
{
    Album *album = ((MZAlbumEditViewController *)unwindSegue.sourceViewController).album;
    [[self.artist mutableSetValueForKey:@"albums"] addObject:album];
}

#pragma mark - Data management

- (void)setArtist:(Artist *)artist
{
    _artist = artist;
    self.title = artist.name;
    self.albumsController = [MZRelationalCollectionController collectionControllerForRelation:@"albums"
                                                                                        onObject:self.artist
                                                                                      filteredBy:nil
                                                                                        sortedBy:@[[NSSortDescriptor sortDescriptorWithKey:@"releaseDate" ascending:YES]]
                                                                          observingChildKeyPaths:@[@"title", @"liveAlbum", @"tracks"]
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
