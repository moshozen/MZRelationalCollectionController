//
//  Catalogue.m
//  MZRelationalCollectionController
//
//  Created by Mat Trudel on 2015-11-25.
//  Copyright © 2015 Mat Trudel. All rights reserved.
//

#import "Catalogue.h"

@implementation Catalogue

- (instancetype)init
{
    if (self = [super init]) {
        self.artists = [NSSet set];
    }
    return self;
}

@end
