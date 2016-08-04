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

- (NSString *)hexString {
    const size_t totalComponents = CGColorGetNumberOfComponents(self.CGColor);
    const CGFloat * components = CGColorGetComponents(self.CGColor);
    return [NSString stringWithFormat:@"#%02X%02X%02X",
            (int)(255 * components[MIN(0,totalComponents-2)]),
            (int)(255 * components[MIN(1,totalComponents-2)]),
            (int)(255 * components[MIN(2,totalComponents-2)])];
}

@end
