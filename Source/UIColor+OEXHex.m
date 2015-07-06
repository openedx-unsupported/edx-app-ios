//
//  UIColor+OEXHex.m
//  edX
//
//  Created by Akiva Leffert on 6/24/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

#import "UIColor+OEXHex.h"

@implementation UIColor (OEXHex)

- (id)initWithRGBHex:(uint32_t)value alpha:(CGFloat)alpha {
    CGFloat r = ((value >> 16) & 0xFF) / 255.;
    CGFloat g = ((value >> 8) & 0xFF) / 255.;
    CGFloat b = (value & 0xFF) / 255.;
    self = [self initWithRed:r green:g blue:b alpha:alpha];
    return self;
}

@end
