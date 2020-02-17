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
#import "MSIDRequestParameters.h"
#import "MSIDAccessToken.h"
#import "MSIDTokenResponseValidator.h"
#import "MSIDAccountIdentifier.h"
#import "MSIDRefreshTokenGrantRequest.h"
#import "MSIDRefreshToken.h"
#import "MSIDAuthority.h"
#import "MSIDOauth2Factory.h"
#import "MSIDTokenResult.h"
#import "NSError+MSIDExtensions.h"
#import "MSIDClaimsRequest.h"
#import "MSIDIntuneApplicationStateManager.h"
#import "MSIDConfiguration.h"
#import "MSIDIntuneEnrollmentIdsCache.h"

#if TARGET_OS_OSX
#import "MSIDExternalAADCacheSeeder.h"
#endif

@interface MSIDSilentTokenRequest()

@property (nonatomic, readwrite) MSIDRequestParameters *requestParameters;
@property (nonatomic) BOOL forceRefresh;
@property (nonatomic, readwrite) MSIDOauth2Factory *oauthFactory;
@property (nonatomic, readwrite) MSIDTokenResponseValidator *tokenResponseValidator;
@property (nonatomic, readwrite) MSIDAccessToken *extendedLifetimeAccessToken;

@end

@implementation MSIDSilentTokenRequest

- (nullable instancetype)initWithRequestParameters:(nonnull MSIDRequestParameters *)parameters
                                      forceRefresh:(BOOL)forceRefresh
                                      oauthFactory:(nonnull MSIDOauth2Factory *)oauthFactory
                            tokenResponseValidator:(nonnull MSIDTokenResponseValidator *)tokenResponseValidator
{
    self = [super init];

    if (self)
    {
        _requestParameters = parameters;
        _forceRefresh = forceRefresh;
        _oauthFactory = oauthFactory;
        _tokenResponseValidator = tokenResponseValidator;
    }

    return self;
}

- (void)executeRequestWithCompletion:(MSIDRequestCompletionBlock)completionBlock
{
    if (!self.requestParameters.accountIdentifier)
    {
        MSID_LOG_WITH_CTX(MSIDLogLevelError, self.requestParameters, @"Account parameter cannot be nil");

        NSError *error = MSIDCreateError(MSIDErrorDomain, MSIDErrorMissingAccountParameter, @"Account parameter cannot be nil", nil, nil, nil, self.requestParameters.correlationId, nil, NO);
        completionBlock(nil, error);
        return;
    }

    NSString *upn = self.requestParameters.accountIdentifier.displayableId;

    [self.requestParameters.authority resolveAndValidate:self.requestParameters.validateAuthority
                                       userPrincipalName:upn
                                                 context:self.requestParameters
                                         completionBlock:^(__unused NSURL *openIdConfigurationEndpoint, 
                                         __unused BOOL validated, NSError *error)
     {
         if (error)
         {
             completionBlock(nil, error);
             return;
         }

         [self executeRequestImpl:completionBlock];
     }];
}

