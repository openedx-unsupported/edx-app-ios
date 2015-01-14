//
//  FindCourseTableViewCell.h
//  edXVideoLocker
//
//  Created by Rahul Varma on 21/11/14.
//  Copyright (c) 2014 edX. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface FindCourseTableViewCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UIView *parentView;
@property (weak, nonatomic) IBOutlet UIButton *btn_FindACourse;
@property (weak, nonatomic) IBOutlet UILabel *lbl_Challenge;
//@property (weak, nonatomic) IBOutlet UILabel *btn_DontSeeCourse;
@property (weak, nonatomic) IBOutlet UIButton *btn_DontSeeCourse;
@end
