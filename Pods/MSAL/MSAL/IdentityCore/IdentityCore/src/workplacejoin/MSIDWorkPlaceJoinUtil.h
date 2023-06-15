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
#import "MSIDWorkPlaceJoinUtilBase.h"

@class MSIDRegistrationInformation;
@class MSIDWorkplaceJoinChallenge;
@class MSIDWPJKeyPairWithCert;

@interface MSIDWorkPlaceJoinUtil : MSIDWorkPlaceJoinUtilBase

// MSIDRegistrationInformation contains keys, cert and IdentityRef - needed for Client TLS challenges
+ (nullable MSIDRegistrationInformation *)getRegistrationInformation:(nullable id<MSIDRequestContext>)context
                                              workplacejoinChallenge:(nullable MSIDWorkplaceJoinChallenge *)workplacejoinChallenge;

// MSIDWPJKeyPairWithCert only contains keys and cert - no IdentityRef. Can be used for PkeyAuth challenges, but not for Client TLS challenges
+ (nullable MSIDWPJKeyPairWithCert *)getWPJKeysWithTenantId:(nullable NSString *)tenantId
                                                    context:(nullable id<MSIDRequestContext>)context;

+ (nullable NSString *)getWPJStringDataForIdentifier:(nonnull NSString *)identifier
                                             context:(nullable id<MSIDRequestContext>)context
                                               error:(NSError*__nullable*__nullable)error;

+ (nullable NSString *)getWPJStringDataFromV2ForTenantId:(NSString *_Nullable)tenantId
                                              identifier:(nonnull NSString *)identifier
                                                     key:(nullable NSString *)key
                                                 context:(nullable id<MSIDRequestContext>)context
                                                   error:(NSError*__nullable*__nullable)error;

@end
