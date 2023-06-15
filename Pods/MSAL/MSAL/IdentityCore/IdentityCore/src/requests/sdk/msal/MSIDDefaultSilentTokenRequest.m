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

#import "MSIDDefaultSilentTokenRequest.h"
#import "MSIDDefaultTokenCacheAccessor.h"
#import "MSIDRequestParameters.h"
#import "MSIDAuthority.h"
#import "MSIDTokenResult.h"
#import "MSIDAccessToken.h"
#import "MSIDIdToken.h"
#import "MSIDAccountIdentifier.h"
#import "MSIDAppMetadataCacheItem.h"
#import "MSIDRefreshToken.h"
#import "NSError+MSIDExtensions.h"
#import "MSIDConstants.h"
#import "MSIDConfiguration.h"
#import "MSIDAccountMetadataCacheAccessor.h"
#import "MSIDTokenResponse.h"
#import "MSIDThrottlingService.h"

@interface MSIDDefaultSilentTokenRequest()

@property (nonatomic) MSIDDefaultTokenCacheAccessor *defaultAccessor;
@property (nonatomic) MSIDAccountMetadataCacheAccessor *accountMetadataAccessor;
@property (nonatomic) MSIDAppMetadataCacheItem *appMetadata;

@end

@implementation MSIDDefaultSilentTokenRequest

#pragma mark - Init

- (nullable instancetype)initWithRequestParameters:(nonnull MSIDRequestParameters *)parameters
                                      forceRefresh:(BOOL)forceRefresh
                                      oauthFactory:(nonnull MSIDOauth2Factory *)oauthFactory
                            tokenResponseValidator:(nonnull MSIDTokenResponseValidator *)tokenResponseValidator
                                        tokenCache:(nonnull MSIDDefaultTokenCacheAccessor *)tokenCache
                             accountMetadataCache:(nonnull MSIDAccountMetadataCacheAccessor *)accountMetadataCache
{
    self = [super initWithRequestParameters:parameters
                               forceRefresh:forceRefresh
                               oauthFactory:oauthFactory
                     tokenResponseValidator:tokenResponseValidator];

    if (self)
    {
        _defaultAccessor = tokenCache;
        _accountMetadataAccessor = accountMetadataCache;
        self.throttlingService = [[MSIDThrottlingService alloc] initWithDataSource:_defaultAccessor.accountCredentialCache.dataSource context:parameters];
    }

    return self;
}

#pragma mark - Abstract impl

- (nullable MSIDAccessToken *)accessTokenWithError:(NSError **)error
{
    NSError *cacheError = nil;
    MSIDAccessToken *accessToken = [self.defaultAccessor getAccessTokenForAccount:self.requestParameters.accountIdentifier
                                                                    configuration:self.requestParameters.msidConfiguration
                                                                          context:self.requestParameters
                                                                            error:&cacheError];

    if (!accessToken && cacheError)
    {
        if (error)
        {
            *error = cacheError;
        }

        MSID_LOG_WITH_CTX_PII(MSIDLogLevelError, self.requestParameters, @"Access token lookup error %@", MSID_PII_LOG_MASKABLE(cacheError));
        return nil;
    }

    return accessToken;
}

- (nullable MSIDTokenResult *)resultWithAccessToken:(MSIDAccessToken *)accessToken
                                       refreshToken:(id<MSIDRefreshableToken>)refreshToken
                                              error:(__unused NSError * _Nullable * _Nullable)error
{
    if (!accessToken)
    {
        return nil;
    }

    NSError *cacheError = nil;

    MSIDIdToken *idToken = [self getIDToken:&cacheError];

    if (!idToken)
    {
        MSID_LOG_WITH_CTX(MSIDLogLevelError, self.requestParameters, @"Couldn't find an id token for clientId %@, authority %@", self.requestParameters.clientId, self.requestParameters.authority.url);
        if (error)
        {
            *error = MSIDCreateError(MSIDErrorDomain, MSIDErrorInternal, @"No id token matching request found", nil, nil, nil, nil, nil, NO);
        }
        
        return nil;
    }

    MSIDAccount *account = [self.defaultAccessor getAccountForIdentifier:self.requestParameters.accountIdentifier
                                                               authority:self.requestParameters.authority
                                                               realmHint:nil
                                                                 context:self.requestParameters
                                                                   error:&cacheError];

    if (!account)
    {
        MSID_LOG_WITH_CTX(MSIDLogLevelError,self.requestParameters, @"Couldn't find an account for clientId %@, authority %@", self.requestParameters.clientId, self.requestParameters.authority.url);

        if (error)
        {
            *error = MSIDCreateError(MSIDErrorDomain, MSIDErrorInternal, @"No account matching request found", nil, nil, nil, nil, nil, NO);
        }
        
        return nil;
    }
    
    MSIDTokenResult *result = [[MSIDTokenResult alloc] initWithAccessToken:accessToken
                                                              refreshToken:refreshToken
                                                                   idToken:idToken.rawIdToken
                                                                   account:account
                                                                 authority:self.requestParameters.msidConfiguration.authority
                                                             correlationId:self.requestParameters.correlationId
                                                             tokenResponse:nil];

    return result;
}

