//
//  CourseVideosTableViewCell.m
//  edXVideoLocker
//
//  Created by Rahul Varma on 28/05/14.
//  Copyright (c) 2014 edX. All rights reserved.
//

#import "CourseVideosTableViewCell.h"
#import "edXConstants.h"

@implementation CourseVideosTableViewCell

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


// MOB - 588
- (void)setHighlighted:(BOOL)highlighted animated:(BOOL)animated
{
    if (highlighted) {
        self.backgroundColor = GREY_COLOR;
    } else {
        self.backgroundColor = [UIColor whiteColor];
    }
}

@end
