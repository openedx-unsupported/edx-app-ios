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

#pragma mark Computed Styles
- (UIColor*) navigationBarColor;
- (UIColor*) navigationItemTintColor;
- (void) applyMockNavigationBarStyleToView:(UIView*)view label:(UILabel*) label leftIconButton:(nullable UIButton*) iconButton;
#pragma mark Colors

#pragma mark Standard Usage

- (UIColor*)standardBackgroundColor;

#pragma mark Primary

- (UIColor*)primaryXDarkColor;
- (UIColor*)primaryDarkColor;
- (UIColor*)primaryBaseColor;
- (UIColor*)primaryLightColor;
- (UIColor*)primaryXLightColor;
- (UIColor*)primaryAccentColor;
- (UIColor*)primaryXAccentColor;

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

#pragma mark Cool

- (UIColor*)coolXDark;
- (UIColor*)coolDark;
- (UIColor*)coolBase;
- (UIColor*)coolLight;
- (UIColor*)coolXLight;
- (UIColor*)coolTrans;
- (UIColor*)coolXTrans;
- (UIColor*)coolXXTrans;

#pragma mark Utility

- (UIColor*)utilitySuccessDark;
- (UIColor*)utilitySuccessBase;
- (UIColor*)utilitySuccessLight;
- (UIColor*)warningDark;
- (UIColor*)warningBase;
- (UIColor*)warningLight;
- (UIColor*)errorDark;
- (UIColor*)errorBase;
- (UIColor*)errorLight;

@end


NS_ASSUME_NONNULL_END