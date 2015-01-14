//
//  NSString+EDXEncoding.m
//  edXVideoLocker
//
//  Created by Akiva Leffert on 11/4/14.
//  Copyright (c) 2014 edX. All rights reserved.
//

#import "NSString+EDXEncoding.h"

@implementation NSString (EDXEncoding)

- (NSString*)edx_stringByUsingFormEncoding {
    NSMutableCharacterSet* characters = [NSCharacterSet alphanumericCharacterSet].mutableCopy;
    [characters addCharactersInString:@" "];
    NSString* encoded = [self stringByAddingPercentEncodingWithAllowedCharacters:characters];
    NSString* result = [encoded stringByReplacingOccurrencesOfString:@" " withString:@"+"];
    return result;
}

@end
