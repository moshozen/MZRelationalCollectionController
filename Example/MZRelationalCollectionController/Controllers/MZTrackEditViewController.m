//
//  MZTrackEditViewController.m
//  MZRelationalCollectionController
//
//  Created by Mat Trudel on 2015-11-26.
//  Copyright © 2015 Mat Trudel. All rights reserved.
//

#import "MZTrackEditViewController.h"

#import "Song.h"

@interface MZTrackEditViewController ()
@property IBOutlet UITextField *titleField;
@property IBOutlet UITextField *durationField;
@property IBOutlet UIDatePicker *durationPicker;
@property IBOutlet UITableViewCell *titleCell;
@property IBOutlet UITableViewCell *durationCell;
@end

@implementation MZTrackEditViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.durationField.inputView = self.durationPicker;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.titleField.text = self.track.title;
    [self.titleField becomeFirstResponder];
    [self updateUIFromAlbum];
}

- (IBAction)editingDidBegin:(UITextField *)textField
{
    if (textField == self.durationField && self.track.duration == 0) {
        self.track.duration = self.durationPicker.countDownDuration;
        [self updateUIFromAlbum];
    }
}

- (IBAction)textDidChange:(UITextField *)textField
{
    if (textField == self.titleField) {
        self.track.title = textField.text;
    }
}

- (IBAction)dateDidChange:(UIDatePicker *)datePicker
{
    if (datePicker == self.durationPicker) {
        self.track.duration = datePicker.countDownDuration;
    }
    [self updateUIFromAlbum];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(nonnull NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    if (cell == self.titleCell) {
        [self.titleField becomeFirstResponder];
    } else if (cell == self.durationCell) {
        [self.durationField becomeFirstResponder];
    }
}

- (void)updateUIFromAlbum
{
    self.durationField.text = [NSString stringWithFormat:@"%ld seconds", (NSInteger)self.track.duration];
}

@end
