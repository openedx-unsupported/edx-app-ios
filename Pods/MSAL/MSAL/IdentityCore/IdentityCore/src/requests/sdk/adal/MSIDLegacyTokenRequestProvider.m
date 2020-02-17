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

#import "MSIDLegacyTokenRequestProvider.h"
#import "MSIDInteractiveTokenRequest.h"
#import "MSIDLegacyTokenResponseValidator.h"
#import "MSIDLegacySilentTokenRequest.h"
#import "MSIDLegacyBrokerTokenRequest.h"
#import "MSIDLegacyTokenCacheAccessor.h"

@interface MSIDLegacyTokenRequestProvider()

@property (nonatomic) MSIDOauth2Factory *oauthFactory;
@property (nonatomic) MSIDLegacyTokenCacheAccessor *tokenCache;

@end

@implementation MSIDLegacyTokenRequestProvider

#pragma mark - Init

- (instancetype)initWithOauthFactory:(MSIDOauth2Factory *)oauthFactory
                      legacyAccessor:(MSIDLegacyTokenCacheAccessor *)legacyAccessor
{
    self = [super init];

    if (self)
    {
        _oauthFactory = oauthFactory;
        _tokenCache = legacyAccessor;
    }

    return self;
}

#pragma mark - MSIDTokenRequestProviding

- (MSIDInteractiveTokenRequest *)interactiveTokenRequestWithParameters:(MSIDInteractiveRequestParameters *)parameters
{
    return [[MSIDInteractiveTokenRequest alloc] initWithRequestParameters:parameters
                                                             oauthFactory:self.oauthFactory
                                                   tokenResponseValidator:[MSIDLegacyTokenResponseValidator new]
                                                               tokenCache:self.tokenCache
                                                    accountMetadataCache:nil];
}

- (MSIDSilentTokenRequest *)silentTokenRequestWithParameters:(MSIDRequestParameters *)parameters
                                                forceRefresh:(BOOL)forceRefresh
{
    return [[MSIDLegacySilentTokenRequest alloc] initWithRequestParameters:parameters
                                                              forceRefresh:forceRefresh
                                                              oauthFactory:self.oauthFactory
                                                    tokenResponseValidator:[MSIDLegacyTokenResponseValidator new]
                                                                tokenCache:self.tokenCache];
}

- (nullable MSIDBrokerTokenRequest *)brokerTokenRequestWithParameters:(nonnull MSIDInteractiveRequestParameters *)parameters
                                                            brokerKey:(nonnull NSString *)brokerKey
                                               brokerApplicationToken:(NSString * _Nullable )brokerApplicationToken
                                                                error:(NSError * _Nullable * _Nullable)error
{
    return [[MSIDLegacyBrokerTokenRequest alloc] initWithRequestParameters:parameters
                                                                 brokerKey:brokerKey
                                                    brokerApplicationToken:brokerApplicationToken
                                                                     error:error];
}


@end
