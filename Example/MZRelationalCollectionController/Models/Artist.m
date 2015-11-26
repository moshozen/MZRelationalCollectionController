//
//  Artist.m
//  MZRelationalCollectionController
//
//  Created by Mat Trudel on 2015-11-25.
//  Copyright © 2015 Mat Trudel. All rights reserved.
//

#import "Artist.h"

@implementation Artist

- (instancetype)init
{
    if (self = [super init]) {
        self.albums = [NSSet set];
    }
    return self;
}

@end
