//
//  NSDictionary+OEXEncoding.m
//  edXVideoLocker
//
//  Created by Akiva Leffert on 11/4/14.
//  Copyright (c) 2014 edX. All rights reserved.
//

#import "NSDictionary+OEXEncoding.h"
#import "NSString+OEXEncoding.h"

@implementation NSDictionary (OEXEncoding)

- (NSString*)oex_stringByUsingFormEncoding {
    NSMutableString* result = [[NSMutableString alloc] init];
    __block NSUInteger remaining = self.count;
    [self enumerateKeysAndObjectsUsingBlock:^(NSString* key, NSString* value, BOOL* stop) {
        NSAssert([key isKindOfClass:[NSString class]], @"Form keys should be strings");
        NSAssert([key isKindOfClass:[NSString class]], @"Form values should be strings");
        [result appendString:key.oex_stringByUsingFormEncoding];
        [result appendString:@"="];
        [result appendString:value.oex_stringByUsingFormEncoding];
        if(remaining > 1) {
            [result appendString:@"&"];
        }
        remaining--;
    }];
    return result;
}

@end
