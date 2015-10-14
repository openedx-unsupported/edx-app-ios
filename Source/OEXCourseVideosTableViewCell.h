//
//  OEXCourseVideosTableViewCell.h
//  edXVideoLocker
//
//  Created by Rahul Varma on 28/05/14.
//  Copyright (c) 2014-2015 edX. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DACircularProgressView.h"

@class OEXCheckBox;

@interface OEXCourseVideosTableViewCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UIImageView* img_VideoWatchState;
@property (weak, nonatomic) IBOutlet UILabel* lbl_Title;
@property (weak, nonatomic) IBOutlet UILabel* lbl_Time;
@property (weak, nonatomic) IBOutlet UILabel* lbl_Size;
@property (weak, nonatomic) IBOutlet DACircularProgressView* customProgressView;
@property (weak, nonatomic) IBOutlet UIButton* btn_Download;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *courseVideoStateLeadingConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *subSectionCourseVideoStateLeadingConstraint;

// Used only while editing the table view
@property (weak, nonatomic) IBOutlet OEXCheckBox* btn_CheckboxDelete;
@property (weak, nonatomic) IBOutlet UIView* view_DisableOffline;

@end
