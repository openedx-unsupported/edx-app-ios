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

#import "MSIDLegacySilentTokenRequest.h"
#import "MSIDLegacyTokenCacheAccessor.h"
#import "MSIDAccessToken.h"
#import "NSError+MSIDExtensions.h"
#import "MSIDAccountMetadataCacheAccessor.h"

@interface MSIDLegacySilentTokenRequest()

@property (nonatomic) MSIDLegacyTokenCacheAccessor *legacyAccessor;

@end

@implementation MSIDLegacySilentTokenRequest

#pragma mark - Init

- (nullable instancetype)initWithRequestParameters:(nonnull MSIDRequestParameters *)parameters
                                      forceRefresh:(BOOL)forceRefresh
                                      oauthFactory:(nonnull MSIDOauth2Factory *)oauthFactory
                            tokenResponseValidator:(nonnull MSIDTokenResponseValidator *)tokenResponseValidator
                                        tokenCache:(nonnull MSIDLegacyTokenCacheAccessor *)tokenCache
{
    self = [super initWithRequestParameters:parameters
                               forceRefresh:forceRefresh
                               oauthFactory:oauthFactory
                     tokenResponseValidator:tokenResponseValidator];

    if (self)
    {
        _legacyAccessor = tokenCache;
    }

    return self;
}

#pragma mark - Abstract impl

- (nullable MSIDAccessToken *)accessTokenWithError:(__unused NSError **)error
{
    // TODO: ADAL pieces
    return nil;
}

- (nullable MSIDTokenResult *)resultWithAccessToken:(__unused MSIDAccessToken *)accessToken
                                       refreshToken:(__unused id<MSIDRefreshableToken>)refreshToken
                                              error:(__unused NSError * _Nullable * _Nullable)error
{
    // TODO: ADAL pieces
    return nil;
}

- (nullable MSIDRefreshToken *)familyRefreshTokenWithError:(__unused NSError * _Nullable * _Nullable)error
{
    // TODO: ADAL pieces
    return nil;
}

- (nullable MSIDBaseToken<MSIDRefreshableToken> *)appRefreshTokenWithError:(__unused NSError * _Nullable * _Nullable)error
{
    // TODO: ADAL pieces
    return nil;
}

- (BOOL)updateFamilyIdCacheWithServerError:(__unused NSError *)serverError
                                cacheError:(__unused NSError **)cacheError
{
    // TODO: ADAL pieces
    return NO;
}

- (BOOL)shouldRemoveRefreshToken:(NSError *)serverError
{
    // ADAL removes RTs on invalid_grant
    MSIDErrorCode oauthError = MSIDErrorCodeForOAuthError(serverError.msidOauthError, MSIDErrorInternal);
    return oauthError == MSIDErrorServerInvalidGrant;
}

- (id<MSIDCacheAccessor>)tokenCache
{
    return self.legacyAccessor;
}

- (MSIDAccountMetadataCacheAccessor *)metadataCache
{
    return nil;
}

@end
