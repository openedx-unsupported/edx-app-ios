//
//  OEXStyles.m
//  edXVideoLocker
//
//  Created by Akiva Leffert on 12/3/14.
//  Copyright (c) 2014 edX. All rights reserved.
//

#import "OEXStyles.h"

#import "OEXSwitchStyle.h"
#import "UIColor+OEXHex.h"
#import "edX-Swift.h"

static OEXStyles* sSharedStyles;

@implementation OEXStyles

+ (instancetype)sharedStyles {
    return sSharedStyles;
}

+ (void)setSharedStyles:(OEXStyles*)styles {
    sSharedStyles = styles;
}

#pragma mark Metrics

+ (CGFloat)dividerSize {
    return 1 / [UIScreen mainScreen].scale;
}

- (CGFloat)standardHorizontalMargin {
    return 15;
}

- (CGFloat)boxCornerRadius {
    return 5;
}

#pragma mark Computed Style

- (UIColor*)navigationBarColor {
    return [self primaryBaseColor];
}

- (UIColor*)navigationItemTintColor {
    return [self standardBackgroundColor];
}

- (void) applyMockBackButtonStyleToButton : (UIButton*) button {
    [button setImage:[UIImage imageNamed:@"ic_back"] forState:UIControlStateNormal];
    [button setFrame:CGRectMake(8, 31, 22, 22)];
}

- (void) applyMockNavigationBarStyleToView:(UIView*)view label:(UILabel*) label leftIconButton:(nullable UIButton*) iconButton {
    
    if ([[OEXConfig sharedConfig]shouldEnableNewCourseNavigation]) {
        view.backgroundColor = [self navigationBarColor];
        label.textColor = [self navigationItemTintColor];
        if (iconButton != nil) {
            [self applyNavigationItemStyleToButton:iconButton];
        }
    }
    
}

