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

- (NSString*)oex_appName {
    return [[NSBundle mainBundle] objectForInfoDictionaryKey: (__bridge NSString*)kCFBundleExecutableKey];
}

- (NSString*)oex_buildVersionString {
    return [[NSBundle mainBundle] objectForInfoDictionaryKey: (__bridge NSString*)kCFBundleVersionKey];
}

- (NSLocale*)oex_displayLocale {
    NSString* localization = [NSBundle mainBundle].preferredLocalizations.firstObject;
    NSLocale* locale = [[NSLocale alloc] initWithLocaleIdentifier:localization];
    return locale;
}

- (NSString*)oex_displayLanguage {
    return [[self oex_displayLocale] objectForKey:NSLocaleLanguageCode];
}

- (NSString*)oex_displayCountry {
    // The display localizations may not have a country portion so fall back to the system locale
    return [[self oex_displayLocale] objectForKey:NSLocaleCountryCode] ?: [[NSLocale currentLocale] objectForKey:NSLocaleCountryCode];
}

@end
