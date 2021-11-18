//
//  OEXLocalizedString.m
//  edXVideoLocker
//
//  Created by Akiva Leffert on 3/2/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

#import "OEXLocalizedString.h"

#import <Smartling.i18n/SLLocalization.h>

NSString* OEXLocalizedString(NSString* key, NSString* comment) {
    NSString* result = NSLocalizedString(key, comment);
    return result;
}

NSString* OEXLocalizedStringFromTable(NSString* key, NSString* tbl, NSString* comment) {
    NSString* result = NSLocalizedStringFromTable(key, tbl, comment);
    return result;
}

NSString* OEXLocalizedStringPlural(NSString* key, NSInteger value, NSString* comment) {
    NSString* result = SLPluralizedString(key, value, comment);
    return result;
}

NSString* OEXLocalizedStringPluralFromTable(NSString* key, NSString* tbl, NSInteger value, NSString* comment) {
    NSString* result = SLPluralizedStringFromTable(key, tbl, value, comment);
    return result;
}
