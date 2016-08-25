//
//  UIColor+OEXHex.h
//  edX
//
//  Created by Akiva Leffert on 6/24/15.
//  Copyright (c) 2015-2016 edX. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIColor (OEXHex)

- (id)initWithRGBHex:(uint32_t)value alpha:(CGFloat)alpha;
- (id)initWithHexString:(NSString *)hexString alpha:(CGFloat)alpha;

- (NSString *)hexString;

@end

NS_ASSUME_NONNULL_END