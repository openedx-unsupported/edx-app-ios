//
//  OEXCustomSlider.h
//  edXVideoLocker
//
//  Created by Jotiram Bhagat on 15/07/14.
//  Copyright (c) 2014-2016 edX. All rights reserved.
//

NS_ASSUME_NONNULL_BEGIN

@interface OEXCustomSlider : UISlider
@property(nonatomic) CGFloat secondaryProgress;
@property(nonatomic, strong ) UIImage* secondaryTrackImage;
@property(nonatomic, strong ) UIColor* secondaryTrackColor;
@end

NS_ASSUME_NONNULL_END
