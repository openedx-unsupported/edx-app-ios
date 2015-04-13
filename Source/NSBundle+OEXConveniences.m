//
//  NSBundle+OEXConveniences.m
//  edXVideoLocker
//
//  Created by Akiva Leffert on 1/26/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

#import "NSBundle+OEXConveniences.h"

@implementation NSBundle (OEXConveniences)

- (NSString*)oex_shortVersionString {
    return [[NSBundle mainBundle] objectForInfoDictionaryKey: @"CFBundleShortVersionString"];
}

- (NSLocale*)oex_displayLocale {
    NSString* localization = [NSBundle mainBundle].preferredLocalizations.firstObject;
    NSLocale* locale = [[NSLocale alloc] initWithLocaleIdentifier:localization];
    return locale;
}

@end