- (void)executeRequestImpl:(MSIDRequestCompletionBlock)completionBlock
{
    if (!self.forceRefresh && ![self.requestParameters.claimsRequest hasClaims])
    {
        NSError *accessTokenError = nil;
        
        MSID_LOG_WITH_CTX(MSIDLogLevelInfo, self.requestParameters, @"Looking for access token...");
        MSIDAccessToken *accessToken = [self accessTokenWithError:&accessTokenError];

        if (accessTokenError)
        {
            completionBlock(nil, accessTokenError);
            return;
        }

        BOOL enrollmentIdMatch = YES;
        
        // If token is scoped down to a particular enrollmentId and app is capable for True MAM CA, verify that enrollmentIds match
        // EnrollmentID matching is done on the request layer to ensure that expired access tokens get removed even if valid enrollmentId is not presented
        if ([MSIDIntuneApplicationStateManager isAppCapableForMAMCA:self.requestParameters.msidConfiguration.authority]
            && ![NSString msidIsStringNilOrBlank:accessToken.enrollmentId])
        {
            NSError *error = nil;
            
            NSString *currentEnrollmentId = [[MSIDIntuneEnrollmentIdsCache sharedCache] enrollmentIdForHomeAccountId:accessToken.accountIdentifier.homeAccountId
                                                                                                        legacyUserId:accessToken.accountIdentifier.displayableId
                                                                                                             context:self.requestParameters
                                                                                                               error:&error];
            
            if (error)
            {
                MSID_LOG_WITH_CTX(MSIDLogLevelWarning, self.requestParameters, @"Failed to read current enrollment ID with error %@", MSID_PII_LOG_MASKABLE(error));
            }
            
            enrollmentIdMatch = currentEnrollmentId && [currentEnrollmentId isEqualToString:accessToken.enrollmentId];
        }
        
        if (accessToken && ![accessToken isExpiredWithExpiryBuffer:self.requestParameters.tokenExpirationBuffer] && enrollmentIdMatch)
        {
            MSID_LOG_WITH_CTX(MSIDLogLevelInfo, self.requestParameters, @"Found valid access token.");
            NSError *rtError = nil;
            
            // Trying to find FRT first.
            MSID_LOG_WITH_CTX(MSIDLogLevelInfo, self.requestParameters, @"Looking for family refresh token...");
            id<MSIDRefreshableToken> refreshableToken = [self familyRefreshTokenWithError:&rtError];
            
            if (!refreshableToken)
            {
                MSID_LOG_WITH_CTX_PII(MSIDLogLevelWarning, self.requestParameters, @"Didn't find family refresh token with error: %@", MSID_PII_LOG_MASKABLE(rtError));
            }
            else
            {
                MSID_LOG_WITH_CTX(MSIDLogLevelInfo, self.requestParameters, @"Found family refresh token.");
            }
            
            // If no FRT, get refresh token instead.
            if (!refreshableToken)
            {
                MSID_LOG_WITH_CTX(MSIDLogLevelInfo, self.requestParameters, @"Looking for app refresh token...");
                refreshableToken = [self appRefreshTokenWithError:&rtError];
                
                if (!refreshableToken)
                {
                    MSID_LOG_WITH_CTX_PII(MSIDLogLevelWarning, self.requestParameters, @"Didn't find app refresh token with error: %@", MSID_PII_LOG_MASKABLE(rtError));
                }
                else
                {
                    MSID_LOG_WITH_CTX(MSIDLogLevelInfo, self.requestParameters, @"Found app refresh token.");
                }
            }

            NSError *resultError = nil;
            MSIDTokenResult *tokenResult = [self resultWithAccessToken:accessToken
                                                          refreshToken:refreshableToken
                                                                 error:&resultError];
            
            if (tokenResult)
            {
                completionBlock(tokenResult, nil);
                return;
            }
            
            MSID_LOG_WITH_CTX(MSIDLogLevelWarning, self.requestParameters, @"Couldn't create result for cached access token, error %@. Try to recover...", MSID_PII_LOG_MASKABLE(resultError));
        }

        if (accessToken && accessToken.isExtendedLifetimeValid && enrollmentIdMatch)
        {
            MSID_LOG_WITH_CTX(MSIDLogLevelInfo, self.requestParameters, @"Access token has expired, but it is long-lived token.");
            
            self.extendedLifetimeAccessToken = accessToken;
        }
        else if (accessToken)
        {
            MSID_LOG_WITH_CTX(MSIDLogLevelInfo, self.requestParameters, @"Access token has expired, removing it...");
            NSError *removalError = nil;
            BOOL removalResult = [self.tokenCache removeAccessToken:accessToken
                                                            context:self.requestParameters
                                                              error:&removalError];
            if (!removalResult)
            {
                MSID_LOG_WITH_CTX_PII(MSIDLogLevelWarning,self.requestParameters, @"Failed to remove access token with error %@", MSID_PII_LOG_MASKABLE(removalError));
            }
        }
    }

    NSError *frtCacheError = nil;
    MSID_LOG_WITH_CTX(MSIDLogLevelInfo, self.requestParameters, @"Looking for Family Refresh token...");
    MSIDRefreshToken *familyRefreshToken = [self familyRefreshTokenWithError:&frtCacheError];

    if (frtCacheError)
    {
        MSID_LOG_WITH_CTX_PII(MSIDLogLevelError, self.requestParameters, @"Failed to read family refresh token with error %@", MSID_PII_LOG_MASKABLE(frtCacheError));
        completionBlock(nil, frtCacheError);
        return;
    }

    if (familyRefreshToken)
    {
        MSID_LOG_WITH_CTX(MSIDLogLevelInfo, self.requestParameters, @"Found Family Refresh token, using it...");
        [self tryFRT:familyRefreshToken completionBlock:completionBlock];
    }
    else
    {
        MSID_LOG_WITH_CTX(MSIDLogLevelInfo, self.requestParameters, @"Family Refresh token wasn't found, looking for Refresh token...");
        NSError *appRTCacheError = nil;
        MSIDBaseToken<MSIDRefreshableToken> *appRefreshToken = [self appRefreshTokenWithError:&appRTCacheError];

        if (appRTCacheError)
        {
            MSID_LOG_WITH_CTX_PII(MSIDLogLevelError, self.requestParameters, @"Failed to read app specific refresh token with error %@", MSID_PII_LOG_MASKABLE(appRTCacheError));
            completionBlock(nil, appRTCacheError);
            return;
        }

        [self tryAppRefreshToken:appRefreshToken completionBlock:completionBlock];
    }
}

