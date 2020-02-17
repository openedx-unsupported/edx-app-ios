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
#import "MSIDConstants.h"
#import "MSIDCacheAccessor.h"

@class MSIDInteractiveRequestParameters;
@class MSIDOauth2Factory;
@class MSIDTokenResponseValidator;
@class MSIDWebWPJResponse;
@class MSIDAccountMetadataCacheAccessor;

#if TARGET_OS_OSX
@class MSIDExternalAADCacheSeeder;
#endif

typedef void (^MSIDInteractiveRequestCompletionBlock)(MSIDTokenResult * _Nullable result, NSError * _Nullable error, MSIDWebWPJResponse * _Nullable installBrokerResponse);

@interface MSIDInteractiveTokenRequest : NSObject

@property (nonatomic, readonly, nonnull) MSIDInteractiveRequestParameters *requestParameters;
@property (nonatomic, readonly, nonnull) MSIDTokenResponseValidator *tokenResponseValidator;
@property (nonatomic, readonly, nonnull) id<MSIDCacheAccessor> tokenCache;
@property (nonatomic, readonly, nonnull) MSIDAccountMetadataCacheAccessor *accountMetadataCache;
@property (nonatomic, readonly, nonnull) MSIDOauth2Factory *oauthFactory;

#if TARGET_OS_OSX
@property (nonatomic, nullable) MSIDExternalAADCacheSeeder *externalCacheSeeder;
#endif

- (nullable instancetype)initWithRequestParameters:(nonnull MSIDInteractiveRequestParameters *)parameters
                                      oauthFactory:(nonnull MSIDOauth2Factory *)oauthFactory
                            tokenResponseValidator:(nonnull MSIDTokenResponseValidator *)tokenResponseValidator
                                        tokenCache:(nonnull id<MSIDCacheAccessor>)tokenCache
                             accountMetadataCache:(nullable MSIDAccountMetadataCacheAccessor *)accountMetadataCache;

- (void)executeRequestWithCompletion:(nonnull MSIDInteractiveRequestCompletionBlock)completionBlock;

@end
