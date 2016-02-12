//
//  OEXTabBarItemsCell.h
//  edXVideoLocker
//
//  Created by Nirbhay Agarwal on 16/05/14.
//  Copyright (c) 2014-2016 edX. All rights reserved.
//

NS_ASSUME_NONNULL_BEGIN

@interface OEXTabBarItemsCell : UICollectionViewCell

@property (weak, nonatomic, nullable) IBOutlet UILabel* title;
@property (weak, nonatomic, nullable) IBOutlet UIImageView* img_Clicked;
@property (weak, nonatomic, nullable) IBOutlet UIImageView* img_BlueBottom;

@end

NS_ASSUME_NONNULL_END
