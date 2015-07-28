//
//  OEXCourseVideosTableViewCell.m
//  edXVideoLocker
//
//  Created by Rahul Varma on 28/05/14.
//  Copyright (c) 2014 edX. All rights reserved.
//

#import "OEXCourseVideosTableViewCell.h"

@implementation OEXCourseVideosTableViewCell

// MOB - 588
- (void)setHighlighted:(BOOL)highlighted animated:(BOOL)animated {
    if(highlighted) {
        self.backgroundColor = GREY_COLOR;
    }
    else {
        self.backgroundColor = [UIColor whiteColor];
    }
}

- (void)awakeFromNib {
    [self.lbl_Title setTextAlignment:NSTextAlignmentNatural];
    [self.lbl_Time setTextAlignment:NSTextAlignmentNatural];
    [self.lbl_Size setTextAlignment:NSTextAlignmentNatural];
    self.btn_CheckboxDelete.accessibilityLabel = OEXLocalizedString(@"ACCESSIBILITY_SELECT", nil);
}

- (NSString *)accessibilityLabel {
    return self.lbl_Title.text;
}

@end
