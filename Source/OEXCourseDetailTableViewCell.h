//
//  OEXCourseDetailTableViewCell.h
//  edXVideoLocker
//
//  Created by Rahul Varma on 11/06/14.
//  Copyright (c) 2014-2016 edX. All rights reserved.
//

NS_ASSUME_NONNULL_BEGIN

@class DACircularProgressView;

@interface OEXCourseDetailTableViewCell : UITableViewCell

@property (weak, nonatomic, nullable) IBOutlet UILabel* lbl_Title;
@property (weak, nonatomic, nullable) IBOutlet UILabel* lbl_Count;
@property (weak, nonatomic, nullable) IBOutlet UIButton* btn_Download;
@property (weak, nonatomic, nullable) IBOutlet UIView* view_Disable;
@property (weak, nonatomic, nullable) IBOutlet DACircularProgressView* customProgressBar;
@end

NS_ASSUME_NONNULL_END
