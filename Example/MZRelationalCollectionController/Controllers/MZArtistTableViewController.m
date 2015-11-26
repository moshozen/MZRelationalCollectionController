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
    cell.textLabel.text = album.title;
    cell.detailTextLabel.text = [NSString stringWithFormat:@"%ld songs, %ld duration", album.tracks.count, [[album.tracks valueForKeyPath:@"@sum.duration"] integerValue]];
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
    }
}

#pragma mark - Album Creation support

- (IBAction)addAlbum:(id)sender
{
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Add Album" message:@"Enter the album title" preferredStyle:UIAlertControllerStyleAlert];
    [alertController addTextFieldWithConfigurationHandler:nil];
    [alertController addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
    [alertController addAction:[UIAlertAction actionWithTitle:@"Save" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        Album *album = [Album new];
        album.title = alertController.textFields.firstObject.text;
        [[self.artist mutableSetValueForKey:@"albums"] addObject:album];
    }]];
    [self presentViewController:alertController animated:YES completion:nil];
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
                                                                          observingChildKeyPaths:@[@"tracks"] // TODO -- this needs to observe duration as well
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
