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

#import "MSIDTokenResponseValidator.h"
#import "MSIDRequestParameters.h"
#import "MSIDOauth2Factory.h"
#import "MSIDTokenResult.h"
#import "MSIDTokenResponse.h"
#import "MSIDBrokerResponse.h"
#import "MSIDAccessToken.h"
#import "MSIDRefreshToken.h"
#import "MSIDBasicContext.h"
#import "MSIDAccountMetadataCacheAccessor.h"
#import "MSIDAccountIdentifier.h"
#import "MSIDIntuneApplicationStateManager.h"

@implementation MSIDTokenResponseValidator

- (MSIDTokenResult *)validateTokenResponse:(MSIDTokenResponse *)tokenResponse
                              oauthFactory:(MSIDOauth2Factory *)factory
                             configuration:(MSIDConfiguration *)configuration
                            requestAccount:(__unused MSIDAccountIdentifier *)accountIdentifier
                             correlationID:(NSUUID *)correlationID
                                     error:(NSError **)error
{
    if (!tokenResponse)
    {
        MSIDFillAndLogError(error, MSIDErrorInternal, @"Token response is nil", correlationID);
        return nil;
    }

    MSIDBasicContext *context = [MSIDBasicContext new];
    context.correlationId = correlationID;
    NSError *verificationError = nil;
    if (![factory verifyResponse:tokenResponse context:context error:&verificationError])
    {
        if (error)
        {
            *error = verificationError;
        }

        MSID_LOG_WITH_CORR_PII(MSIDLogLevelWarning, correlationID, @"Unsuccessful token response, error %@", MSID_PII_LOG_MASKABLE(verificationError));

        return nil;
    }
    
    return [self createTokenResultFromResponse:tokenResponse
                                  oauthFactory:factory
                                 configuration:configuration
                                requestAccount:accountIdentifier
                                 correlationID:correlationID
                                         error:error];
}

- (MSIDTokenResult *)createTokenResultFromResponse:(MSIDTokenResponse *)tokenResponse
                                      oauthFactory:(MSIDOauth2Factory *)factory
                                     configuration:(MSIDConfiguration *)configuration
                                    requestAccount:(__unused MSIDAccountIdentifier *)accountIdentifier
                                     correlationID:(NSUUID *)correlationID
                                             error:(NSError **)error

{
    MSIDAccessToken *accessToken = [factory accessTokenFromResponse:tokenResponse configuration:configuration];
    MSIDRefreshToken *refreshToken = [factory refreshTokenFromResponse:tokenResponse configuration:configuration];
    
    MSIDAccount *account = [factory accountFromResponse:tokenResponse configuration:configuration];
    NSError *authorityError = nil;
    MSIDAuthority *resultAuthority = [factory resultAuthorityWithConfiguration:configuration tokenResponse:tokenResponse error:&authorityError];
    
    if (!resultAuthority)
    {
        MSID_LOG_WITH_CORR(MSIDLogLevelError, correlationID, @"Failed to create authority with error %@, %ld", authorityError.domain, (long)authorityError.code);
        
        if (error)
        {
            *error = authorityError;
        }
        
        return nil;
    }
    
    MSIDTokenResult *result = [[MSIDTokenResult alloc] initWithAccessToken:accessToken
                                                              refreshToken:refreshToken
                                                                   idToken:tokenResponse.idToken
                                                                   account:account
                                                                 authority:resultAuthority
                                                             correlationId:correlationID
                                                             tokenResponse:tokenResponse];
    
    return result;
}

- (BOOL)validateTokenResult:(__unused MSIDTokenResult *)tokenResult
              configuration:(__unused MSIDConfiguration *)configuration
                  oidcScope:(__unused NSString *)oidcScope
              correlationID:(__unused NSUUID *)correlationID
                      error:(__unused NSError **)error
{
    // Post saving validation
    return YES;
}

- (BOOL)validateAccount:(__unused MSIDAccountIdentifier *)accountIdentifier
            tokenResult:(__unused MSIDTokenResult *)tokenResult
          correlationID:(__unused NSUUID *)correlationID
                  error:(__unused NSError *__autoreleasing  _Nullable *)error
{
    return YES;
}

