//
//  MZCatalogueTableViewController.h
//  MZRelationalCollectionController
//
//  Created by Mat Trudel on 2015-11-25.
//  Copyright © 2015 Mat Trudel. All rights reserved.
//

#import <UIKit/UIKit.h>

@class Catalogue;

@interface MZCatalogueTableViewController : UITableViewController
@property(nonatomic) Catalogue *catalogue;
@end
