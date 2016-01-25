//
//  CLButton.h
//  CLMoviePlayer
//
//  Created by Jotiram Bhagat on 25/06/14.
//  Copyright (c) 2014-2016 Jotiram Bhagat. All rights reserved.
//

@import UIKit;

NS_ASSUME_NONNULL_BEGIN

@protocol CLButtonDelegate <NSObject>

@optional
- (void)buttonTouchedDown:(UIButton*)button;
- (void)buttonTouchedUpOutside:(UIButton*)button;
- (void)buttonTouchCancelled:(UIButton*)button;
@end

@interface CLButton : UIButton
@property(nonatomic, weak, nullable) id <CLButtonDelegate>delegate;
@end

NS_ASSUME_NONNULL_END
