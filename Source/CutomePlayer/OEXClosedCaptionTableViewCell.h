//
//  OEXClosedCaptionTableViewCell.h
//  edXVideoLocker
//
//  Created by Rahul Varma on 18/09/14.
//  Copyright (c) 2014-2016 edX. All rights reserved.
//

NS_ASSUME_NONNULL_BEGIN

@interface OEXClosedCaptionTableViewCell : UITableViewCell

@property (weak, nonatomic, nullable) IBOutlet UILabel* lbl_Title;
@property (weak, nonatomic, nullable) IBOutlet UIView* viewDisable;
@end

NS_ASSUME_NONNULL_END
