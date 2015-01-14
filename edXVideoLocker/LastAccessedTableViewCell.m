//
//  LastAccessedTableViewCell.m
//  edXVideoLocker
//
//  Created by Rahul Varma on 11/06/14.
//  Copyright (c) 2014 edX. All rights reserved.
//

#import "LastAccessedTableViewCell.h"

@implementation LastAccessedTableViewCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)awakeFromNib
{
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