- (void)tryFRT:(MSIDRefreshToken *)familyRefreshToken completionBlock:(nonnull MSIDRequestCompletionBlock)completionBlock
{
    MSID_LOG_WITH_CTX_PII(MSIDLogLevelVerbose, self.requestParameters, @"Trying to acquire access token using FRT for clientId %@, authority %@, account %@", self.requestParameters.authority, self.requestParameters.clientId, self.requestParameters.accountIdentifier.maskedHomeAccountId);

    [self refreshAccessToken:familyRefreshToken
             completionBlock:^(MSIDTokenResult * _Nullable result, NSError * _Nullable error) {
                 if (error)
                 {
                     if ([self isErrorRecoverableByUserInteraction:error])
                     {
                         //Udpate app metadata  by resetting familyId if server returns client_mismatch
                         NSError *msidError = nil;

                         [self updateFamilyIdCacheWithServerError:error
                                                       cacheError:&msidError];

                         if (msidError)
                         {
                             MSID_LOG_WITH_CTX_PII(MSIDLogLevelError, self.requestParameters, @"Failed to update familyID cache status with error %@", MSID_PII_LOG_MASKABLE(error));
                         }

                         MSIDBaseToken<MSIDRefreshableToken> *appRefreshToken = [self appRefreshTokenWithError:&msidError];

                         if (msidError)
                         {
                             MSID_LOG_WITH_CTX_PII(MSIDLogLevelError, self.requestParameters, @"Failed to retrieve multi resource refresh token with error %@", MSID_PII_LOG_MASKABLE(error));
                             completionBlock(nil, msidError);
                             return;
                         }

                         if (appRefreshToken && ![[familyRefreshToken refreshToken] isEqualToString:[appRefreshToken refreshToken]])
                         {
                             [self tryAppRefreshToken:appRefreshToken completionBlock:completionBlock];
                             return;
                         }

                         NSError *interactionError = MSIDCreateError(MSIDErrorDomain, MSIDErrorInteractionRequired, @"User interaction is required", error.msidOauthError, error.msidSubError, error, self.requestParameters.correlationId, nil, YES);
                         completionBlock(nil, interactionError);
                     }
                     else
                     {
                         completionBlock(nil, error);
                     }
                 }
                 else
                 {
                     completionBlock(result, nil);
                 }
             }];
}

- (void)tryAppRefreshToken:(MSIDBaseToken<MSIDRefreshableToken> *)multiResourceRefreshToken
           completionBlock:(nonnull MSIDRequestCompletionBlock)completionBlock
{
    if (!multiResourceRefreshToken)
    {
        MSID_LOG_WITH_CTX(MSIDLogLevelInfo, self.requestParameters, @"Refresh token wasn't found, user interaction is required.");
        
        NSError *interactionError = MSIDCreateError(MSIDErrorDomain, MSIDErrorInteractionRequired, @"User interaction is required", nil, nil, nil, self.requestParameters.correlationId, nil, YES);
        completionBlock(nil, interactionError);
        return;
    }
    
    MSID_LOG_WITH_CTX(MSIDLogLevelInfo, self.requestParameters, @"Found Refresh token, using it...");
    [self refreshAccessToken:multiResourceRefreshToken
             completionBlock:^(MSIDTokenResult * _Nullable result, NSError * _Nullable error) {
                 if (error)
                 {
                     //Check if server returns invalid_grant or invalid_request
                     if ([self isErrorRecoverableByUserInteraction:error])
                     {
                         NSError *interactionError = MSIDCreateError(MSIDErrorDomain, MSIDErrorInteractionRequired, @"User interaction is required", error.msidOauthError, error.msidSubError, error, self.requestParameters.correlationId, nil, YES);

                         completionBlock(nil, interactionError);
                         return;
                     }
                     else
                     {
                         completionBlock(nil, error);
                     }
                 }
                 else
                 {
                     completionBlock(result, nil);
                 }
             }];
}

