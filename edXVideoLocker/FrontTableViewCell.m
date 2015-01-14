//
//  FrontTableViewCell.m
//  edXVideoLocker
//
//  Created by Rahul Varma on 09/06/14.
//  Copyright (c) 2014 edX. All rights reserved.
//

#import "FrontTableViewCell.h"

@implementation FrontTableViewCell

- (void)awakeFromNib
{
    self.view_Parent.layer.cornerRadius = 5;
    self.view_Parent.layer.masksToBounds = YES;
    
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
