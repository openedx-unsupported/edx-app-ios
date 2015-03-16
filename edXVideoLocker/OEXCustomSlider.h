//
//  OEXCustomSlider.h
//  edXVideoLocker
//
//  Created by Jotiram Bhagat on 15/07/14.
//  Copyright (c) 2014 edX. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface OEXCustomSlider : UISlider
@property(nonatomic) CGFloat secondaryProgress;
@property(nonatomic, strong ) UIImage* secondaryTrackImage;
@property(nonatomic, strong ) UIColor* secondaryTrackColor;
@end
