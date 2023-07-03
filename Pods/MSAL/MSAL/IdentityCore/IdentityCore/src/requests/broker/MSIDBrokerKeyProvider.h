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

#import <Foundation/Foundation.h>

#define kChosenCipherKeySize    kCCKeySizeAES256
#define kSymmetricKeyTag        "com.microsoft.adBrokerKey"

#if TARGET_OS_IPHONE

enum {
    CSSM_ALGID_NONE =                   0x00000000L,
    CSSM_ALGID_VENDOR_DEFINED =         CSSM_ALGID_NONE + 0x80000000L,
    CSSM_ALGID_AES
};

#endif

@interface MSIDBrokerKeyProvider : NSObject

- (instancetype)initWithGroup:(NSString *)keychainGroup;

- (instancetype)initWithGroup:(NSString *)keychainGroup
                keyIdentifier:(NSString *)keyIdentifier NS_DESIGNATED_INITIALIZER;

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

- (NSData *)brokerKeyWithError:(NSError **)error;

- (NSString *)base64BrokerKeyWithContext:(id<MSIDRequestContext>)context
                                   error:(NSError **)error;

- (BOOL)saveApplicationToken:(NSString *)appToken forClientId:(NSString *)clientId error:(NSError **)error;

- (NSString *)getApplicationToken:(NSString *)clientId error:(NSError **)error;

@end
