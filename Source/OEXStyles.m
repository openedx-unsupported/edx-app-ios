//
//  OEXStyles.m
//  edXVideoLocker
//
//  Created by Akiva Leffert on 12/3/14.
//  Copyright (c) 2014 edX. All rights reserved.
//

#import "OEXStyles.h"

#import "OEXSwitchStyle.h"
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
    return 16;
}

#pragma mark Computed Style

- (UIColor*) navigationBarColor {
    return [self primaryAccentColor];
}

- (UIColor*) navigationItemTintColor {
    return [self standardBackgroundColor];
}

- (void) applyMockNavigationBarStyleToView:(UIView*)view label:(UILabel*) label leftIconButton:(nullable UIButton*) iconButton {
    
    if ([[OEXConfig sharedConfig]shouldEnableNewCourseNavigation]) {
        view.backgroundColor = [self navigationBarColor];
        label.textColor = [self navigationItemTintColor];
        if (iconButton != nil) {
            
            [iconButton setImage:[iconButton.imageView.image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
            [iconButton.imageView setTintColor: [self navigationItemTintColor]];
            
        }
    }
    
}

#pragma mark Colors
// All colors per http://ux.edx.org/#colors

#pragma mark Standard Usages

- (UIColor*)standardBackgroundColor {
    return [self neutralWhite];
}

#pragma mark Primary

- (UIColor*)primaryXDarkColor {
    return [UIColor colorWithRed:0 green:54/255. blue:84/255. alpha:1];
}

- (UIColor*)primaryDarkColor {
    return [UIColor colorWithRed:0 green:84/255. blue:131/255. alpha:1];
}

- (UIColor*)primaryBaseColor {
    return [UIColor colorWithRed:0 green:121/255.0 blue:188/255. alpha:1];
}

- (UIColor*)primaryLightColor {
    return [UIColor colorWithRed:76/255. green:161/255. blue:208/255. alpha:1];
}

- (UIColor*)primaryXLightColor {
    return [UIColor colorWithRed:178/255. green:214/255. blue:234/255. alpha:1];
}

- (UIColor*)primaryAccentColor {
    return [UIColor colorWithRed:14/255. green:166/255. blue:236/255. alpha:1];
}

- (UIColor*)primaryXAccentColor {
    return [UIColor colorWithRed:0/255. green:178/255. blue:255/255. alpha:1];
}

#pragma mark Secondary

- (UIColor*)secondaryXDarkColor {
    return [UIColor colorWithRed:91/255. green:40/255. blue:63./255. alpha:1.];
}

- (nonnull UIColor*)secondaryDarkColor {
    return [UIColor colorWithRed:142/255. green:62/255. blue:98/255. alpha:1.];
}

- (nonnull UIColor*)secondaryBaseColor {
    return [UIColor colorWithRed:203./255. green:89./255. blue:141./255. alpha:1.];
}

- (nonnull UIColor*)secondaryLightColor {
    return [UIColor colorWithRed:218/255. green:138/255. blue:175/255. alpha:1.];
}

- (nonnull UIColor*)secondaryXLightColor {
    return [UIColor colorWithRed:239/255. green:205/255. blue:220./255. alpha:1.];
}

- (nonnull UIColor*)secondaryAccentColor {
    return [UIColor colorWithRed:242/255. green:108./255 blue:170/255. alpha:1.];
}

#pragma mark Neutral

- (UIColor*)neutralBlack {
    return [UIColor colorWithWhite:16/255. alpha:1];
}

- (UIColor*)neutralBlackT {
    return [UIColor colorWithWhite:0/255. alpha:1];
}

- (UIColor*)neutralXDark {
    return [UIColor colorWithRed:66/255. green:65/255. blue:65/255. alpha:1];
}

- (UIColor*)neutralDark {
    return [UIColor colorWithRed:100/255. green:98/255. blue:98/255. alpha:1];
}

- (UIColor*)neutralBase {
    return [UIColor colorWithRed:167/255. green:164/255. blue:164/255. alpha:1];
}

- (UIColor*)neutralLight {
    return [UIColor colorWithRed:211/255. green:209/255. blue:209/255. alpha:1];
}

- (UIColor*)neutralXLight {
    return [UIColor colorWithRed:233/255. green:232/255. blue:232/255. alpha:1];
}

- (UIColor*)neutralWhite {
    return [UIColor colorWithWhite:252/255. alpha:1];
}

- (UIColor*)neutralWhiteT {
    return [UIColor colorWithWhite:255/255. alpha:1];
}

- (UIColor*)neutralTranslucent {
    return [UIColor colorWithRed:167/255. green:164/255. blue:164/255. alpha:.498];
}

- (UIColor*)neutralXTranslucent {
    return [UIColor colorWithRed:167/255. green:164/255. blue:164/255. alpha:.247];
}

- (UIColor*)neutralXXTranslucent {
    return [UIColor colorWithRed:167/255. green:164/255. blue:164/255. alpha:.0471];
}


#pragma mark Cool

- (UIColor*)coolXDark {
    return [UIColor colorWithRed:39/255. green:44/255. blue:46/255. alpha:1];
}

- (UIColor*)coolDark {
    return [UIColor colorWithRed:79/255. green:88/255. blue:92/255. alpha:1];
}

- (UIColor*)coolBase {
    return [UIColor colorWithRed:158/255. green:177/255. blue:185/255. alpha:1];
}

- (UIColor*)coolLight {
    return [UIColor colorWithRed:206/255. green:216/255. blue:220/255. alpha:1];
}

- (UIColor*)coolXLight {
    return [UIColor colorWithRed:230/255. green:235/255. blue:237/255. alpha:1];
}

- (UIColor*)coolTrans {
    return [UIColor colorWithRed:158/255. green:177/255. blue:185/255. alpha:0.5];
}

- (UIColor*)coolXTrans {
    return [UIColor colorWithRed:158/255. green:177/255. blue:185/255. alpha:.247];
}

- (UIColor*)coolXXTrans {
    return [UIColor colorWithRed:158/255. green:177/255. blue:185/255. alpha:.047];
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

#pragma mark Fonts

- (UIFont*)sansSerifOfSize:(CGFloat)size {
    return [UIFont fontWithName:@"OpenSans" size:size];
}

- (UIFont*)boldSansSerifOfSize:(CGFloat)size {
    return [UIFont fontWithName:@"OpenSans-Semibold" size:size];
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
