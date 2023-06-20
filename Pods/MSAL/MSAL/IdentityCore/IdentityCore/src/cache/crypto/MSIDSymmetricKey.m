//
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

#include "MSIDSymmetricKey.h"

#import <CommonCrypto/CommonCryptor.h>
#import <CommonCrypto/CommonHMAC.h>
#import <CommonCrypto/CommonDigest.h>

@interface MSIDSymmetricKey()

@property (nonatomic) NSString *symmetricKeyBase64;

@end

@implementation MSIDSymmetricKey

- (nullable instancetype)initWithSymmetricKeyBytes:(NSData *)symmetricKey
{
    if (!symmetricKey)
    {
        return nil;
    }
    
    self = [super init];
    
    if (self)
    {
        _symmetricKey = symmetricKey;
    }
    
    return self;
}

- (nullable instancetype)initWithSymmetricKeyBase64:(NSString *)symmetricKeyBase64
{
    if (!symmetricKeyBase64)
    {
        return nil;
    }
    
    return [self initWithSymmetricKeyBytes:[[NSData alloc] initWithBase64EncodedString:symmetricKeyBase64 options:0]];
}

- (nullable NSString *)createVerifySignature:(NSData *)context
                                  dataToSign:(NSString *)dataToSign
{
    NSData *data = [dataToSign dataUsingEncoding:NSUTF8StringEncoding];
    NSData *derivedKey = [self computeKDFInCounterMode:context];
    if (data == nil || data.length == 0 || derivedKey == nil)
    {
        return nil;
    }
    
    unsigned char cHMAC[CC_SHA256_DIGEST_LENGTH];
    CCHmac(kCCHmacAlgSHA256,
           derivedKey.bytes,
           derivedKey.length,
           [data bytes],
           [data length],
           cHMAC);
    NSData *signedData = [[NSData alloc] initWithBytes:cHMAC length:sizeof(cHMAC)];

    return [NSString msidBase64UrlEncodedStringFromData:signedData];
}

/**
 Key Derivation using Pseudorandom Functions in Counter Mode: SP 800-108
 Spec link: https://nvlpubs.nist.gov/nistpubs/Legacy/SP/nistspecialpublication800-108.pdf
 Formula:
 
 Fixed values:
 1. h - The length of the output of the PRF in bits
 2. r - The length of the binary representation of the counter i.
 Input: KI, Label, Context, and L.
 Process:
 1. n := ⎡L/h⎤.
 2. If n > 2^r -1, then indicate an error and stop.
 3. result(0):= ∅.
 4. For i = 1 to n, do
 a. K(i) := PRF (KI, [i]2 || Label || 0x00 || Context || [L]2)
 12
 SP 800-108 Recommendation for Key Derivation Using Pseudorandom Functions
 b. result(i) := result(i-1) || K(i).
 5. Return: KO := the leftmost L bits of result(n).
 Output: KO.
 
 Implementation notes:
 1. PRF: we use HMAC-SHA256
 h: 256
 r: 32
 L: 256
 Label: AzureAD-SecureConversation
 
 the input of HMAC-SHA256 would look like:
 0x00 0x00 0x00 0x01 || AzureAD-SecureConversation String in binary || 0x00 || context in binary || (256) in big-endian binary
 
 */

- (NSData *)computeKDFInCounterMode:(NSData *)ctx
{
    if (ctx == nil)
    {
        return nil;
    }
    
    NSData *labelData = [@"AzureAD-SecureConversation" dataUsingEncoding:NSUTF8StringEncoding];
    NSMutableData *mutData = [NSMutableData new];
    [mutData appendBytes:labelData.bytes length:labelData.length];
    Byte bytes[] = {0x00};
    [mutData appendBytes:bytes length:1];
    [mutData appendBytes:ctx.bytes length:ctx.length];
    int32_t size = CFSwapInt32HostToBig(256); //make big-endian
    [mutData appendBytes:&size length:sizeof(size)];
    
    uint8_t *pbDerivedKey = [self kdfCounterMode:(uint8_t*)_symmetricKey.bytes
                          keyDerivationKeyLength:_symmetricKey.length
                                      fixedInput:(uint8_t*)mutData.bytes
                                fixedInputLength:mutData.length];
    
    if (pbDerivedKey == NULL)
    {
        return nil;
    }
    
    mutData = nil;
    NSData *dataToReturn = [NSData dataWithBytes:(const void *)pbDerivedKey length:32];
    free(pbDerivedKey);
    
    return dataToReturn;
}

- (uint8_t *)kdfCounterMode:(uint8_t *)keyDerivationKey
     keyDerivationKeyLength:(size_t)keyDerivationKeyLength
                 fixedInput:(uint8_t *)fixedInput
           fixedInputLength:(size_t)fixedInputLength
{
    uint32_t ctr;
    unsigned char cHMAC[CC_SHA256_DIGEST_LENGTH];
    uint8_t *keyDerivated;
    uint8_t *dataInput;
    int len;
    int numCurrentElements;
    int numCurrentElements_bytes;
    int outputSizeBit = 256;
    
    numCurrentElements = 0;
    ctr = 1;
    keyDerivated = (uint8_t *)malloc(outputSizeBit / 8); //output is 32 bytes
    
    if (keyDerivated == NULL)
    {
        return NULL;
    }
    
    do
    {
        //update data using "ctr"
        dataInput = [self updateDataInput:ctr
                               fixedInput:fixedInput
                        fixedInput_length:fixedInputLength];
        
        if (dataInput == NULL)
        {
            return NULL;
        }
        
        CCHmac(kCCHmacAlgSHA256,
               keyDerivationKey,
               keyDerivationKeyLength,
               dataInput,
               (fixedInputLength+4), //+4 to account for ctr
               cHMAC);
        
        //decide how many bytes (so the "length") copy for currently keyDerivated?
        if (256 >= outputSizeBit)
        {
            len = outputSizeBit;
        }
        else
        {
            len = MIN(256, outputSizeBit - numCurrentElements);
        }
        
        //convert bits in byte
        numCurrentElements_bytes = numCurrentElements/8;
        
        //copy KI in part of keyDerivated
        memcpy((keyDerivated + numCurrentElements_bytes), cHMAC, 32);
        
        //increment ctr and numCurrentElements copied in keyDerivated
        numCurrentElements = numCurrentElements + len;
        ctr++;
        
        //deallock space in memory
        free(dataInput);
        
    } while (numCurrentElements < outputSizeBit);
    
    return keyDerivated;
}


/*
 *Function used to shift data by 4 byte and insert ctr in the first 4 bytes.
 */
- (uint8_t *)updateDataInput:(uint8_t)ctr
                  fixedInput:(uint8_t *)fixedInput
           fixedInput_length:(size_t)fixedInput_length
{
    uint8_t *tmpFixedInput = (uint8_t *)malloc(fixedInput_length + 4); //+4 is caused from the ct
    
    if (tmpFixedInput == NULL)
    {
        return NULL;
    }
 
    tmpFixedInput[0] = (ctr >> 24);
    tmpFixedInput[1] = (ctr >> 16);
    tmpFixedInput[2] = (ctr >> 8);
    tmpFixedInput[3] = ctr;
    
    memcpy(tmpFixedInput + 4, fixedInput, fixedInput_length * sizeof(uint8_t));
    return tmpFixedInput;
}

- (NSString *)symmetricKeyBase64
{
    return [_symmetricKey base64EncodedStringWithOptions:0];
}

@end
