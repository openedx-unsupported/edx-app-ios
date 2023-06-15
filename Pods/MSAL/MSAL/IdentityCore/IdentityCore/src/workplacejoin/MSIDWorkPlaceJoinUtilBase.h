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

#ifndef MSIDWorkPlaceJoinUtilBase_h
#define MSIDWorkPlaceJoinUtilBase_h

@class MSIDWPJKeyPairWithCert;

#import <Foundation/Foundation.h>

@interface MSIDWorkPlaceJoinUtilBase : NSObject

+ (nullable NSDictionary *)getRegisteredDeviceMetadataInformation:(nullable id<MSIDRequestContext>)context;

+ (nullable NSDictionary *)getRegisteredDeviceMetadataInformation:(nullable id<MSIDRequestContext>)context
                                                         tenantId:(nullable NSString *)tenantId;

/**
    Helper API to lookup both the private key and the associated certificate from the keychain.
    Functionality of the API can be customized by specifying custom private and cert lookup attributes.
 
    @param queryAttributes Additional private key lookup attributes. Caller can specify additional parameters like kSecAttrAccessGroup, or kSecAttrApplicationTag to make private key lookup more specific.
    @param certAttributes Additional certificate lookup attributes. Caller can specify additional parameters like kSecAttrAccessGroup to make certificate lookup more specific.
    @param context   Additional request context used for logging and telemetry.
 
    @return MSIDWPJKeyPairWithCert representing a combination of a private key and a certificate if it was found, nil otherwise. Currently only looks up RSA private keys until full ECC test setup is available. 
*/
+ (nullable MSIDWPJKeyPairWithCert *)findWPJRegistrationInfoWithAdditionalPrivateKeyAttributes:(nonnull NSDictionary *)queryAttributes
                                                                                certAttributes:(nullable NSDictionary *)certAttributes
                                                                                       context:(nullable id<MSIDRequestContext>)context;

@end

#endif /* MSIDWorkPlaceJoinUtilBase_h */