#pragma mark - Helpers

- (BOOL)isErrorRecoverableByUserInteraction:(NSError *)msidError
{
    MSIDErrorCode oauthError = MSIDErrorCodeForOAuthError(msidError.msidOauthError, MSIDErrorServerInvalidGrant);

    if (oauthError == MSIDErrorServerInvalidScope
        || oauthError == MSIDErrorServerInvalidClient)
    {
        return NO;
    }

    /*
        The default behavior of SDK should be to always show UI
        as long as server returns us valid response with an existing Oauth2 error.
        If it's an unrecoverable error, server will show error message to user in the web UI.
        If client wants to not show UI in particular cases, they can examine error contents and do custom handling based on Oauth2 error code and/or sub error.
     */
    return ![NSString msidIsStringNilOrBlank:msidError.msidOauthError];
}

- (void)refreshAccessToken:(MSIDBaseToken<MSIDRefreshableToken> *)refreshToken
           completionBlock:(MSIDRequestCompletionBlock)completionBlock
{
    if (!refreshToken)
    {
        NSError *error = MSIDCreateError(MSIDErrorDomain, MSIDErrorInteractionRequired, @"No token matching arguments found in the cache", nil, nil, nil, self.requestParameters.correlationId, nil, YES);
        completionBlock(nil, error);
        return;
    }

    MSID_LOG_WITH_CTX(MSIDLogLevelInfo, self.requestParameters, @"Refreshing access token");

    [self.requestParameters.authority loadOpenIdMetadataWithContext:self.requestParameters
                                                    completionBlock:^(__unused MSIDOpenIdProviderMetadata * _Nullable metadata, NSError * _Nullable error) {

                                                        if (error)
                                                        {
                                                            completionBlock(nil, error);
                                                            return;
                                                        }

                                                        [self acquireTokenWithRefreshTokenImpl:refreshToken
                                                                               completionBlock:completionBlock];

                                                    }];
}

