//
//  MZTrackEditViewController.m
//  MZRelationalCollectionController
//
//  Created by Mat Trudel on 2015-11-26.
//  Copyright © 2015 Mat Trudel. All rights reserved.
//

#import "MZTrackEditViewController.h"

#import "Song.h"

@interface MZTrackEditViewController () <UIPickerViewDelegate, UIPickerViewDataSource>
@property IBOutlet UITextField *titleField;
@property IBOutlet UITextField *durationField;
@property IBOutlet UIPickerView *durationPicker;
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

- (IBAction)textDidChange:(UITextField *)textField
{
    if (textField == self.titleField) {
        self.track.title = textField.text;
    }
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
    NSInteger minutes = fmod(trunc(self.track.duration / 60.0), 60.0);
    NSInteger seconds = fmod(self.track.duration, 60.0);
    [self.durationPicker selectRow:minutes inComponent:0 animated:NO];
    [self.durationPicker selectRow:seconds inComponent:1 animated:NO];
    self.durationField.text = [NSString stringWithFormat:@"%02ld:%02ld", minutes, seconds];
}

- (NSTimeInterval)durationFromPicker
{
    NSInteger minutes = [self.durationPicker selectedRowInComponent:0];
    NSInteger seconds = [self.durationPicker selectedRowInComponent:1];
    return (minutes * 60) + seconds;
}

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
    return 2;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
{
    if (component == 0) {
        return 30;
    } else {
        return 60;
    }
}

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component
{
    if (component == 0) {
        return [NSString stringWithFormat:@"%ld min", row];
    } else {
        return [NSString stringWithFormat:@"%ld sec", row];
    }
}

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component
{
    self.track.duration = [self durationFromPicker];
    [self updateUIFromAlbum];
}

@end
