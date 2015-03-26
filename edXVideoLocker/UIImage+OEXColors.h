//
//  UIImage+OEXColors.h
//  edXVideoLocker
//
//  Created by Akiva Leffert on 3/24/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIImage (OEXColors)

/// Returns a a single color image with the given size
+ (UIImage*)oex_imageWithColor:(UIColor*)color size:(CGSize)size;

/// Returns a 1x1 image in the given color
+ (UIImage*)oex_imageWithColor:(UIColor*)color;

@end
