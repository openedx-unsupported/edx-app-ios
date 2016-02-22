//
//  OEXDownloadTableCell.h
//  edXVideoLocker
//
//  Created by Jotiram Bhagat on 30/06/14.
//  Copyright (c) 2014-2016 edX. All rights reserved.
//

NS_ASSUME_NONNULL_BEGIN

@interface OEXDownloadTableCell : UITableViewCell
@property(weak, nonatomic, nullable) IBOutlet UILabel* lbl_title;
@property(weak, nonatomic, nullable) IBOutlet UIProgressView* progressView;
@property(weak, nonatomic, nullable) IBOutlet UILabel* lbl_time;
@property(weak, nonatomic, nullable) IBOutlet UILabel* lbl_totalSize;
@property(weak, nonatomic, nullable) IBOutlet UIButton* btn_cancel;
@end

NS_ASSUME_NONNULL_END