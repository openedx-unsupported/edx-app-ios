//
//  NSString+OEXValidation.m
//  edXVideoLocker
//
//  Created by Akiva Leffert on 1/26/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

#import "NSString+OEXValidation.h"

@implementation NSString (OEXValidation)

- (BOOL)oex_isValidEmailAddress {
    // Regular expression to check the email format.
    NSString* emailReg = @".+@.+\\..+";

    NSPredicate* emailTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", emailReg];
    return [emailTest evaluateWithObject:self];
}

@end
