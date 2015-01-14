//
//  CourseInfoCell.h
//  edXVideoLocker
//
//  Created by Abhishek Bhagat on 05/07/14.
//  Copyright (c) 2014 edX. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CustomLabel.h"
@interface CourseInfoCell : UITableViewCell
@property (weak, nonatomic) IBOutlet CustomLabel *lbl_Date;
@property (weak, nonatomic) IBOutlet UITextView *webview_Data;
@property(nonatomic,strong)IBOutlet NSLayoutConstraint *textViewHeight;
@end
