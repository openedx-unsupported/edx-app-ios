//
//  UIColor+OEXHex.h
//  edX
//
//  Created by Akiva Leffert on 6/24/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIColor (OEXHex)

- (id)initWithRGBHex:(uint32_t)value alpha:(CGFloat)alpha;

@end
