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

#import "MSIDSilentTokenRequest.h"
#import "MSIDProviderType.h"

@class MSIDAccountMetadataCacheAccessor;

NS_ASSUME_NONNULL_BEGIN

API_AVAILABLE(ios(13.0), macos(10.15))
@interface MSIDSSOExtensionSilentTokenRequest : MSIDSilentTokenRequest

@property (nonatomic, readonly, nonnull) id<MSIDCacheAccessor> tokenCache;

- (nullable instancetype)initWithRequestParameters:(MSIDRequestParameters *)parameters
                                      forceRefresh:(BOOL)forceRefresh
                                      oauthFactory:(MSIDOauth2Factory *)oauthFactory
                            tokenResponseValidator:(MSIDTokenResponseValidator *)tokenResponseValidator NS_UNAVAILABLE;

- (nullable instancetype)initWithRequestParameters:(MSIDRequestParameters *)parameters
                                      forceRefresh:(BOOL)forceRefresh
                                      oauthFactory:(MSIDOauth2Factory *)oauthFactory
                            tokenResponseValidator:(MSIDTokenResponseValidator *)tokenResponseValidator
                                        tokenCache:(id<MSIDCacheAccessor>)tokenCache
                              accountMetadataCache:(nullable MSIDAccountMetadataCacheAccessor *)accountMetadataCache
                                extendedTokenCache:(nullable id<MSIDExtendedTokenCacheDataSource>)extendedTokenCache NS_DESIGNATED_INITIALIZER;

@end

NS_ASSUME_NONNULL_END
