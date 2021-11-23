//
//  OEXLocalizedString.m
//  edXVideoLocker
//
//  Created by Akiva Leffert on 3/2/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

#import "OEXLocalizedString.h"

#import <Smartling.i18n/SLLocalization.h>

NSString* OEXLocalizedStringFromTable(NSString* key, NSString* tbl, NSString* comment) {
    return NSLocalizedStringFromTable(key, tbl, comment);
}

NSString* OEXLocalizedStringPluralFromTable(NSString* key, NSString* tbl, NSInteger value, NSString* comment) {
    return SLPluralizedStringFromTable(key, tbl, value, comment);
}
