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
    return [self.oexColors colorForIdentifier:ColorsIdentifiersPrimaryXDarkColor];
}

- (UIColor*)primaryDarkColor {
    return [self.oexColors colorForIdentifier:ColorsIdentifiersPrimaryDarkColor];
}

- (UIColor*)primaryBaseColor {
    return [self.oexColors colorForIdentifier:ColorsIdentifiersPrimaryBaseColor];
}

- (UIColor*)primaryLightColor {
    return [self.oexColors colorForIdentifier:ColorsIdentifiersPrimaryLightColor];
}

- (UIColor*)primaryXLightColor {
    // Note. This is not the color value from the mobile style guide.
    // iOS seems to have a darker color space than the desktop so this is
    // deliberately lightened from that.
    return [self.oexColors colorForIdentifier:ColorsIdentifiersPrimaryXLightColor];
}

#pragma mark Secondary

- (UIColor*)secondaryXDarkColor {
    return [self.oexColors colorForIdentifier:ColorsIdentifiersSecondaryXDarkColor];
}

- (nonnull UIColor*)secondaryDarkColor {
    return [self.oexColors colorForIdentifier:ColorsIdentifiersSecondaryDarkColor];
}

- (nonnull UIColor*)secondaryBaseColor {
    return [self.oexColors colorForIdentifier:ColorsIdentifiersSecondaryBaseColor];
}

- (nonnull UIColor*)secondaryLightColor {
    return [self.oexColors colorForIdentifier:ColorsIdentifiersSecondaryLightColor];
}

- (nonnull UIColor*)secondaryXLightColor {
    return [self.oexColors colorForIdentifier:ColorsIdentifiersSecondaryXLightColor];
}

#pragma mark Neutral

- (UIColor*)neutralBlack {
    return [self.oexColors colorForIdentifier:ColorsIdentifiersNeutralBlack];
}

- (UIColor*)neutralBlackT {
    return [self.oexColors colorForIdentifier:ColorsIdentifiersNeutralBlackT];
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

- (UIColor*)neutralLight {
    return [self.oexColors colorForIdentifier:ColorsIdentifiersNeutralLight];
}

- (UIColor*)neutralXLight {
    return [self.oexColors colorForIdentifier:ColorsIdentifiersNeutralXLight];
}

- (UIColor*)neutralXXLight {
    return [self.oexColors colorForIdentifier:ColorsIdentifiersNeutralXXLight];
}

- (UIColor*)neutralWhite {
    return [self.oexColors colorForIdentifier:ColorsIdentifiersNeutralWhite];
}

- (UIColor*)neutralWhiteT {
    return [self.oexColors colorForIdentifier:ColorsIdentifiersNeutralWhiteT];
}


#pragma mark Utility

- (UIColor*)utilitySuccessDark {
    return [self.oexColors colorForIdentifier:ColorsIdentifiersUtilitySuccessDark];
}

- (UIColor*)utilitySuccessBase {
    return [self.oexColors colorForIdentifier:ColorsIdentifiersUtilitySuccessBase];
}

- (UIColor*)utilitySuccessLight {
    return [self.oexColors colorForIdentifier:ColorsIdentifiersUtilitySuccessLight];
}

- (UIColor*)warningDark {
    return [self.oexColors colorForIdentifier:ColorsIdentifiersWarningDark];
}

- (UIColor*)warningBase {
    return [self.oexColors colorForIdentifier:ColorsIdentifiersWarningBase];
}

- (UIColor*)warningLight {
    return [self.oexColors colorForIdentifier:ColorsIdentifiersWarningLight];
}

- (UIColor*)errorDark {
    return [self.oexColors colorForIdentifier:ColorsIdentifiersErrorDark];
}

- (UIColor*)errorBase {
    return [self.oexColors colorForIdentifier:ColorsIdentifiersErrorBase];
}

- (UIColor*)errorLight {
    return [self.oexColors colorForIdentifier:ColorsIdentifiersErrorLight];
}

- (UIColor*)banner {
    return [self.oexColors colorForIdentifier:ColorsIdentifiersBanner];
}

- (UIColor * __nonnull) disabledButtonColor
{
    return [UIColor grayColor];
}

#pragma mark Fonts

- (UIFont*)sansSerifOfSize:(CGFloat)size {
    return [self.oexFonts fontForIdentifier:FontIdentifiersRegular
                                       size:size];
}

- (UIFont*)semiBoldSansSerifOfSize:(CGFloat)size {
    return [self.oexFonts fontForIdentifier:FontIdentifiersSemiBold
                                       size:size];
}

- (UIFont*)boldSansSerifOfSize:(CGFloat)size {
    return [self.oexFonts fontForIdentifier:FontIdentifiersBold
                                       size:size];
}

- (UIFont*)lightSansSerifOfSize:(CGFloat)size {
    return [self.oexFonts fontForIdentifier:FontIdentifiersLight
                                       size:size];
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
