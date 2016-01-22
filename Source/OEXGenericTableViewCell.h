//
//  OEXGenericTableViewCell.h
//  edXVideoLocker
//
//  Created by Rahul Varma on 12/06/14.
//  Copyright (c) 2014-2016 edX. All rights reserved.
//

@class DACircularProgressView;

NS_ASSUME_NONNULL_BEGIN

@interface OEXGenericTableViewCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UIImageView* img_VideoWatchState;
@property (weak, nonatomic) IBOutlet UILabel* lbl_Title;
@property (weak, nonatomic) IBOutlet UILabel* lbl_Time;
@property (weak, nonatomic) IBOutlet UILabel* lbl_Size;
@property (weak, nonatomic) IBOutlet DACircularProgressView* customProgressView;
@property (weak, nonatomic) IBOutlet UIButton* btn_Download;
@end

NS_ASSUME_NONNULL_END
