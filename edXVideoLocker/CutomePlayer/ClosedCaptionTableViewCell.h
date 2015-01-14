//
//  ClosedCaptionTableViewCell.h
//  edXVideoLocker
//
//  Created by Rahul Varma on 18/09/14.
//  Copyright (c) 2014 edX. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ClosedCaptionTableViewCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UILabel *lbl_Title;
@property (weak, nonatomic) IBOutlet UIView *viewDisable;
@end
