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

#import "MSIDBrokerCryptoProvider.h"
#import "NSData+AES.h"
#import "NSData+MSIDExtensions.h"
#import <CommonCrypto/CommonCrypto.h>
#import "NSData+MSIDExtensions.h"
#import "NSMutableDictionary+MSIDExtensions.h"

@interface MSIDBrokerCryptoProvider()

@property (nonatomic) NSData *encryptionKey;

@end

@implementation MSIDBrokerCryptoProvider

- (instancetype)initWithEncryptionKey:(NSData *)encryptionKey
{
    self = [super init];

    if (self)
    {
        _encryptionKey = encryptionKey;
    }

    return self;
}

- (NSDictionary *)decryptBrokerResponse:(NSDictionary *)response
                          correlationId:(NSUUID *)correlationId
                                  error:(NSError **)error
{
    NSString *hash = response[@"hash"];

    if (!hash)
    {
        MSIDFillAndLogError(error, MSIDErrorBrokerResponseHashMissing, @"Key hash is missing from the broker response", correlationId);
        return nil;
    }

    NSString *encryptedBase64Response = response[@"response"];
    NSString *msgVer = response[@"msg_protocol_ver"];

    NSInteger protocolVersion = msgVer ? [msgVer integerValue] : 1;

    NSData *encryptedResponse = [NSData msidDataFromBase64UrlEncodedString:encryptedBase64Response];

    if (!encryptedResponse)
    {
        MSIDFillAndLogError(error, MSIDErrorBrokerCorruptedResponse, @"Encrypted response missing from broker response", correlationId);
        return nil;
    }

    NSData *decrypted = [self decryptData:encryptedResponse protocolVersion:protocolVersion];

    if (!decrypted)
    {
        MSIDFillAndLogError(error, MSIDErrorBrokerResponseDecryptionFailed, @"Failed to decrypt broker message", correlationId);
        return nil;
    }

    NSString *decryptedString = [[NSString alloc] initWithData:decrypted encoding:NSUTF8StringEncoding];

    if (!decryptedString)
    {
        MSIDFillAndLogError(error, MSIDErrorBrokerResponseDecryptionFailed, @"Failed to initialize decrypted string", correlationId);
        return nil;
    }

    //now compute the hash on the unencrypted data
    NSString *actualHash = [[[[decrypted msidSHA256] msidHexString] msidTrimmedString] uppercaseString];

    if (![hash isEqualToString:actualHash])
    {
        MSIDFillAndLogError(error, MSIDErrorBrokerResponseHashMismatch, @"Decrypted response does not match the hash", correlationId);
        return nil;
    }

    // create response from the decrypted payload
    NSDictionary *decryptedResponse = [NSDictionary msidDictionaryFromWWWFormURLEncodedString:decryptedString];
    return [decryptedResponse msidDictionaryWithoutNulls];
}

- (nullable NSData *)decryptData:(NSData *)response
                 protocolVersion:(NSUInteger)version
{
    const void *keyBytes = nil;
    size_t keySize = 0;

    // 'key' should be 32 bytes for AES256, will be null-padded otherwise
    char keyPtr[kCCKeySizeAES256+1]; // room for terminator (unused)

    if (version > 1)
    {
        keyBytes = [self.encryptionKey bytes];
        keySize = [self.encryptionKey length];
    }
    else
    {
        NSString *key = [[NSString alloc] initWithData:self.encryptionKey encoding:NSASCIIStringEncoding];
        bzero(keyPtr, sizeof(keyPtr)); // fill with zeroes (for padding)
        // fetch key data
        [key getCString:keyPtr maxLength:sizeof(keyPtr) encoding:NSUTF8StringEncoding];
        keyBytes = keyPtr;
        keySize = kCCKeySizeAES256;
    }

    return [response msidAES128DecryptedDataWithKey:keyBytes keySize:keySize];
}

@end
