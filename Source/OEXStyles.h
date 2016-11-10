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

+ (CGFloat)dividerSize;

- (UIFont*)sansSerifOfSize:(CGFloat)size;
- (UIFont*)lightSansSerifOfSize:(CGFloat)size;
- (UIFont*)semiBoldSansSerifOfSize:(CGFloat)size;
- (UIFont*)boldSansSerifOfSize:(CGFloat)size;

- (nullable NSString*)styleHTMLContent:(nullable NSString*)htmlString stylesheet:(NSString*)stylesheet;

- (OEXSwitchStyle*)standardSwitchStyle;

#pragma mark Metrics
- (CGFloat)standardHorizontalMargin;
- (CGFloat)boxCornerRadius;

#pragma mark Computed Styles
- (UIColor*) navigationBarColor;
- (UIColor*) navigationItemTintColor;
- (void) applyMockBackButtonStyleToButton : (UIButton*) button;
- (void) applyMockNavigationBarStyleToView:(UIView*)view label:(UILabel*) label leftIconButton:(nullable UIButton*) iconButton;
///Tints the imageView of the mock navigation item (UIButton*) to the specified color
- (void) applyNavigationItemStyleToButton : (UIButton*) button;
#pragma mark Colors

#pragma mark Standard Usage

- (UIColor*)standardBackgroundColor;
- (UIBarStyle)standardNavigationBarStyle;
// This is primarily for legacy code.
// Most code should not use this and instead go by its navigation controller's bar style.
// Or from Swift use UIStatusBarStyle.init(barStyle:)
- (UIStatusBarStyle)standardStatusBarStyle;

#pragma mark Primary

- (UIColor*)primaryXDarkColor;
- (UIColor*)primaryDarkColor;
- (UIColor*)primaryBaseColor;
- (UIColor*)primaryLightColor;
- (UIColor*)primaryXLightColor;

#pragma mark Secondary

- (nonnull UIColor*)secondaryXDarkColor;
- (nonnull UIColor*)secondaryDarkColor;
- (nonnull UIColor*)secondaryBaseColor;
- (nonnull UIColor*)secondaryLightColor;
- (nonnull UIColor*)secondaryXLightColor;

#pragma mark Neutral

- (UIColor*)neutralBlack;
- (UIColor*)neutralBlackT;
- (UIColor*)neutralXDark;
- (UIColor*)neutralDark;
- (UIColor*)neutralBase;
- (UIColor*)neutralLight;
- (UIColor*)neutralXLight;
- (UIColor*)neutralXXLight;
- (UIColor*)neutralWhite;
- (UIColor*)neutralWhiteT;

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
- (UIColor*)banner;
- (UIColor*)disabledButtonColor;

@end

@protocol OEXStylesProvider <NSObject>

@property (readonly, nonatomic) OEXStyles* styles;

@end


NS_ASSUME_NONNULL_END
