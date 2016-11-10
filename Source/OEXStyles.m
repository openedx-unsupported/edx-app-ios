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
    return [self.oexColors colorForIdentifier:@"primaryXDarkColor"];
}

- (UIColor*)primaryDarkColor {
    return [self.oexColors colorForIdentifier:@"primaryDarkColor"];
}

- (UIColor*)primaryBaseColor {
    return [self.oexColors colorForIdentifier:@"primaryBaseColor"];
}

- (UIColor*)primaryLightColor {
    return [self.oexColors colorForIdentifier:@"primaryLightColor"];
}

- (UIColor*)primaryXLightColor {
    // Note. This is not the color value from the mobile style guide.
    // iOS seems to have a darker color space than the desktop so this is
    // deliberately lightened from that.
    return [self.oexColors colorForIdentifier:@"primaryXLightColor"];
}

#pragma mark Secondary

- (UIColor*)secondaryXDarkColor {
    return [self.oexColors colorForIdentifier:@"secondaryXDarkColor"];
}

- (nonnull UIColor*)secondaryDarkColor {
    return [self.oexColors colorForIdentifier:@"secondaryDarkColor"];
}

- (nonnull UIColor*)secondaryBaseColor {
    return [self.oexColors colorForIdentifier:@"secondaryBaseColor"];
}

- (nonnull UIColor*)secondaryLightColor {
    return [self.oexColors colorForIdentifier:@"secondaryLightColor"];
}

- (nonnull UIColor*)secondaryXLightColor {
    return [self.oexColors colorForIdentifier:@"secondaryXLightColor"];
}

#pragma mark Neutral

- (UIColor*)neutralBlack {
    return [self.oexColors colorForIdentifier:@"neutralBlack"];
}

- (UIColor*)neutralBlackT {
    return [self.oexColors colorForIdentifier:@"neutralBlackT"];
}

- (UIColor*)neutralXDark {
    return [self.oexColors colorForIdentifier:@"neutralXDark"];
}

- (UIColor*)neutralDark {
    return [self.oexColors colorForIdentifier:@"neutralDark"];
}

- (UIColor*)neutralBase {
    return [self.oexColors colorForIdentifier:@"neutralBase"];
}

- (UIColor*)neutralLight {
    return [self.oexColors colorForIdentifier:@"neutralLight"];
}

- (UIColor*)neutralXLight {
    return [self.oexColors colorForIdentifier:@"neutralXLight"];
}

- (UIColor*)neutralXXLight {
    return [self.oexColors colorForIdentifier:@"neutralXXLight"];
}

- (UIColor*)neutralWhite {
    return [self.oexColors colorForIdentifier:@"neutralWhite"];
}

- (UIColor*)neutralWhiteT {
    return [self.oexColors colorForIdentifier:@"neutralWhiteT"];
}


#pragma mark Utility

- (UIColor*)utilitySuccessDark {
    return [self.oexColors colorForIdentifier:@"utilitySuccessDark"];
}

- (UIColor*)utilitySuccessBase {
    return [self.oexColors colorForIdentifier:@"utilitySuccessBase"];
}

- (UIColor*)utilitySuccessLight {
    return [self.oexColors colorForIdentifier:@"utilitySuccessLight"];
}

- (UIColor*)warningDark {
    return [self.oexColors colorForIdentifier:@"warningDark"];
}

- (UIColor*)warningBase {
    return [self.oexColors colorForIdentifier:@"warningBase"];
}

- (UIColor*)warningLight {
    return [self.oexColors colorForIdentifier:@"warningLight"];
}

- (UIColor*)errorDark {
    return [self.oexColors colorForIdentifier:@"errorDark"];
}

- (UIColor*)errorBase {
    return [self.oexColors colorForIdentifier:@"errorBase"];
}

- (UIColor*)errorLight {
    return [self.oexColors colorForIdentifier:@"errorLight"];
}

- (UIColor*)banner {
    return [self.oexColors colorForIdentifier:@"banner"];
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
