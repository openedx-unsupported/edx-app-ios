//
//  OEXDownloadTableCell.m
//  edXVideoLocker
//
//  Created by Jotiram Bhagat on 30/06/14.
//  Copyright (c) 2014-2015 edX. All rights reserved.
//

#import "OEXDownloadTableCell.h"

@implementation OEXDownloadTableCell

- (void)awakeFromNib {
    [self.lbl_title setTextAlignment:NSTextAlignmentNatural];
    [self.lbl_time setTextAlignment:NSTextAlignmentNatural];
    [self.lbl_totalSize setTextAlignment:NSTextAlignmentNatural];
    
    self.accessibilityTraits = UIAccessibilityTraitUpdatesFrequently;
}

@end
