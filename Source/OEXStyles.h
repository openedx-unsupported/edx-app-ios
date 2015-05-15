//
//  OEXStyles.h
//  edXVideoLocker
//
//  Created by Akiva Leffert on 12/3/14.
//  Copyright (c) 2014 edX. All rights reserved.
//

#import <Foundation/Foundation.h>

@class OEXSwitchStyle;

@interface OEXStyles : NSObject

/// Note that these are not thread safe. The expectation is that these operations are done
/// immediately when the app launches or synchronously at the start of a test.
+ (nullable instancetype)sharedStyles;
+ (void)setSharedStyles:(nullable OEXStyles*)styles;

- (nonnull UIFont*)sansSerifOfSize:(CGFloat)size;
- (nonnull UIFont*)boldSansSerifOfSize:(CGFloat)size;

- (nullable NSString*)styleHTMLContent:(nullable NSString*)htmlString;

- (nonnull OEXSwitchStyle*)standardSwitchStyle;

#pragma mark Colors

#pragma mark Primary

- (nonnull UIColor*)primaryBaseColor;
- (nonnull UIColor*)primaryLightColor;

#pragma mark Neutral

- (nonnull UIColor*)neutralBlack;
- (nonnull UIColor*)neutralBlackT;
- (nonnull UIColor*)neutralXDark;
- (nonnull UIColor*)neutralDark;
- (nonnull UIColor*)neutralBase;
- (nonnull UIColor*)neutralLight;
- (nonnull UIColor*)neutralXLight;
- (nonnull UIColor*)neutralWhite;
- (nonnull UIColor*)neutralWhiteT;
- (nonnull UIColor*)neutralTranslucent;
- (nonnull UIColor*)neutralXTranslucent;
- (nonnull UIColor*)neutralXXTranslucent;

@end
