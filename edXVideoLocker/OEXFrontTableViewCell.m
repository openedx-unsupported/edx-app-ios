//
//  OEXFrontTableViewCell.m
//  edXVideoLocker
//
//  Created by Rahul Varma on 09/06/14.
//  Copyright (c) 2014 edX. All rights reserved.
//

#import "OEXFrontTableViewCell.h"

@implementation OEXFrontTableViewCell

- (void)prepareForReuse {
    self.course = nil;
}

- (void)awakeFromNib
{
    self.view_Parent.layer.cornerRadius = 5;
    self.view_Parent.layer.masksToBounds = YES;
    
}

@end
