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

    view.backgroundColor = [self navigationBarColor];
    label.textColor = [self navigationItemTintColor];
    if (iconButton != nil) {
        [self applyNavigationItemStyleToButton:iconButton];
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
    return UIBarStyleBlack;
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
    return [[OEXColors sharedInstance] colorForIdentifier:@"primaryXDarkColor"];
}

- (UIColor*)primaryDarkColor {
    return [[OEXColors sharedInstance] colorForIdentifier:@"primaryDarkColor"];
}

- (UIColor*)primaryBaseColor {
    return [[OEXColors sharedInstance] colorForIdentifier:@"primaryBaseColor"];
}

- (UIColor*)primaryLightColor {
    return [[OEXColors sharedInstance] colorForIdentifier:@"primaryLightColor"];
}

- (UIColor*)primaryXLightColor {
    // Note. This is not the color value from the mobile style guide.
    // iOS seems to have a darker color space than the desktop so this is
    // deliberately lightened from that.
    return [[OEXColors sharedInstance] colorForIdentifier:@"primaryXLightColor"];
}

#pragma mark Secondary

- (UIColor*)secondaryXDarkColor {
    return [[OEXColors sharedInstance] colorForIdentifier:@"secondaryXDarkColor"];
}

- (nonnull UIColor*)secondaryDarkColor {
    return [[OEXColors sharedInstance] colorForIdentifier:@"secondaryDarkColor"];
}

- (nonnull UIColor*)secondaryBaseColor {
    return [[OEXColors sharedInstance] colorForIdentifier:@"secondaryBaseColor"];
}

- (nonnull UIColor*)secondaryLightColor {
    return [[OEXColors sharedInstance] colorForIdentifier:@"secondaryLightColor"];
}

- (nonnull UIColor*)secondaryXLightColor {
    return [[OEXColors sharedInstance] colorForIdentifier:@"secondaryXLightColor"];
}

#pragma mark Neutral

- (UIColor*)neutralBlack {
    return [[OEXColors sharedInstance] colorForIdentifier:@"neutralBlack"];
}

- (UIColor*)neutralBlackT {
    return [[OEXColors sharedInstance] colorForIdentifier:@"neutralBlackT"];
}

- (UIColor*)neutralXDark {
    return [[OEXColors sharedInstance] colorForIdentifier:@"neutralXDark"];
}

- (UIColor*)neutralDark {
    return [[OEXColors sharedInstance] colorForIdentifier:@"neutralDark"];
}

- (UIColor*)neutralBase {
    return [[OEXColors sharedInstance] colorForIdentifier:@"neutralBase"];
}

- (UIColor*)neutralLight {
    return [[OEXColors sharedInstance] colorForIdentifier:@"neutralLight"];
}

- (UIColor*)neutralXLight {
    return [[OEXColors sharedInstance] colorForIdentifier:@"neutralXLight"];
}

- (UIColor*)neutralXXLight {
    return [[OEXColors sharedInstance] colorForIdentifier:@"neutralXXLight"];
}

- (UIColor*)neutralWhite {
    return [[OEXColors sharedInstance] colorForIdentifier:@"neutralWhite"];
}

- (UIColor*)neutralWhiteT {
    return [[OEXColors sharedInstance] colorForIdentifier:@"neutralWhiteT"];
}


#pragma mark Utility

- (UIColor*)utilitySuccessDark {
    return [[OEXColors sharedInstance] colorForIdentifier:@"utilitySuccessDark"];
}

- (UIColor*)utilitySuccessBase {
    return [[OEXColors sharedInstance] colorForIdentifier:@"utilitySuccessBase"];
}

- (UIColor*)utilitySuccessLight {
    return [[OEXColors sharedInstance] colorForIdentifier:@"utilitySuccessLight"];
}

- (UIColor*)warningDark {
    return [[OEXColors sharedInstance] colorForIdentifier:@"warningDark"];
}

- (UIColor*)warningBase {
    return [[OEXColors sharedInstance] colorForIdentifier:@"warningBase"];
}

- (UIColor*)warningLight {
    return [[OEXColors sharedInstance] colorForIdentifier:@"warningLight"];
}

- (UIColor*)errorDark {
    return [[OEXColors sharedInstance] colorForIdentifier:@"errorDark"];
}

- (UIColor*)errorBase {
    return [[OEXColors sharedInstance] colorForIdentifier:@"errorBase"];
}

- (UIColor*)errorLight {
    return [[OEXColors sharedInstance] colorForIdentifier:@"errorLight"];
}

- (UIColor*)banner {
    return [[OEXColors sharedInstance] colorForIdentifier:@"banner"];
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

- (NSString*)styleHTMLContent:(NSString*)htmlString stylesheet:(NSString*)stylesheet {
    NSString* path = [[NSBundle mainBundle] pathForResource:stylesheet ofType:@"css"];
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
