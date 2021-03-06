//
//  Artist.h
//  MZRelationalCollectionController
//
//  Created by Mat Trudel on 2015-11-25.
//  Copyright © 2015 Mat Trudel. All rights reserved.
//

#import <Foundation/Foundation.h>

@class Album;

@interface Artist : NSObject
@property NSString *name;
@property NSSet<Album *> *albums;
@end
