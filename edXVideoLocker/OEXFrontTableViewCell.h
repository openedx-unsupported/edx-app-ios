//
//  OEXFrontTableViewCell.h
//  edXVideoLocker
//
//  Created by Rahul Varma on 09/06/14.
//  Copyright (c) 2014 edX. All rights reserved.
//

#import <UIKit/UIKit.h>

@class OEXCourse;

@interface OEXFrontTableViewCell : UITableViewCell

@property (strong, nonatomic) OEXCourse* course;

@property (weak, nonatomic) IBOutlet UIView *view_Parent;
@property (weak, nonatomic) IBOutlet UIView *view_ChildContent;
@property (weak, nonatomic) IBOutlet UILabel *lbl_Title;

@property (weak, nonatomic) IBOutlet UILabel *lbl_NewCourse;
@property (weak, nonatomic) IBOutlet UIButton *btn_NewCourseContent;
@property (weak, nonatomic) IBOutlet UIImageView *img_NewCourse;
@property (weak, nonatomic) IBOutlet UILabel *lbl_Subtitle;
@property (weak, nonatomic) IBOutlet UIImageView *img_Course;

@property (weak, nonatomic) IBOutlet UILabel *lbl_Starting;
@property (weak, nonatomic) IBOutlet UIImageView *img_Starting;

-(void)setCourseImage;

@end
