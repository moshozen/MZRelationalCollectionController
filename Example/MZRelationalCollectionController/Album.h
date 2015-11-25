//
//  Album.h
//  MZRelationalCollectionController
//
//  Created by Mat Trudel on 2015-11-25.
//  Copyright © 2015 Mat Trudel. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Album : NSObject
@property NSString *title;
@property NSDate *releaseDate;
@property BOOL liveAlbum;
@property NSArray *tracks;
@end
