//
//  OEXFindCourseTableViewCell.m
//  edXVideoLocker
//
//  Created by Rahul Varma on 21/11/14.
//  Copyright (c) 2014 edX. All rights reserved.
//

#import "OEXFindCourseTableViewCell.h"

@implementation OEXFindCourseTableViewCell

- (void)awakeFromNib {
    // Initialization code
    self.parentView.layer.cornerRadius = 5;
    self.parentView.layer.masksToBounds = YES;
    [self setAccessibilityLabels];
}

- (void)setAccessibilityLabels {
    self.btn_FindACourse.accessibilityHint = OEXLocalizedString(@"OPENS_MOBILE_FRIENDLY_COURSES", nil);
}
@end
