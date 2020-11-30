//
//  OEXDownloadTableCell.m
//  edXVideoLocker
//
//  Created by Jotiram Bhagat on 30/06/14.
//  Copyright (c) 2014-2015 edX. All rights reserved.
//

#import "OEXStyles.h"
#import "OEXDownloadTableCell.h"

@implementation OEXDownloadTableCell

- (void)awakeFromNib {
    [super awakeFromNib];
    [self.lbl_title setTextAlignment:NSTextAlignmentNatural];
    [self.lbl_time setTextAlignment:NSTextAlignmentNatural];
    [self.lbl_totalSize setTextAlignment:NSTextAlignmentNatural];
    self.accessibilityTraits = UIAccessibilityTraitUpdatesFrequently;

    [self.lbl_title setTextColor:[[OEXStyles sharedStyles] primaryBaseColor]];
    [self.lbl_time setTextColor:[[OEXStyles sharedStyles] primaryXLightColor]];
    [self.lbl_totalSize setTextColor:[[OEXStyles sharedStyles] primaryXLightColor]];
    [self.progressView setProgressTintColor:[[OEXStyles sharedStyles] successBase]];
    [self tintCancelButton];
    [self setAccessibilityIdentifiers];
}

- (void) setAccessibilityIdentifiers {
    [self.contentView setAccessibilityIdentifier:@"OEXDownloadTableCell:content-view"];
    [self.lbl_title setAccessibilityIdentifier:@"OEXDownloadTableCell:title-label"];
    [self.lbl_time setAccessibilityIdentifier:@"OEXDownloadTableCell:time-label"];
    [self.lbl_totalSize setAccessibilityIdentifier:@"OEXDownloadTableCell:total-size-label"];
    [self.progressView setAccessibilityIdentifier:@"OEXDownloadTableCell:progress-view"];
    [self.btn_cancel setAccessibilityIdentifier:@"OEXDownloadTableCell:cancel-button"];
}

-(void) tintCancelButton {
    UIImage *image = [_btn_cancel.imageView.image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    [_btn_cancel setImage:image forState:UIControlStateNormal];
    _btn_cancel.tintColor = [[OEXStyles sharedStyles] neutralXDark];
}

@end
