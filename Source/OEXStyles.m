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

- (OEXColors *)oexColors {
    return [OEXColors sharedInstance];
}
    
- (OEXFonts *)oexFonts {
    return [OEXFonts sharedInstance];
}

#pragma mark Computed Style

- (UIColor*)navigationBarColor {
    return [self neutralWhite];
}

- (UIColor*)navigationItemTintColor {
    return [self primaryBaseColor];
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

- (UIColor*)primaryXXLightColor {
    return [self.oexColors colorForIdentifier:ColorsIdentifiersPrimaryXXLightColor];
}
- (UIColor*)primaryXLightColor {
    return [self.oexColors colorForIdentifier:ColorsIdentifiersPrimaryXLightColor];
}
- (UIColor*)primaryLightColor {
    return [self.oexColors colorForIdentifier:ColorsIdentifiersPrimaryLightColor];
}

- (UIColor*)primaryBaseColor {
    return [self.oexColors colorForIdentifier:ColorsIdentifiersPrimaryBaseColor];
}

- (UIColor*)primaryDarkColor {
    return [self.oexColors colorForIdentifier:ColorsIdentifiersPrimaryDarkColor];
}

#pragma mark Arand Action

- (UIColor*)secondaryBaseColor {
    return [self.oexColors colorForIdentifier:ColorsIdentifiersSecondaryBaseColor];
}

- (UIColor*)secondaryDarkColor {
    return [self.oexColors colorForIdentifier:ColorsIdentifiersSecondaryDarkColor];
}

#pragma mark Accent Colors

- (UIColor*)accentAColor {
    return [self.oexColors colorForIdentifier:ColorsIdentifiersAccentAColor];
}

- (UIColor*)accentBColor {
    return [self.oexColors colorForIdentifier:ColorsIdentifiersAccentBColor];
}

#pragma mark Neutral Dark

- (UIColor*)neutralBlackT {
    return [self.oexColors colorForIdentifier:ColorsIdentifiersNeutralBlackT];
}

- (UIColor*)neutralBlack {
    return [self.oexColors colorForIdentifier:ColorsIdentifiersNeutralBlack];
}

- (UIColor*)neutralXXDark {
    return [self.oexColors colorForIdentifier:ColorsIdentifiersNeutralXXDark];
}

- (UIColor*)neutralXDark {
    return [self.oexColors colorForIdentifier:ColorsIdentifiersNeutralXDark];
}

- (UIColor*)neutralDark {
    return [self.oexColors colorForIdentifier:ColorsIdentifiersNeutralDark];
}

- (UIColor*)neutralBase {
    return [self.oexColors colorForIdentifier:ColorsIdentifiersNeutralBase];
}

#pragma mark Neutral Light

- (UIColor*)neutralWhiteT {
    return [self.oexColors colorForIdentifier:ColorsIdentifiersNeutralWhiteT];
}

- (UIColor*)neutralWhite {
    return [self.oexColors colorForIdentifier:ColorsIdentifiersNeutralWhite];
}

- (UIColor*)neutralXLight {
    return [self.oexColors colorForIdentifier:ColorsIdentifiersNeutralXLight];
}

- (UIColor*)neutralLight {
    return [self.oexColors colorForIdentifier:ColorsIdentifiersNeutralLight];
}

#pragma mark - Utility Colors
#pragma mark Success Color

- (UIColor*)successXXLight {
    return [self.oexColors colorForIdentifier:ColorsIdentifiersSuccessXXLight];
}

- (UIColor*)successXLight {
    return [self.oexColors colorForIdentifier:ColorsIdentifiersSuccessXLight];
}

- (UIColor*)successLight {
    return [self.oexColors colorForIdentifier:ColorsIdentifiersSuccessLight];
}

- (UIColor*)successBase {
    return [self.oexColors colorForIdentifier:ColorsIdentifiersSuccessBase];
}

- (UIColor*)successDark {
    return [self.oexColors colorForIdentifier:ColorsIdentifiersSuccessDark];
}

- (UIColor*)successXDark {
    return [self.oexColors colorForIdentifier:ColorsIdentifiersSuccessXDark];
}

#pragma mark Warning Color

- (UIColor*)warningXXLight {
    return [self.oexColors colorForIdentifier:ColorsIdentifiersWarningXXLight];
}

- (UIColor*)warningXLight {
    return [self.oexColors colorForIdentifier:ColorsIdentifiersWarningXLight];
}

- (UIColor*)warningLight {
    return [self.oexColors colorForIdentifier:ColorsIdentifiersWarningLight];
}

- (UIColor*)warningBase {
    return [self.oexColors colorForIdentifier:ColorsIdentifiersWarningBase];
}

- (UIColor*)warningDark {
    return [self.oexColors colorForIdentifier:ColorsIdentifiersWarningDark];
}

- (UIColor*)warningXDark {
    return [self.oexColors colorForIdentifier:ColorsIdentifiersWarningXDark];
}

#pragma mark Error Color

- (UIColor*)errorXXLight {
    return [self.oexColors colorForIdentifier:ColorsIdentifiersErrorXXLight];
}

- (UIColor*)errorXLight {
    return [self.oexColors colorForIdentifier:ColorsIdentifiersErrorXLight];
}

- (UIColor*)errorLight {
    return [self.oexColors colorForIdentifier:ColorsIdentifiersErrorLight];
}

- (UIColor*)errorBase {
    return [self.oexColors colorForIdentifier:ColorsIdentifiersErrorBase];
}

- (UIColor*)errorDark {
    return [self.oexColors colorForIdentifier:ColorsIdentifiersErrorDark];
}

- (UIColor*)errorXDark {
    return [self.oexColors colorForIdentifier:ColorsIdentifiersErrorXDark];
}

#pragma mark Info Color

-(UIColor*) infoXXLight {
    return [self.oexColors colorForIdentifier:ColorsIdentifiersInfoXXLight];
}

-(UIColor*) infoXLight {
    return [self.oexColors colorForIdentifier:ColorsIdentifiersInfoXLight];
}

-(UIColor*) infoLight {
    return [self.oexColors colorForIdentifier:ColorsIdentifiersInfoLight];
}

-(UIColor*) infoBase {
    return [self.oexColors colorForIdentifier:ColorsIdentifiersInfoBase];
}

-(UIColor*) infoDark {
    return [self.oexColors colorForIdentifier:ColorsIdentifiersInfoDark];
}

-(UIColor*) infoXDark {
    return [self.oexColors colorForIdentifier:ColorsIdentifiersInfoXDark];
}

#pragma mark Supportive Colors

- (UIColor * __nonnull) disabledButtonColor
{
    return [self neutralXDark];
}

#pragma mark - Fonts

- (UIFont*)regularFontOfSize:(CGFloat)size {
    return [self.oexFonts fontFor:FontIdentifiersRegular
                                       size:size];
}

- (UIFont*)semiBoldFontOfSize:(CGFloat)size {
    return [self.oexFonts fontFor:FontIdentifiersSemiBold
                                       size:size];
}

- (UIFont*)boldFontOfSize:(CGFloat)size {
    return [self.oexFonts fontFor:FontIdentifiersBold
                                       size:size];
}

- (UIFont*)lightFontOfSize:(CGFloat)size {
    return [self.oexFonts fontFor:FontIdentifiersLight
                                       size:size];
}

- (UIFont*)regularFontOfSize:(CGFloat)size dynamicTypeSupported:(BOOL) dynamicTypeSupported {
    return [self.oexFonts fontFor:FontIdentifiersRegular
                             size:size dynamicTypeSupported:dynamicTypeSupported];
}

- (UIFont*)semiBoldFontOfSize:(CGFloat)size dynamicTypeSupported:(BOOL) dynamicTypeSupported {
    return [self.oexFonts fontFor:FontIdentifiersSemiBold
                             size:size dynamicTypeSupported:dynamicTypeSupported];
}

- (UIFont*)boldFontOfSize:(CGFloat)size dynamicTypeSupported:(BOOL) dynamicTypeSupported {
    return [self.oexFonts fontFor:FontIdentifiersBold
                             size:size dynamicTypeSupported:dynamicTypeSupported];
}

- (UIFont*)boldItalicFontOfSize:(CGFloat)size dynamicTypeSupported:(BOOL)dynamicTypeSupported {
    return [self.oexFonts fontFor:FontIdentifiersBoldItalic
                             size:size dynamicTypeSupported:dynamicTypeSupported];
}

- (UIFont*)lightFontOfSize:(CGFloat)size dynamicTypeSupported:(BOOL) dynamicTypeSupported {
    return [self.oexFonts fontFor:FontIdentifiersLight
                             size:size dynamicTypeSupported:dynamicTypeSupported];
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
