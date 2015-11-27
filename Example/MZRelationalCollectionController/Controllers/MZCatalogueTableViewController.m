//
//  MZCatalogueTableViewController.m
//  MZRelationalCollectionController
//
//  Created by Mat Trudel on 2015-11-25.
//  Copyright © 2015 Mat Trudel. All rights reserved.
//

#import "MZCatalogueTableViewController.h"

#import <MZRelationalCollectionController/MZRelationalCollectionController.h>

#import "MZArtistTableViewController.h"
#import "MZArtistEditViewController.h"

#import "Catalogue.h"
#import "Artist.h"

@interface MZCatalogueTableViewController () <MZRelationalCollectionControllerDelegate>
@property MZRelationalCollectionController *artistsController;
@end

@implementation MZCatalogueTableViewController

#pragma mark - UITableViewDelegate & UITableViewDatasource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.artistsController.collection.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"artistCell" forIndexPath:indexPath];
    Artist *artist = self.artistsController.collection[indexPath.row];
    cell.textLabel.text = artist.name;
    cell.detailTextLabel.text = [NSString stringWithFormat:@"%ld albums", (unsigned long)artist.albums.count];
    return cell;
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return UITableViewCellEditingStyleDelete;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    Artist *artist = self.artistsController.collection[indexPath.row];
    [[self.catalogue mutableSetValueForKey:@"artists"] removeObject:artist];
}

#pragma mark - Segues

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"showArtist"]) {
        NSIndexPath *indexPath = [self.tableView indexPathForCell:sender];
        Artist *artist = self.artistsController.collection[indexPath.row];
        ((MZArtistTableViewController *)segue.destinationViewController).artist = artist;
    } else if ([segue.identifier isEqualToString:@"editArtist"]) {
        NSIndexPath *indexPath = [self.tableView indexPathForCell:sender];
        Artist *artist = self.artistsController.collection[indexPath.row];
        segue.destinationViewController.navigationItem.leftBarButtonItem = nil;
        segue.destinationViewController.navigationItem.rightBarButtonItem = nil;
        segue.destinationViewController.title = @"Edit Artist";
        ((MZArtistEditViewController *)segue.destinationViewController).artist = artist;
    } else if ([segue.identifier isEqualToString:@"newArtist"]) {
        Artist *artist = [Artist new];
        UINavigationController *navigationController = segue.destinationViewController;
        navigationController.viewControllers.firstObject.title = @"New Artist";
        ((MZArtistEditViewController *)navigationController.viewControllers.firstObject).artist = artist;
    }
}

- (IBAction)cancel:(UIStoryboardSegue *)unwindSegue
{
    // NOP
}

- (IBAction)done:(UIStoryboardSegue *)unwindSegue
{
    Artist *artist = ((MZArtistEditViewController *)unwindSegue.sourceViewController).artist;
    [[self.catalogue mutableSetValueForKey:@"artists"] addObject:artist];
}

#pragma mark - Data management

- (void)setCatalogue:(Catalogue *)catalogue
{
    _catalogue = catalogue;
    self.artistsController = [MZRelationalCollectionController collectionControllerForRelation:@"artists"
                                                                                      onObject:self.catalogue
                                                                                    filteredBy:nil
                                                                                      sortedBy:@[[NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES]]
                                                                        observingChildKeyPaths:@[@"name", @"albums"]
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
