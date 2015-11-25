//
//  ArrayArtist.h
//  MZRelationalCollectionController
//
//  Created by Mat Trudel on 2015-11-25.
//  Copyright © 2015 Mat Trudel. All rights reserved.
//

#import <Foundation/Foundation.h>

@class Album;

@interface ArrayArtist : NSObject
@property NSString *name;
@property NSArray<Album *> *albums;
@end
