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
    [self tintCancelButton];
    [self resetLabels];
}


- (void)prepareForReuse {
    [super prepareForReuse];
    [self resetLabels];
}

- (void)resetLabels {
    self.lbl_title.text = @"";
    self.lbl_time.text = @"";
    self.lbl_totalSize.text = @"";
}

- (void)tintCancelButton {
    UIImage *image = [_btn_cancel.imageView.image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    [_btn_cancel setImage:image forState:UIControlStateNormal];
    _btn_cancel.tintColor = [[OEXStyles sharedStyles] neutralBase];
}

@end