- (void)acquireTokenWithRefreshTokenImpl:(MSIDBaseToken<MSIDRefreshableToken> *)refreshToken
                         completionBlock:(MSIDRequestCompletionBlock)completionBlock
{
    MSID_LOG_WITH_CTX(MSIDLogLevelInfo, self.requestParameters, @"Acquiring Access token via Refresh token...");
    
    MSIDRefreshTokenGrantRequest *tokenRequest = [self.oauthFactory refreshTokenRequestWithRequestParameters:self.requestParameters
                                                                                                refreshToken:refreshToken.refreshToken];

    [tokenRequest sendWithBlock:^(MSIDTokenResponse *tokenResponse, NSError *error)
    {
        if (error)
        {
            BOOL serverUnavailable = error.userInfo[MSIDServerUnavailableStatusKey] != nil;

            if (serverUnavailable && self.requestParameters.extendedLifetimeEnabled && self.extendedLifetimeAccessToken)
            {
                NSTimeInterval expiresIn = [self.extendedLifetimeAccessToken.extendedExpiresOn timeIntervalSinceNow];
                MSID_LOG_WITH_CTX(MSIDLogLevelInfo, self.requestParameters, @"Server unavailable, using long-lived access token, which expires in %f", expiresIn);
                NSError *cacheError = nil;
                MSIDTokenResult *tokenResult = [self resultWithAccessToken:self.extendedLifetimeAccessToken
                                                              refreshToken:refreshToken
                                                                     error:&cacheError];
                
                MSID_LOG_WITH_CTX(MSIDLogLevelError, self.requestParameters, @"Found error retrieving cache for result %@, %ld", cacheError.domain, (long)cacheError.code);
                tokenResult.extendedLifeTimeToken = YES;
                NSError *resultError = (tokenResult ? nil : error);
                
                completionBlock(tokenResult, resultError);
                return;
            }
            
            MSID_LOG_WITH_CTX(MSIDLogLevelInfo, self.requestParameters, @"Failed to acquire Access token via Refresh token.");

            completionBlock(nil, error);
            return;
        }

        MSID_LOG_WITH_CTX(MSIDLogLevelInfo, self.requestParameters, @"Validate and save token response...");
        NSError *validationError = nil;
        MSIDTokenResult *tokenResult = [self.tokenResponseValidator validateAndSaveTokenResponse:tokenResponse
                                                                                    oauthFactory:self.oauthFactory
                                                                                      tokenCache:self.tokenCache
                                                                            accountMetadataCache:self.metadataCache
                                                                               requestParameters:self.requestParameters
                                                                                           error:&validationError];

        if (!tokenResult && [self shouldRemoveRefreshToken:validationError])
        {
            MSID_LOG_WITH_CTX(MSIDLogLevelInfo, self.requestParameters, @"Refresh token invalid, removing it...");
            NSError *removalError = nil;
            BOOL result = [self.tokenCache validateAndRemoveRefreshToken:refreshToken
                                                                 context:self.requestParameters
                                                                   error:&removalError];

            if (!result)
            {
                MSID_LOG_WITH_CTX_PII(MSIDLogLevelWarning, self.requestParameters, @"Failed to remove invalid refresh token with error %@", MSID_PII_LOG_MASKABLE(removalError));
            }
        }

        if (!tokenResult)
        {
            // Special case - need to return homeAccountId in case of Intune policies required.
            if (validationError.code == MSIDErrorServerProtectionPoliciesRequired)
            {
                MSID_LOG_WITH_CTX(MSIDLogLevelInfo, self.requestParameters, @"Received Protection Policy Required error.");
                
                NSMutableDictionary *updatedUserInfo = [validationError.userInfo mutableCopy];
                updatedUserInfo[MSIDHomeAccountIdkey] = self.requestParameters.accountIdentifier.homeAccountId;
                
                validationError = MSIDCreateError(validationError.domain,
                                                  validationError.code,
                                                  nil,
                                                  nil,
                                                  nil,
                                                  nil,
                                                  nil,
                                                  updatedUserInfo, NO);
            }
            
            completionBlock(nil, validationError);
            return;
        }
        
        void (^completionBlockWrapper)(void) = ^
        {
            MSID_LOG_WITH_CTX(MSIDLogLevelInfo, self.requestParameters, @"Returning token result.");
            completionBlock(tokenResult, nil);
        };
        
#if TARGET_OS_OSX
        if (self.externalCacheSeeder != nil)
        {
            [self.externalCacheSeeder seedTokenResponse:tokenResponse
                                                factory:self.oauthFactory
                                      requestParameters:self.requestParameters
                                        completionBlock:completionBlockWrapper];
        }
        else
#endif
        {
            completionBlockWrapper();
        }
    }];
}

#pragma mark - Abstract

- (nullable MSIDAccessToken *)accessTokenWithError:(__unused NSError **)error
{
    NSAssert(NO, @"Abstract method. Should be implemented in a subclass");
    return nil;
}

- (nullable MSIDTokenResult *)resultWithAccessToken:(__unused MSIDAccessToken *)accessToken
                                       refreshToken:(__unused id<MSIDRefreshableToken>)refreshToken
                                              error:(__unused NSError * _Nullable * _Nullable)error
{
    NSAssert(NO, @"Abstract method. Should be implemented in a subclass");
    return nil;
}

- (nullable MSIDRefreshToken *)familyRefreshTokenWithError:(__unused NSError * _Nullable * _Nullable)error
{
    NSAssert(NO, @"Abstract method. Should be implemented in a subclass");
    return nil;
}

- (nullable MSIDBaseToken<MSIDRefreshableToken> *)appRefreshTokenWithError:(__unused NSError * _Nullable * _Nullable)error
{
    NSAssert(NO, @"Abstract method. Should be implemented in a subclass");
    return nil;
}

- (BOOL)updateFamilyIdCacheWithServerError:(__unused NSError *)serverError
                                cacheError:(__unused NSError **)cacheError
{
    NSAssert(NO, @"Abstract method. Should be implemented in a subclass");
    return NO;
}

- (BOOL)shouldRemoveRefreshToken:(__unused NSError *)serverError
{
    NSAssert(NO, @"Abstract method. Should be implemented in a subclass");
    return NO;
}

- (id<MSIDCacheAccessor>)tokenCache
{
    NSAssert(NO, @"Abstract method. Should be implemented in a subclass");
    return nil;
}

- (MSIDAccountMetadataCacheAccessor *)metadataCache
{
    NSAssert(NO, @"Abstract method. Should be implemented in a subclass");
    return nil;
}

@end
