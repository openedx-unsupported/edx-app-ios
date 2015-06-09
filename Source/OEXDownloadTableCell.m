//
//  OEXDownloadTableCell.m
//  edXVideoLocker
//
//  Created by Jotiram Bhagat on 30/06/14.
//  Copyright (c) 2014 edX. All rights reserved.
//

#import "OEXDownloadTableCell.h"

@implementation OEXDownloadTableCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString*)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if(self) {
        // Initialization code
    }
    return self;
}

- (void)awakeFromNib {
    [self.lbl_title setTextAlignment:NSTextAlignmentNatural];
    [self.lbl_time setTextAlignment:NSTextAlignmentNatural];
    [self.lbl_totalSize setTextAlignment:NSTextAlignmentNatural];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
