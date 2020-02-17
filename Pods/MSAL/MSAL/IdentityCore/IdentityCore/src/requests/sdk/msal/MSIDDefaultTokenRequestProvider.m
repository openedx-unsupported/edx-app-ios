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

#import "MSIDDefaultTokenRequestProvider.h"
#import "MSIDInteractiveTokenRequest.h"
#import "MSIDDefaultTokenResponseValidator.h"
#import "MSIDDefaultSilentTokenRequest.h"
#import "MSIDDefaultTokenCacheAccessor.h"
#import "MSIDDefaultBrokerTokenRequest.h"
#import "MSIDDefaultTokenRequestProvider+Internal.h"

@implementation MSIDDefaultTokenRequestProvider

- (nullable instancetype)initWithOauthFactory:(MSIDOauth2Factory *)oauthFactory
                              defaultAccessor:(MSIDDefaultTokenCacheAccessor *)defaultAccessor
                      accountMetadataAccessor:(MSIDAccountMetadataCacheAccessor *)accountMetadataAccessor
                       tokenResponseValidator:(MSIDTokenResponseValidator *)tokenResponseValidator
{
    self = [super init];

    if (self)
    {
        _oauthFactory = oauthFactory;
        _tokenCache = defaultAccessor;
        _accountMetadataCache = accountMetadataAccessor;
        _tokenResponseValidator = tokenResponseValidator;
    }

    return self;
}

- (MSIDInteractiveTokenRequest *)interactiveTokenRequestWithParameters:(MSIDInteractiveRequestParameters *)parameters
{
    __auto_type request = [[MSIDInteractiveTokenRequest alloc] initWithRequestParameters:parameters
                                                                            oauthFactory:self.oauthFactory
                                                                  tokenResponseValidator:self.tokenResponseValidator
                                                                              tokenCache:self.tokenCache
                                                                    accountMetadataCache:self.accountMetadataCache];
#if TARGET_OS_OSX
    request.externalCacheSeeder = self.externalCacheSeeder;
#endif
    
    return request;
}

- (MSIDSilentTokenRequest *)silentTokenRequestWithParameters:(MSIDRequestParameters *)parameters
                                                forceRefresh:(BOOL)forceRefresh
{
    __auto_type request = [[MSIDDefaultSilentTokenRequest alloc] initWithRequestParameters:parameters
                                                                              forceRefresh:forceRefresh
                                                                              oauthFactory:self.oauthFactory
                                                                    tokenResponseValidator:self.tokenResponseValidator
                                                                                tokenCache:self.tokenCache
                                                                      accountMetadataCache:self.accountMetadataCache];
    
#if TARGET_OS_OSX
    request.externalCacheSeeder = self.externalCacheSeeder;
#endif
    
    return request;
}

- (nullable MSIDBrokerTokenRequest *)brokerTokenRequestWithParameters:(nonnull MSIDInteractiveRequestParameters *)parameters
                                                            brokerKey:(nonnull NSString *)brokerKey
                                               brokerApplicationToken:(NSString * _Nullable )brokerApplicationToken
                                                                error:(NSError * _Nullable * _Nullable)error
{
    return [[MSIDDefaultBrokerTokenRequest alloc] initWithRequestParameters:parameters
                                                                  brokerKey:brokerKey
                                                     brokerApplicationToken:brokerApplicationToken
                                                                      error:error];
}

@end
