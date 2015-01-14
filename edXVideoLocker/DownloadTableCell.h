//
//  DownloadTableCell.h
//  edXVideoLocker
//
//  Created by Jotiram Bhagat on 30/06/14.
//  Copyright (c) 2014 edX. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface DownloadTableCell : UITableViewCell
@property(weak,nonatomic)IBOutlet UILabel *lbl_title;
@property(weak,nonatomic)IBOutlet UIProgressView *progressView;
@property(weak,nonatomic)IBOutlet UILabel *lbl_time;
@property(weak,nonatomic)IBOutlet UILabel *lbl_totalSize;
@property(weak,nonatomic)IBOutlet UIButton *btn_cancel;
@end