- (MSIDTokenResult *)validateAndSaveBrokerResponse:(MSIDBrokerResponse *)brokerResponse
                                         oidcScope:(NSString *)oidcScope
                                      oauthFactory:(MSIDOauth2Factory *)factory
                                        tokenCache:(id<MSIDCacheAccessor>)tokenCache
                                     correlationID:(NSUUID *)correlationID
                                             error:(NSError **)error
{
    MSID_LOG_WITH_CORR(MSIDLogLevelInfo, correlationID, @"Validating broker response.");
    
    if (!brokerResponse)
    {
        MSIDFillAndLogError(error, MSIDErrorInternal, @"Broker response is nil", correlationID);
        return nil;
    }
    
    if (!brokerResponse.msidAuthority)
    {
        if (error)
        {
            *error = MSIDCreateError(MSIDErrorDomain, MSIDErrorInvalidInternalParameter, @"No authority returned from broker", nil, nil, nil, correlationID, nil, YES);
        }
        
        return nil;
    }

    MSIDConfiguration *configuration = [[MSIDConfiguration alloc] initWithAuthority:brokerResponse.msidAuthority
                                                                        redirectUri:nil
                                                                           clientId:brokerResponse.clientId
                                                                             target:brokerResponse.target];
    
    configuration.applicationIdentifier = [MSIDIntuneApplicationStateManager intuneApplicationIdentifierForAuthority:brokerResponse.msidAuthority
                                                                                                       appIdentifier:[[NSBundle mainBundle] bundleIdentifier]];

    MSIDTokenResponse *tokenResponse = brokerResponse.tokenResponse;
    MSIDTokenResult *tokenResult = [self validateTokenResponse:tokenResponse
                                                  oauthFactory:factory
                                                 configuration:configuration
                                                requestAccount:nil
                                                 correlationID:[[NSUUID alloc] initWithUUIDString:brokerResponse.correlationId]
                                                         error:error];

    if (!tokenResult)
    {
        MSID_LOG_WITH_CORR(MSIDLogLevelInfo, correlationID, @"Broker response is not valid.");
        return nil;
    }
    MSID_LOG_WITH_CORR(MSIDLogLevelInfo, correlationID, @"Broker response is valid.");

    BOOL shouldSaveSSOStateOnly = brokerResponse.accessTokenInvalidForResponse;
    MSID_LOG_WITH_CORR(MSIDLogLevelInfo, correlationID, @"Saving broker response, only save SSO state %d", shouldSaveSSOStateOnly);

    NSError *savingError = nil;
    BOOL isSaved = NO;

    if (shouldSaveSSOStateOnly)
    {
        isSaved = [tokenCache saveSSOStateWithConfiguration:configuration
                                                   response:tokenResponse
                                                    factory:factory
                                                    context:nil
                                                      error:&savingError];
    }
    else
    {
        isSaved = [tokenCache saveTokensWithConfiguration:configuration
                                                 response:tokenResponse
                                                  factory:factory
                                                  context:nil
                                                    error:&savingError];
    }

    if (!isSaved)
    {
        MSID_LOG_WITH_CORR_PII(MSIDLogLevelError, correlationID, @"Failed to save tokens in cache. Error %@", MSID_PII_LOG_MASKABLE(savingError));
    }
    else
    {
        MSID_LOG_WITH_CORR(MSIDLogLevelInfo, correlationID, @"Saved broker response.");
    }

    MSID_LOG_WITH_CORR(MSIDLogLevelInfo, correlationID, @"Validating token result.");
    BOOL resultValid = [self validateTokenResult:tokenResult
                                   configuration:configuration
                                       oidcScope:oidcScope
                                   correlationID:correlationID
                                           error:error];

    if (!resultValid)
    {
        MSID_LOG_WITH_CORR(MSIDLogLevelInfo, correlationID, @"Token result is invalid.");
        return nil;
    }
    MSID_LOG_WITH_CORR(MSIDLogLevelInfo, correlationID, @"Token result is valid.");

    tokenResult.brokerAppVersion = brokerResponse.brokerAppVer;
    return tokenResult;
}


- (MSIDTokenResult *)validateAndSaveTokenResponse:(MSIDTokenResponse *)tokenResponse
                                     oauthFactory:(MSIDOauth2Factory *)factory
                                       tokenCache:(id<MSIDCacheAccessor>)tokenCache
                             accountMetadataCache:(MSIDAccountMetadataCacheAccessor *)accountMetadataCache
                                requestParameters:(MSIDRequestParameters *)parameters
                                            error:(NSError **)error
{
    MSIDTokenResult *tokenResult = [self validateTokenResponse:tokenResponse
                                                  oauthFactory:factory
                                                 configuration:parameters.msidConfiguration
                                                requestAccount:parameters.accountIdentifier
                                                 correlationID:parameters.correlationId
                                                         error:error];

    if (!tokenResult)
    {
        return nil;
    }
    
    //save metadata
    NSError *updateMetadataError = nil;
    MSIDAuthority *resultingAuthority = [factory resultAuthorityWithConfiguration:parameters.msidConfiguration tokenResponse:tokenResponse error:&updateMetadataError];
    if (resultingAuthority && !updateMetadataError)
    {
        MSIDAuthority *providedAuthority = parameters.providedAuthority ?: parameters.authority;
        [accountMetadataCache updateAuthorityURL:resultingAuthority.url
                                   forRequestURL:providedAuthority.url
                                   homeAccountId:tokenResult.account.accountIdentifier.homeAccountId
                                        clientId:parameters.clientId
                                   instanceAware:parameters.instanceAware
                                         context:parameters
                                           error:&updateMetadataError];
        
        if (updateMetadataError)
        {
            MSID_LOG_WITH_CTX(MSIDLogLevelError, parameters, @"Failed to update auhtority map in cache. Error %@", MSID_PII_LOG_MASKABLE(updateMetadataError));
        }
    }

    NSError *savingError = nil;
    BOOL isSaved = [tokenCache saveTokensWithConfiguration:parameters.msidConfiguration
                                                  response:tokenResponse
                                                   factory:factory
                                                   context:parameters
                                                     error:&savingError];

    if (!isSaved)
    {
        MSID_LOG_WITH_CTX(MSIDLogLevelError, parameters, @"Failed to save tokens in cache. Error %@", MSID_PII_LOG_MASKABLE(savingError));
    }

    BOOL resultValid = [self validateTokenResult:tokenResult
                                   configuration:parameters.msidConfiguration
                                       oidcScope:parameters.oidcScope
                                   correlationID:parameters.correlationId
                                           error:error];

    if (!resultValid)
    {
        return nil;
    }

    return tokenResult;
}


@end
