//
//  OEXCourseInfoCell.h
//  edXVideoLocker
//
//  Created by Abhishek Bhagat on 05/07/14.
//  Copyright (c) 2014 edX. All rights reserved.
//

#import <UIKit/UIKit.h>

@class OEXCustomLabel;

@interface OEXCourseInfoCell : UITableViewCell

@property (weak, nonatomic) IBOutlet OEXCustomLabel *lbl_Date;
@property (weak, nonatomic) IBOutlet UITextView *webview_Data;
@property(nonatomic,strong)IBOutlet NSLayoutConstraint *textViewHeight;

@end
