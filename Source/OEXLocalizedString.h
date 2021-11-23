//
//  OEXLocalizedString.h
//  edXVideoLocker
//
//  Created by Akiva Leffert on 3/2/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// Use this for *all* strings displayed to the user
/// unless they need to handle plurals in which case see OEXLocalizedStringPlural
/// The string should be defined in Localizable.strings
/// With Table name, which should be current file name, e.g. ProfileOptions
/// Along with a comment there.

NSString* OEXLocalizedStringFromTable(NSString* string, NSString* tbl, NSString* __nullable  comment);

/// Use this for *all* strings displayed to the user that need to handle pluralization
/// For other strings see OEXLocalizedString
/// The string should be defined in Localizable.strings
/// Along with a comment there.
/// With Table name, which should be current file name, e.g. ProfileOptions
/// For full documentation on the format to deal with the different plural cases see
/// https://github.com/Smartling/ios-i18n

NSString* OEXLocalizedStringPluralFromTable(NSString* key, NSString* tbl, NSInteger value,  NSString* __nullable  comment);

NS_ASSUME_NONNULL_END
