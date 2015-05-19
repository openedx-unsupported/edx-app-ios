//
//  OEXStyles.h
//  edXVideoLocker
//
//  Created by Akiva Leffert on 12/3/14.
//  Copyright (c) 2014 edX. All rights reserved.
//

#import <Foundation/Foundation.h>

@class OEXSwitchStyle;

NS_ASSUME_NONNULL_BEGIN

@interface OEXStyles : NSObject

/// Note that these are not thread safe. The expectation is that these operations are done
/// immediately when the app launches or synchronously at the start of a test.
+ (instancetype)sharedStyles;
+ (void)setSharedStyles:(nullable OEXStyles*)styles;

- (UIFont*)sansSerifOfSize:(CGFloat)size;
- (UIFont*)boldSansSerifOfSize:(CGFloat)size;

- (nullable NSString*)styleHTMLContent:(nullable NSString*)htmlString;

- (OEXSwitchStyle*)standardSwitchStyle;

#pragma mark Metrics

- (CGFloat)dividerHeight;
- (CGFloat)standardHorizontalMargin;

#pragma mark Colors

- (UIColor*)standardBackgroundColor;

#pragma mark Primary

- (UIColor*)primaryBaseColor;
- (UIColor*)primaryLightColor;

#pragma mark Secondary

- (nonnull UIColor*)secondaryXDarkColor;
- (nonnull UIColor*)secondaryDarkColor;
- (nonnull UIColor*)secondaryBaseColor;
- (nonnull UIColor*)secondaryLightColor;
- (nonnull UIColor*)secondaryXLightColor;
- (nonnull UIColor*)secondaryAccentColor;

#pragma mark Neutral

- (UIColor*)neutralBlack;
- (UIColor*)neutralBlackT;
- (UIColor*)neutralXDark;
- (UIColor*)neutralDark;
- (UIColor*)neutralBase;
- (UIColor*)neutralLight;
- (UIColor*)neutralXLight;
- (UIColor*)neutralWhite;
- (UIColor*)neutralWhiteT;
- (UIColor*)neutralTranslucent;
- (UIColor*)neutralXTranslucent;
- (UIColor*)neutralXXTranslucent;

@end


NS_ASSUME_NONNULL_END