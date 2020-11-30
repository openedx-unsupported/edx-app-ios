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

- (UIFont*)regularFontOfSize:(CGFloat)size;
- (UIFont*)lightFontOfSize:(CGFloat)size;
- (UIFont*)semiBoldFontOfSize:(CGFloat)size;
- (UIFont*)boldFontOfSize:(CGFloat)size;

- (UIFont*)regularFontOfSize:(CGFloat)size dynamicTypeSupported:(BOOL) dynamicTypeSupported;
- (UIFont*)lightFontOfSize:(CGFloat)size dynamicTypeSupported:(BOOL) dynamicTypeSupported;
- (UIFont*)semiBoldFontOfSize:(CGFloat)size dynamicTypeSupported:(BOOL) dynamicTypeSupported;
- (UIFont*)boldFontOfSize:(CGFloat)size dynamicTypeSupported:(BOOL) dynamicTypeSupported;
- (UIFont*)boldItalicFontOfSize:(CGFloat)size dynamicTypeSupported:(BOOL) dynamicTypeSupported;

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

#pragma mark Standard Usage

- (UIColor*)standardBackgroundColor;
- (UIBarStyle)standardNavigationBarStyle;
// This is primarily for legacy code.
// Most code should not use this and instead go by its navigation controller's bar style.
// Or from Swift use UIStatusBarStyle.init(barStyle:)
- (UIStatusBarStyle)standardStatusBarStyle;

#pragma mark - Core Colors
#pragma mark Primary

- (UIColor*)primaryXXLightColor;
- (UIColor*)primaryXLightColor;
- (UIColor*)primaryLightColor;
- (UIColor*)primaryBaseColor;
- (UIColor*)primaryDarkColor;

#pragma mark Secondary Action

- (UIColor*)secondaryBaseColor;
- (UIColor*)secondaryDarkColor;

#pragma mark Accent

- (UIColor*)accentAColor;
- (UIColor*)accentBColor;

#pragma mark Neutral Dark

- (UIColor*)neutralBlackT;
- (UIColor*)neutralBlack;
- (UIColor*)neutralXXDark;
- (UIColor*)neutralXDark;
- (UIColor*)neutralDark;
- (UIColor*)neutralBase;

#pragma mark Neutral Light

- (UIColor*)neutralWhiteT;
- (UIColor*)neutralWhite;
- (UIColor*)neutralXLight;
- (UIColor*)neutralLight;

#pragma mark - Utility Colors

#pragma mark Success Color

- (UIColor*)successXXLight;
- (UIColor*)successXLight;
- (UIColor*)successLight;
- (UIColor*)successBase;
- (UIColor*)successDark;
- (UIColor*)successXDark;

#pragma mark Warning Color

- (UIColor*)warningXXLight;
- (UIColor*)warningXLight;
- (UIColor*)warningLight;
- (UIColor*)warningBase;
- (UIColor*)warningDark;
- (UIColor*)warningXDark;

#pragma mark Error Color

- (UIColor*)errorXXLight;
- (UIColor*)errorXLight;
- (UIColor*)errorLight;
- (UIColor*)errorBase;
- (UIColor*)errorDark;
- (UIColor*)errorXDark;

#pragma mark Info Color

- (UIColor*)infoXXLight;
- (UIColor*)infoXLight;
- (UIColor*)infoLight;
- (UIColor*)infoBase;
- (UIColor*)infoDark;
- (UIColor*)infoXDark;

#pragma mark Supportive Colors

- (UIColor*)disabledButtonColor;

@end

@protocol OEXStylesProvider <NSObject>

@property (readonly, nonatomic) OEXStyles* styles;

@end


NS_ASSUME_NONNULL_END
