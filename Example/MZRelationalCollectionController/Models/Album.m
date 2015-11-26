//
//  Album.m
//  MZRelationalCollectionController
//
//  Created by Mat Trudel on 2015-11-25.
//  Copyright © 2015 Mat Trudel. All rights reserved.
//

#import "Album.h"

@implementation Album

- (instancetype)init
{
    if (self = [super init]) {
        self.tracks = @[];
    }
    return self;
}

@end
