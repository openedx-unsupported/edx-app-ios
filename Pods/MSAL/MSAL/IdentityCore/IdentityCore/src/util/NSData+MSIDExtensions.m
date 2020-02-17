// Copyright (c) Microsoft Corporation.
// All rights reserved.
//
// This code is licensed under the MIT License.
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files(the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and / or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions :
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

#import "NSData+MSIDExtensions.h"
#import "NSString+MSIDExtensions.h"
#import "NSDictionary+MSIDExtensions.h"
#import <CommonCrypto/CommonDigest.h>

@implementation NSData (MSIDExtensions)

- (NSData *)msidSHA1
{
    unsigned char hash[CC_SHA1_DIGEST_LENGTH];
    CC_SHA1(self.bytes, (CC_LONG)self.length, hash);
    
    return [NSData dataWithBytes:hash length:CC_SHA1_DIGEST_LENGTH];
}


- (NSData *)msidSHA256
{
    unsigned char hash[CC_SHA256_DIGEST_LENGTH];
    CC_SHA256(self.bytes, (CC_LONG)self.length, hash);
    
    return [NSData dataWithBytes:hash length:CC_SHA256_DIGEST_LENGTH];
}


- (NSString *)msidHexString
{
    return [NSString msidHexStringFromData:self];
}


- (NSString *)msidBase64UrlEncodedString
{
    return [NSString msidBase64UrlEncodedStringFromData:self];
}

/// <summary>
/// Base64 URL decode a set of bytes.
/// </summary>
/// <remarks>
/// See RFC 4648, Section 5 plus switch characters 62 and 63 and no padding.
/// For a good overview of Base64 encoding, see http://en.wikipedia.org/wiki/Base64
/// This SDK will use rfc7515 and decode using padding. See https://tools.ietf.org/html/rfc7515#appendix-C
/// </remarks>
+ (NSData *)msidDataFromBase64UrlEncodedString:(NSString *)encodedString
{
    NSString *base64encoded = [[encodedString stringByReplacingOccurrencesOfString:@"-" withString:@"+"]
                               stringByReplacingOccurrencesOfString:@"_" withString:@"/"];
    
    // The input string lacks the usual '=' padding at the end, so the valid end sequences
    // are:
    //      ........XX           (cbEncodedSize % 4) == 2    (2 chars of virtual padding)
    //      ........XXX          (cbEncodedSize % 4) == 3    (1 char of virtual padding)
    //      ........XXXX         (cbEncodedSize % 4) == 0    (no virtual padding)
    // Invalid sequences are:
    //      ........X            (cbEncodedSize % 4) == 1
    
    // Input string is not sized correctly to be base64 URL encoded.
    
    NSUInteger stringMod4 = base64encoded.length % 4;
    
    if (stringMod4 == 1)
    {
        return nil;
    }
    
    if (stringMod4 == 0)// No Padding necessary
    {
        return [[NSData alloc] initWithBase64EncodedString:base64encoded options:0];
    }
    
    // 'virtual padding'
    NSUInteger padding = 4 - stringMod4;
    NSUInteger paddedLength = base64encoded.length + padding;
    NSString *paddedString = [base64encoded stringByPaddingToLength:paddedLength withString:@"=" startingAtIndex:0];
    
    NSData *data = [[NSData alloc] initWithBase64EncodedString:paddedString options:0];
    return data;
}


@end
