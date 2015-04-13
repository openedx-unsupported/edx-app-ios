//
//  UIImage+OEXColors.m
//  edXVideoLocker
//
//  Created by Akiva Leffert on 3/24/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

#import "UIImage+OEXColors.h"

@implementation UIImage (OEXColors)

+ (UIImage*)oex_imageWithColor:(UIColor*)color size:(CGSize)size {
    UIGraphicsBeginImageContextWithOptions(size, NO, 1);
    
    [color setFill];
    UIRectFill(CGRectMake(0, 0, 1, 1));
    
    UIImage* result = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return result;
}

+ (UIImage*)oex_imageWithColor:(UIColor*)color {
    return [self oex_imageWithColor:color size:CGSizeMake(1, 1)];
}

@end