- (void) applyNavigationItemStyleToButton : (UIButton*) button {
    [button setImage:[[button imageForState:UIControlStateNormal] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
    [button setTintColor:[self navigationItemTintColor]];
}

#pragma mark Colors
// Based off http://ux.edx.org/#colors with simplification for mobile

#pragma mark Standard Usages

- (UIColor*)standardBackgroundColor {
    return [self neutralWhite];
}

- (UIBarStyle)standardNavigationBarStyle {
    if([[OEXConfig sharedConfig] shouldEnableNewCourseNavigation]) {
        return UIBarStyleBlack;
    }
    else {
        return UIBarStyleDefault;
    }
}

- (UIStatusBarStyle)standardStatusBarStyle {
    switch(self.standardNavigationBarStyle) {
        case UIBarStyleBlack:
        case UIBarStyleBlackTranslucent:
            return UIStatusBarStyleLightContent;
        case UIBarStyleDefault:
            return UIStatusBarStyleDefault;
    }
}

#pragma mark Primary

- (UIColor*)primaryXDarkColor {
    return [[UIColor alloc] initWithRGBHex:0x003654 alpha:1];
}

- (UIColor*)primaryDarkColor {
    return [[UIColor alloc] initWithRGBHex:0x005483 alpha:1];
}

- (UIColor*)primaryBaseColor {
    return [[UIColor alloc] initWithRGBHex:0x0079BC alpha:1];
}

- (UIColor*)primaryLightColor {
    return [[UIColor alloc] initWithRGBHex:0x4CA1D0 alpha:1];
}

- (UIColor*)primaryXLightColor {
    return [[UIColor alloc] initWithRGBHex:0xB2D6EA alpha:1];
}

#pragma mark Secondary

- (UIColor*)secondaryXDarkColor {
    return [[UIColor alloc] initWithRGBHex:0x5B283F alpha:1];
}

- (nonnull UIColor*)secondaryDarkColor {
    return [[UIColor alloc] initWithRGBHex:0x8E3E62 alpha:1];
}

- (nonnull UIColor*)secondaryBaseColor {
    return [[UIColor alloc] initWithRGBHex:0xCB598D alpha:1];
}

- (nonnull UIColor*)secondaryLightColor {
    return [[UIColor alloc] initWithRGBHex:0xDA8AAF alpha:1];
}

- (nonnull UIColor*)secondaryXLightColor {
    return [[UIColor alloc] initWithRGBHex:0xEFCDDC alpha:1];
}

#pragma mark Neutral

- (UIColor*)neutralBlack {
    return [[UIColor alloc] initWithRGBHex:0x101010 alpha:1];
}

- (UIColor*)neutralBlackT {
    return [[UIColor alloc] initWithRGBHex:0x000000 alpha:1];
}

- (UIColor*)neutralXDark {
    return [[UIColor alloc] initWithRGBHex:0x424141 alpha:1];
}

- (UIColor*)neutralDark {
    return [[UIColor alloc] initWithRGBHex:0x646262 alpha:1];
}

- (UIColor*)neutralBase {
    return [[UIColor alloc] initWithRGBHex:0xA7A4A4 alpha:1];
}

- (UIColor*)neutralLight {
    return [[UIColor alloc] initWithRGBHex:0xD3D1D1 alpha:1];
}

- (UIColor*)neutralXLight {
    return [[UIColor alloc] initWithRGBHex:0xE9E8E8 alpha:1];
}

- (UIColor*)neutralXXLight {
    return [[UIColor alloc] initWithRGBHex:0xF2F2F2 alpha:1];
}

- (UIColor*)neutralWhite {
    return [[UIColor alloc] initWithRGBHex:0xFCFCFC alpha:1];
}

- (UIColor*)neutralWhiteT {
    return [[UIColor alloc] initWithRGBHex:0xFFFFFF alpha:1];
}


#pragma mark Utility

- (UIColor*)utilitySuccessDark {
    return [UIColor colorWithRed:24/255. green:12/255. blue:60/255. alpha:1.0];
}

- (UIColor*)utilitySuccessBase {
    return [UIColor colorWithRed:37/255. green:184/255. blue:90/255. alpha:1.0];
}

- (UIColor*)utilitySuccessLight {
    return [UIColor colorWithRed:108/255. green:207/255. blue:144/255. alpha:1.0];
}

- (UIColor*)warningDark {
    return [UIColor colorWithRed:169/255. green:125/255. blue:57/255. alpha:1.0];
}

- (UIColor*)warningBase {
    return [UIColor colorWithRed:253/255. green:188/255. blue:86/255. alpha:1.0];
}

- (UIColor*)warningLight {
    return [UIColor colorWithRed:253/255. green:210/255. blue:141/255. alpha:1.0];
}

- (UIColor*)errorDark {
    return [UIColor colorWithRed:119/255. green:4/255. blue:10/255. alpha:1.0];
}

- (UIColor*)errorBase {
    return [UIColor colorWithRed:178/255. green:6/255. blue:16/255. alpha:1.0];
}

- (UIColor*)errorLight {
    return [UIColor colorWithRed:203/255. green:88/255. blue:94/255. alpha:1.0];
}

- (UIColor*)banner {
    return [UIColor colorWithRed:125/255. green:200/255. blue:143/255. alpha:1.0];
}

- (UIColor * __nonnull) disabledButtonColor
{
    return [UIColor grayColor];
}


#pragma mark Fonts

- (UIFont*)sansSerifOfSize:(CGFloat)size {
    return [UIFont fontWithName:@"OpenSans" size:size];
}

- (UIFont*)semiBoldSansSerifOfSize:(CGFloat)size {
    return [UIFont fontWithName:@"OpenSans-Semibold" size:size];
}

- (UIFont*)boldSansSerifOfSize:(CGFloat)size {
    return [UIFont fontWithName:@"OpenSans-Bold" size:size];
}

- (UIFont*)lightSansSerifOfSize:(CGFloat)size {
    return [UIFont fontWithName:@"OpenSans-Light" size:size];
}

- (NSString*)styleHTMLContent:(NSString*)htmlString {
    NSString* path = [[NSBundle mainBundle] pathForResource:@"handouts-announcements" ofType:@"css"];
    NSError* error = nil;
    NSMutableString* css = [NSMutableString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:&error];
    NSAssert(!error, @"Error loading style: %@", error.localizedDescription);

    NSMutableString* styledHTML = htmlString.mutableCopy;
    [styledHTML appendString:@"</html>"];
    [styledHTML appendString:@"</body>"];
    [styledHTML insertString:@"</style>" atIndex:0];
    [styledHTML insertString:css atIndex:0];
    [styledHTML insertString:@"<style>" atIndex:0];

    [styledHTML insertString:@"<body>" atIndex:0];
    [styledHTML insertString:@"</head>" atIndex:0];
    [styledHTML insertString:@"<meta name = \"viewport\" content = \"width=device-width, initial-scale=1\"/>" atIndex:0];
    [styledHTML insertString:@"<head>" atIndex:0];
    [styledHTML insertString:@"<html>" atIndex:0];
    return styledHTML;
}

- (OEXSwitchStyle*)standardSwitchStyle {
    return [[OEXSwitchStyle alloc] initWithTintColor:nil onTintColor:[self primaryLightColor] thumbTintColor:nil];
}

@end
