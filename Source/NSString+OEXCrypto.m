//
//  NSString+OEXCrypto.m
//  edX
//
//  Created by Akiva Leffert on 6/18/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

#import "NSString+OEXCrypto.h"

#import <CommonCrypto/CommonCrypto.h>

@implementation NSString (OEXCrypto)

- (NSString*)oex_md5 {
    NSData* data = [self dataUsingEncoding:NSUTF8StringEncoding];
    unsigned char md5Buffer[CC_MD5_DIGEST_LENGTH];
    CC_MD5(data.bytes, (CC_LONG)data.length, md5Buffer);
    
    NSMutableString *output = [NSMutableString stringWithCapacity:CC_MD5_DIGEST_LENGTH * 2];
    for(int i = 0; i < CC_MD5_DIGEST_LENGTH; i++)
        [output appendFormat:@"%02x",md5Buffer[i]];
    
    return output;
}

@end
