//
//  NSDictionary+EDXEncoding.m
//  edXVideoLocker
//
//  Created by Akiva Leffert on 11/4/14.
//  Copyright (c) 2014 edX. All rights reserved.
//

#import "NSDictionary+EDXEncoding.h"
#import "NSString+EDXEncoding.h"

@implementation NSDictionary (EDXEncoding)

- (NSString*)edx_stringByUsingFormEncoding {
    NSMutableString* result = [[NSMutableString alloc] init];
    __block NSUInteger remaining = self.count;
    [self enumerateKeysAndObjectsUsingBlock:^(NSString* key, NSString* value, BOOL *stop) {
        NSAssert([key isKindOfClass:[NSString class]], @"Form keys should be strings");
        NSAssert([key isKindOfClass:[NSString class]], @"Form values should be strings");
        [result appendString:key.edx_stringByUsingFormEncoding];
        [result appendString:@"="];
        [result appendString:value.edx_stringByUsingFormEncoding];
        if(remaining > 1) {
            [result appendString:@"&"];
        }
        remaining--;
    }];
    return result;
}


@end