-(MSIDIdToken *)getIDToken:(NSError **)error
{
    return [self getIDTokenForTokenType:MSIDIDTokenType error:error];
}

-(MSIDIdToken *)getIDTokenForTokenType:(MSIDCredentialType)idTokenType
                                 error:(NSError **)error
{
    return [self.defaultAccessor getIDTokenForAccount:self.requestParameters.accountIdentifier
                                        configuration:self.requestParameters.msidConfiguration
                                          idTokenType:idTokenType
                                              context:self.requestParameters
                                                error:error];
}

- (nullable MSIDRefreshToken *)familyRefreshTokenWithError:(NSError * _Nullable * _Nullable)error
{
    self.appMetadata = [self appMetadataWithError:error];

    //On first network try, app metadata will be nil but on every subsequent attempt, it should reflect if clientId is part of family
    NSString *familyId = self.appMetadata ? self.appMetadata.familyId : MSID_DEFAULT_FAMILY_ID;

    if (![NSString msidIsStringNilOrBlank:familyId])
    {
        return [self.defaultAccessor getRefreshTokenWithAccount:self.requestParameters.accountIdentifier
                                                       familyId:familyId
                                                  configuration:self.requestParameters.msidConfiguration
                                                        context:self.requestParameters
                                                          error:error];
    }

    return nil;
}

- (nullable MSIDBaseToken<MSIDRefreshableToken> *)appRefreshTokenWithError:(NSError * _Nullable * _Nullable)error
{
    return [self.defaultAccessor getRefreshTokenWithAccount:self.requestParameters.accountIdentifier
                                                   familyId:nil
                                              configuration:self.requestParameters.msidConfiguration
                                                    context:self.requestParameters
                                                      error:error];
}

- (BOOL)updateFamilyIdCacheWithServerError:(NSError *)serverError
                                cacheError:(NSError **)cacheError
{
    //When FRT is used by client which is not part of family, the server returns "client_mismatch" as sub-error
    NSString *subError = serverError.msidSubError;
    if (subError && [subError isEqualToString:MSIDServerErrorClientMismatch])
    {
        BOOL result = [self.defaultAccessor updateAppMetadataWithFamilyId:@""
                                                                 clientId:self.requestParameters.msidConfiguration.clientId
                                                                authority:self.requestParameters.msidConfiguration.authority
                                                                  context:self.requestParameters
                                                                    error:cacheError];


        //reset family id if set in app's metadata
        if (!result)
        {
            MSID_LOG_WITH_CTX(MSIDLogLevelWarning,self.requestParameters, @"Failed to update app metadata");
        }
    }

    return YES;
}

- (BOOL)shouldRemoveRefreshToken:(NSError *)serverError
{
    // MSAL removes RTs on invalid_grant + bad token combination
    MSIDErrorCode oauthError = MSIDErrorCodeForOAuthError(serverError.msidOauthError, MSIDErrorInternal);
    NSString *subError = serverError.msidSubError;
    return oauthError == MSIDErrorServerInvalidGrant && [subError isEqualToString:MSIDServerErrorBadToken];
}

- (id<MSIDCacheAccessor>)tokenCache
{
    return self.defaultAccessor;
}

- (MSIDAccountMetadataCacheAccessor *)metadataCache
{
    return self.accountMetadataAccessor;
}

#pragma mark - Helpers

- (MSIDAppMetadataCacheItem *)appMetadataWithError:(NSError * _Nullable * _Nullable)error
{
    NSError *cacheError = nil;
    NSArray<MSIDAppMetadataCacheItem *> *appMetadataEntries = [self.defaultAccessor getAppMetadataEntries:self.requestParameters.msidConfiguration
                                                                                                  context:self.requestParameters
                                                                                                    error:&cacheError];

    if (cacheError)
    {
        if (error)
        {
            *error = cacheError;
        }

        MSID_LOG_WITH_CTX_PII(MSIDLogLevelError, self.requestParameters, @"Failed reading app metadata with error %@", MSID_PII_LOG_MASKABLE(cacheError));
        return nil;
    }

    return appMetadataEntries.firstObject;
}

@end
