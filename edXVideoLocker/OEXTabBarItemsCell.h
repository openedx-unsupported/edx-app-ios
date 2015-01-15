//
//  OEXTabBarItemsCell.h
//  edXVideoLocker
//
//  Created by Nirbhay Agarwal on 16/05/14.
//  Copyright (c) 2014 edX. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface OEXTabBarItemsCell : UICollectionViewCell

@property (weak, nonatomic) IBOutlet UILabel *title;
@property (weak, nonatomic) IBOutlet UIImageView *img_Clicked;
@property (weak, nonatomic) IBOutlet UIImageView *img_BlueBottom;

@end
