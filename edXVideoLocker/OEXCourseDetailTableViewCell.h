//
//  OEXCourseDetailTableViewCell.h
//  edXVideoLocker
//
//  Created by Rahul Varma on 11/06/14.
//  Copyright (c) 2014 edX. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DACircularProgressView.h"

@interface OEXCourseDetailTableViewCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UILabel *lbl_Title;
@property (weak, nonatomic) IBOutlet UILabel *lbl_Count;
@property (weak, nonatomic) IBOutlet UIButton *btn_Download;
@property (weak, nonatomic) IBOutlet UIView *view_Disable;
@property (weak, nonatomic) IBOutlet DACircularProgressView *customProgressBar;
@end
