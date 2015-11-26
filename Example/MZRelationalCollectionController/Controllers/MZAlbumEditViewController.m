//
//  MZAlbumEditViewController.m
//  MZRelationalCollectionController
//
//  Created by Mat Trudel on 2015-11-26.
//  Copyright © 2015 Mat Trudel. All rights reserved.
//

#import "MZAlbumEditViewController.h"

#import "Album.h"

@interface MZAlbumEditViewController ()
@property IBOutlet UITextField *titleField;
@property IBOutlet UITextField *releaseDateField;
@property IBOutlet UIDatePicker *datePicker;
@property IBOutlet UITableViewCell *titleCell;
@property IBOutlet UITableViewCell *releaseDateCell;
@property IBOutlet UITableViewCell *liveAlbumCell;
@end

@implementation MZAlbumEditViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.releaseDateField.inputView = self.datePicker;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.titleField.text = self.album.title;
    [self.titleField becomeFirstResponder];
    [self updateUIFromAlbum];
}

- (IBAction)editingDidBegin:(UITextField *)textField
{
    if (textField == self.releaseDateField && !self.album.releaseDate) {
        self.album.releaseDate = self.datePicker.date;
        [self updateUIFromAlbum];
    }
}

- (IBAction)textDidChange:(UITextField *)textField
{
    if (textField == self.titleField) {
        self.album.title = textField.text;
    }
}

- (IBAction)dateDidChange:(UIDatePicker *)datePicker
{
    if (datePicker == self.datePicker) {
        self.album.releaseDate = datePicker.date;
    }
    [self updateUIFromAlbum];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(nonnull NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    if (cell == self.titleCell) {
        [self.titleField becomeFirstResponder];
    } else if (cell == self.releaseDateCell) {
        [self.releaseDateField becomeFirstResponder];
    } else if (cell == self.liveAlbumCell) {
        [self.titleField resignFirstResponder];
        [self.releaseDateField resignFirstResponder];
        self.album.liveAlbum = !self.album.liveAlbum;
    }
    [self updateUIFromAlbum];
}

- (void)updateUIFromAlbum
{
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.timeStyle = NSDateFormatterNoStyle;
    dateFormatter.dateStyle = NSDateFormatterMediumStyle;

    self.releaseDateField.text = [dateFormatter stringFromDate:self.album.releaseDate];
    self.liveAlbumCell.accessoryType = self.album.liveAlbum? UITableViewCellAccessoryCheckmark : UITableViewCellEditingStyleNone;
}

@end
