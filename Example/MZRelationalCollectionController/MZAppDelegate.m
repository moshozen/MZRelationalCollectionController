//
//  MZAppDelegate.m
//  MZRelationalCollectionController
//
//  Created by CocoaPods on 05/15/2015.
//  Copyright (c) 2014 Mat Trudel. All rights reserved.
//

#import "MZAppDelegate.h"

#import "MZCatalogueTableViewController.h"

#import "Catalogue.h"

@interface MZAppDelegate ()
@property Catalogue *catalogue;
@end

@implementation MZAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.catalogue = [Catalogue new];
    UINavigationController *rootViewController = ((UINavigationController *)self.window.rootViewController);
    MZCatalogueTableViewController *catalogViewController = rootViewController.viewControllers.firstObject;
    catalogViewController.catalogue = self.catalogue;
    return YES;
}

@end
