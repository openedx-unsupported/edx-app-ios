//
//  OEXStyles.m
//  edXVideoLocker
//
//  Created by Akiva Leffert on 12/3/14.
//  Copyright (c) 2014 edX. All rights reserved.
//

#import "OEXStyles.h"

#import "OEXSwitchStyle.h"

static OEXStyles* sSharedStyles;

@implementation OEXStyles

+ (instancetype)sharedStyles {
    return sSharedStyles;
}

+ (void)setSharedStyles:(OEXStyles*)styles {
    sSharedStyles = styles;
}

#pragma mark Metrics

- (CGFloat)dividerHeight {
    return 1 / [UIScreen mainScreen].scale;
}

- (CGFloat)standardHorizontalMargin {
    return 16;
}

#pragma mark Colors
// All colors per http://ux.edx.org/#colors

- (UIColor*)standardBackgroundColor {
    return [self neutralWhite];
}

#pragma mark Primary
- (UIColor*)primaryBaseColor {
    return [UIColor colorWithRed:0 green:122.0/255.0 blue:186.0/255. alpha:1];
}

- (UIColor*)primaryLightColor {
    return [UIColor colorWithRed:63/255. green:155/255. blue:203./255. alpha:1];
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
    return [UIColor colorWithRed:211/255. green:209/255. blue:209/255. alpha:1];
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

- (UIColor*)tintColor {
    return [self primaryLightColor];
}

#pragma mark Utility

- (UIColor*)utilitySuccessBase {
    return [UIColor colorWithRed:37/255. green:184/255. blue:90/255. alpha:1.0];
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
    return [[OEXSwitchStyle alloc] initWithTintColor:nil onTintColor:[self tintColor] thumbTintColor:nil];
}

@end
