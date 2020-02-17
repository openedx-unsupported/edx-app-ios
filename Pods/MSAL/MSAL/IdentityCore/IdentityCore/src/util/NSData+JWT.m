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

#import "NSData+JWT.h"
#import <CommonCrypto/CommonDigest.h>
#import <Security/Security.h>
#import <Security/SecKey.h>

@implementation NSData (JWT)

#if TARGET_OS_IPHONE

- (NSData *)signHashWithPrivateKey:(SecKeyRef)privateKey
{
    NSData *signedHash = nil;
    size_t signedHashBytesSize = SecKeyGetBlockSize(privateKey);
    uint8_t *signedHashBytes = calloc(signedHashBytesSize, 1);

    if (!signedHashBytes)
    {
        return nil;
    }

    OSStatus status = errSecAuthFailed;

    status = SecKeyRawSign(privateKey,
                           kSecPaddingPKCS1SHA256,
                           [self bytes],
                           CC_SHA256_DIGEST_LENGTH,
                           signedHashBytes,
                           &signedHashBytesSize);

    if (status != errSecSuccess)
    {
        MSID_LOG_WITH_CTX(MSIDLogLevelError, nil, @"Failed to sign JWT %d", (int)status);
        free(signedHashBytes);
        return nil;
    }

    signedHash = [NSData dataWithBytes:signedHashBytes
                                length:(NSUInteger)signedHashBytesSize];

    free(signedHashBytes);
    return signedHash;
}

#else

- (NSData *)signHashWithPrivateKey:(SecKeyRef)privateKey
{
    CFErrorRef error = nil;
    // Create signer
    SecTransformRef signer = SecSignTransformCreate(privateKey, &error);

    if (!signer)
    {
        MSID_LOG_WITH_CTX(MSIDLogLevelError, nil, @"Failed to sign JWT %@", error);
        return nil;
    }

    BOOL result = YES;
    // Set attributes
    result &= [self setAttributeOnSigner:signer attributeKey:kSecPaddingKey attributeValue:kSecPaddingPKCS1Key];
    result &= [self setAttributeOnSigner:signer attributeKey:kSecInputIsAttributeName attributeValue:kSecInputIsDigest];
    result &= [self setAttributeOnSigner:signer attributeKey:kSecTransformInputAttributeName attributeValue:(__bridge CFDataRef)self];
    result &= [self setAttributeOnSigner:signer attributeKey:kSecDigestTypeAttribute attributeValue:kSecDigestSHA2];
    result &= [self setAttributeOnSigner:signer attributeKey:kSecDigestLengthAttribute attributeValue:(__bridge CFNumberRef)@(256)];

    if (!result)
    {
        MSID_LOG_WITH_CTX(MSIDLogLevelError, nil, @"Failed to sign JWT %@", error);
        CFRelease(signer);
        return nil;
    }

    CFDataRef resultData = SecTransformExecute(signer, &error);
    CFRelease(signer);

    if (!resultData)
    {
        MSID_LOG_WITH_CTX(MSIDLogLevelError, nil, @"Failed to sign JWT %@", error);
        return nil;
    }

    return CFBridgingRelease(resultData);
}

- (BOOL)setAttributeOnSigner:(SecTransformRef)signer attributeKey:(CFStringRef)key attributeValue:(CFTypeRef)value
{
    CFErrorRef error = nil;
    BOOL result = SecTransformSetAttribute(signer, key, value, &error);

    if (!result)
    {
        MSID_LOG_WITH_CTX(MSIDLogLevelError, nil, @"Failed to set signing attribute with error %@", error);
        return NO;
    }

    return YES;
}

#endif

@end
