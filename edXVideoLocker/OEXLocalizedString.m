//
//  OEXLocalizedString.m
//  edXVideoLocker
//
//  Created by Akiva Leffert on 3/2/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

#import "OEXLocalizedString.h"

NSString* OEXLocalizedString(NSString* key, NSString* comment) {
    NSString* result = NSLocalizedString(key, comment);
    return result;
}