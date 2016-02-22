//
//  OEXCourseInfoCell.h
//  edXVideoLocker
//
//  Created by Abhishek Bhagat on 05/07/14.
//  Copyright (c) 2014-2016 edX. All rights reserved.
//

NS_ASSUME_NONNULL_BEGIN

@class OEXCustomLabel;

@interface OEXCourseInfoCell : UITableViewCell

@property (weak, nonatomic, nullable) IBOutlet OEXCustomLabel* lbl_Date;
@property (weak, nonatomic, nullable) IBOutlet UITextView* webview_Data;
@property(nonatomic, strong) IBOutlet NSLayoutConstraint* textViewHeight;

@end

NS_ASSUME_NONNULL_END
