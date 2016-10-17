//
//  OEXFrontTableViewCell.m
//  edXVideoLocker
//
//  Created by Rahul Varma on 09/06/14.
//  Copyright (c) 2014 edX. All rights reserved.
//

#import "OEXFrontTableViewCell.h"

#import "OEXConfig.h"
#import "OEXCourse.h"

@implementation OEXFrontTableViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
    UIView* v = self.contentView.subviews[0];
    v.layer.cornerRadius = 5;
    v.layer.masksToBounds = YES;
}

@end
