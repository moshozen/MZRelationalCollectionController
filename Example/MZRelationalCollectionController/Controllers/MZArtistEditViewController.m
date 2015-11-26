//
//  MZArtistEditViewController.m
//  MZRelationalCollectionController
//
//  Created by Mat Trudel on 2015-11-26.
//  Copyright © 2015 Mat Trudel. All rights reserved.
//

#import "MZArtistEditViewController.h"

#import "Artist.h"

@interface MZArtistEditViewController ()
@property IBOutlet UITextField *nameField;
@end

@implementation MZArtistEditViewController

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.nameField.text = self.artist.name;
    [self.nameField becomeFirstResponder];
}

- (IBAction)textDidChange:(UITextField *)textField
{
    if (textField == self.nameField) {
        self.artist.name = textField.text;
    }
}

@end
