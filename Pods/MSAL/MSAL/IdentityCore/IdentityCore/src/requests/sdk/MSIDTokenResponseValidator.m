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
#import "MSIDAuthenticationScheme.h"
#import "MSIDAuthScheme.h"

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
    // Verify if the auth scheme from server's response match with the request
    NSString *tokenType = [tokenResponse.tokenType lowercaseString];
    MSIDAuthScheme scheme = configuration.authScheme.authScheme;
    NSString *tokenTypeFromConfiguration = [MSIDAuthSchemeParamFromType(scheme) lowercaseString];
    if (![NSString msidIsStringNilOrBlank:tokenType] && ![tokenType isEqualToString:tokenTypeFromConfiguration])
    {
        MSIDFillAndLogError(error, MSIDErrorServerInvalidResponse, @"Please update Microsoft Authenticator to the latest version. Pop tokens are not supported with this broker version.", correlationID);
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
                                  requestAuthority:(NSURL *)requestAuthority
                                     instanceAware:(BOOL)instanceAware
                                      oauthFactory:(MSIDOauth2Factory *)factory
                                        tokenCache:(id<MSIDCacheAccessor>)tokenCache
                              accountMetadataCache:(MSIDAccountMetadataCacheAccessor *)accountMetadataCache
                                     correlationID:(NSUUID *)correlationID
                                  saveSSOStateOnly:(BOOL)saveSSOStateOnly
                                        authScheme:(MSIDAuthenticationScheme *)authScheme
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
    
    configuration.authScheme = authScheme;
    
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
    
    [self saveTokenResponseToCache:tokenResponse
                     configuration:configuration
                      oauthFactory:factory
                        tokenCache:tokenCache
                  saveSSOStateOnly:saveSSOStateOnly
                           context:nil
                             error:nil];
    
    //save metadata
    NSError *authorityError;
    MSIDAuthority *resultingAuthority = [factory resultAuthorityWithConfiguration:configuration tokenResponse:tokenResponse error:&authorityError];
    if (authorityError)
    {
        MSID_LOG_WITH_CTX(MSIDLogLevelError, nil, @"Failed to create resulting authority for metadata update. Error %@", MSID_PII_LOG_MASKABLE(authorityError));
    }
    [self updateAccountMetadataForHomeAccountId:tokenResult.account.accountIdentifier.homeAccountId
                                       clientId:configuration.clientId
                                  instanceAware:instanceAware
                                          state:MSIDAccountMetadataStateSignedIn
                               requestAuthority:requestAuthority
                             resultingAuthority:resultingAuthority.url
                           accountMetadataCache:accountMetadataCache
                                        context:nil];

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
                                 saveSSOStateOnly:(BOOL)saveSSOStateOnly
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
    NSError *authorityError;
    MSIDAuthority *resultingAuthority = [factory resultAuthorityWithConfiguration:parameters.msidConfiguration tokenResponse:tokenResponse error:&authorityError];
    if (authorityError)
    {
        MSID_LOG_WITH_CTX(MSIDLogLevelError, parameters, @"Failed to create resulting authority for metadata update. Error %@", MSID_PII_LOG_MASKABLE(authorityError));
    }
    MSIDAuthority *providedAuthority = parameters.providedAuthority ?: parameters.authority;
    [self updateAccountMetadataForHomeAccountId:tokenResult.account.accountIdentifier.homeAccountId
                                       clientId:parameters.clientId
                                  instanceAware:parameters.instanceAware
                                          state:MSIDAccountMetadataStateSignedIn
                               requestAuthority:providedAuthority.url
                             resultingAuthority:resultingAuthority.url
                           accountMetadataCache:accountMetadataCache
                                        context:parameters];
    
    // Note, if there's an error saving result, we log it, but we don't fail validation
    // This is by design because even if we fail to cache, we still should return tokens back to the app
    [self saveTokenResponseToCache:tokenResponse
                     configuration:parameters.msidConfiguration
                      oauthFactory:factory
                        tokenCache:tokenCache
                  saveSSOStateOnly:saveSSOStateOnly
                           context:parameters
                             error:nil];

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

#pragma mark - Internal

- (BOOL)saveTokenResponseToCache:(MSIDTokenResponse *)tokenResponse
                   configuration:(MSIDConfiguration *)configuration
                    oauthFactory:(MSIDOauth2Factory *)factory
                      tokenCache:(id<MSIDCacheAccessor>)tokenCache
                saveSSOStateOnly:(BOOL)saveSSOStateOnly
                         context:(id<MSIDRequestContext>)context
                           error:(NSError **)error
{
    MSID_LOG_WITH_CTX(MSIDLogLevelInfo, context, @"Saving token response, only save SSO state %d", saveSSOStateOnly);
    
    NSError *savingError;
    BOOL isSaved = NO;

    if (saveSSOStateOnly)
    {
        isSaved = [tokenCache saveSSOStateWithConfiguration:configuration
                                                   response:tokenResponse
                                                    factory:factory
                                                    context:context
                                                      error:&savingError];
    }
    else
    {
        isSaved = [tokenCache saveTokensWithConfiguration:configuration
                                                 response:tokenResponse
                                                  factory:factory
                                                  context:context
                                                    error:&savingError];
    }

    if (!isSaved)
    {
        MSID_LOG_WITH_CTX(MSIDLogLevelError, context, @"Failed to save tokens in cache. Error %@", MSID_PII_LOG_MASKABLE(savingError));
        if (error) *error = savingError;
    }
    else
    {
        MSID_LOG_WITH_CTX(MSIDLogLevelVerbose, context, @"Saved token response successfully.");
    }
    
    return isSaved;
}

- (void)updateAccountMetadataForHomeAccountId:(NSString *)homeAccountId
                                     clientId:(NSString *)clientId
                                instanceAware:(BOOL)instanceAware
                                        state:(MSIDAccountMetadataState)state
                             requestAuthority:(NSURL *)requestAuthority
                           resultingAuthority:(NSURL *)resultingAuthority
                         accountMetadataCache:(MSIDAccountMetadataCacheAccessor *)accountMetadataCache
                                      context:(id<MSIDRequestContext>)context
{
    //save metadata
    NSError *updateMetadataError = nil;
    [accountMetadataCache updateSignInStateForHomeAccountId:homeAccountId
                                                   clientId:clientId
                                                      state:state
                                                    context:context
                                                      error:&updateMetadataError];
    if (updateMetadataError)
    {
        MSID_LOG_WITH_CTX(MSIDLogLevelError, context, @"Failed to update sign in state in metadata cache. Error %@", MSID_PII_LOG_MASKABLE(updateMetadataError));
    }
    
    
    if (requestAuthority && resultingAuthority)
    {
        [accountMetadataCache updateAuthorityURL:resultingAuthority
                                   forRequestURL:requestAuthority
                                   homeAccountId:homeAccountId
                                        clientId:clientId
                                   instanceAware:instanceAware
                                         context:context
                                           error:&updateMetadataError];
        
        if (updateMetadataError)
        {
            MSID_LOG_WITH_CTX(MSIDLogLevelError, context, @"Failed to update auhtority map in cache. Error %@", MSID_PII_LOG_MASKABLE(updateMetadataError));
        }
    }
}

@end
