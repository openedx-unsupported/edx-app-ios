//
//  UIImage+OEXColors.h
//  edXVideoLocker
//
//  Created by Akiva Leffert on 3/24/15.
//  Copyright (c) 2015-2016 edX. All rights reserved.
//

NS_ASSUME_NONNULL_BEGIN

@interface UIImage (OEXColors)

/// Returns a a single color image with the given size
+ (UIImage*)oex_imageWithColor:(UIColor*)color size:(CGSize)size;

/// Returns a 1x1 image in the given color
+ (UIImage*)oex_imageWithColor:(UIColor*)color;

@end

NS_ASSUME_NONNULL_END
