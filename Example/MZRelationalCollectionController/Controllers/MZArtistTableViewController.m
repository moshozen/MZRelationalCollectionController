//
//  MZArtistTableViewController.m
//  MZRelationalCollectionController
//
//  Created by Mat Trudel on 2015-11-25.
//  Copyright © 2015 Mat Trudel. All rights reserved.
//

#import "MZArtistTableViewController.h"

#import "Artist.h"

@implementation MZArtistTableViewController

- (void)setArtist:(Artist *)artist
{
    _artist = artist;
    self.title = artist.name;
}

@end
