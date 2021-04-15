//
//  NSBundle+OEXConveniences.h
//  edXVideoLocker
//
//  Created by Akiva Leffert on 1/26/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSBundle (OEXConveniences)

/// The user facing version, like 2.1.2
- (NSString*)oex_shortVersionString;
/// The build number, like 6512
- (NSString*)oex_buildVersionString;
/// The user facing version string, like 2.1.2 (6512)
- (NSString*)oex_displayVersionString;
/// The user facing app name, like edX
- (NSString*)oex_appName;

/// [NSLocale currentLocale] is the locale the *system* is set to.
/// oex_displayLocale is the locale we're actually displaying our UI in since, we may not have a translation
/// for the system locale.
- (NSLocale*)oex_displayLocale;
/// Two letter language code for the locale returned by oex_displayLocale
- (NSString*)oex_displayLanguage;
/// Best guess out a current country. The display locale (see oex_displayLocale)
/// may not have a country associated with it, in which case we fall back to the system locale.
- (NSString*)oex_displayCountry;

@end

NS_ASSUME_NONNULL_END
