//
//  OEXFindCourseTableViewCell.h
//  edXVideoLocker
//
//  Created by Rahul Varma on 21/11/14.
//  Copyright (c) 2014-2016 edX. All rights reserved.
//

NS_ASSUME_NONNULL_BEGIN

@interface OEXFindCourseTableViewCell : UITableViewCell

@property (weak, nonatomic, nullable) IBOutlet UIView* parentView;
@property (weak, nonatomic, nullable) IBOutlet UIButton* btn_FindACourse;
@property (weak, nonatomic, nullable) IBOutlet UILabel* lbl_Challenge;
//@property (weak, nonatomic, nullable) IBOutlet UILabel *btn_DontSeeCourse;
@property (weak, nonatomic, nullable) IBOutlet UIButton* btn_DontSeeCourse;
@end

NS_ASSUME_NONNULL_END
