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
#import "MSIDAccountMetadataCacheAccessor.h"
#import "MSIDTokenResponseHandler.h"
#import "MSIDLastRequestTelemetry.h"
#import "MSIDCurrentRequestTelemetry.h"

#if TARGET_OS_OSX && !EXCLUDE_FROM_MSALCPP
#import "MSIDExternalAADCacheSeeder.h"
#endif

#import "MSIDAuthenticationScheme.h"

typedef NS_ENUM(NSInteger, MSIDRefreshTokenTypes)
{
    MSIDAppRefreshTokenType = 0,
    MSIDFamilyRefreshTokenType
};

@interface MSIDSilentTokenRequest()

@property (nonatomic) MSIDRequestParameters *requestParameters;
@property (nonatomic) BOOL forceRefresh;
@property (nonatomic) MSIDOauth2Factory *oauthFactory;
@property (nonatomic) MSIDTokenResponseValidator *tokenResponseValidator;
@property (nonatomic) MSIDAccessToken *extendedLifetimeAccessToken;
@property (nonatomic) MSIDAccessToken *unexpiredRefreshNeededAccessToken;
@property (nonatomic) MSIDTokenResponseHandler *tokenResponseHandler;
#if !EXCLUDE_FROM_MSALCPP
@property (nonatomic) MSIDLastRequestTelemetry *lastRequestTelemetry;
@property (nonatomic) MSIDCurrentRequestTelemetry *currentRequestTelemetry;
#endif
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
        _tokenResponseHandler = [MSIDTokenResponseHandler new];
#if !EXCLUDE_FROM_MSALCPP
        _lastRequestTelemetry = [MSIDLastRequestTelemetry sharedInstance];
        _currentRequestTelemetry = parameters.currentRequestTelemetry;
#endif
        _unexpiredRefreshNeededAccessToken = nil;
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
                                                           __unused BOOL validated, NSError *localError)
     {
        if (localError)
        {
            completionBlock(nil, localError);
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
        
        if (!accessToken)
        {
            CONDITIONAL_SET_REFRESH_TYPE(self.currentRequestTelemetry.tokenCacheRefreshType, TokenCacheRefreshTypeNoCachedAT);
        }
        
        BOOL enrollmentIdMatch = YES;
        BOOL accessTokenKeyThumbprintMatch = YES;
        
        // If token is scoped down to a particular enrollmentId and app is capable for True MAM CA, verify that enrollmentIds match
        // EnrollmentID matching is done on the request layer to ensure that expired access tokens get removed even if valid enrollmentId is not presented
        if (self.requestParameters.msidConfiguration.authority.supportsMAMScenarios
            && [MSIDIntuneApplicationStateManager isAppCapableForMAMCA]
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
            
            
            MSID_LOG_WITH_CTX(MSIDLogLevelInfo, self.requestParameters, @"Enrollment id match result = %@, access token's enrollment id : %@, cached enrollment id: %@, ", enrollmentIdMatch ? @"True" : @"False", MSID_PII_LOG_MASKABLE(accessToken.enrollmentId), MSID_PII_LOG_MASKABLE(currentEnrollmentId));
        }
        
        if (accessToken && ![NSString msidIsStringNilOrBlank:accessToken.kid])
        {
            accessTokenKeyThumbprintMatch = [self.requestParameters.authScheme matchAccessTokenKeyThumbprint:accessToken];
        }
        
        if (accessToken && ![accessToken isExpiredWithExpiryBuffer:self.requestParameters.tokenExpirationBuffer] && enrollmentIdMatch && accessTokenKeyThumbprintMatch)
        {
            MSID_LOG_WITH_CTX(MSIDLogLevelInfo, self.requestParameters, @"Found valid access token.");
            
            // unexpired token exists , check if refresh needed, if no refresh needed, return the unexpired token
            if (!accessToken.refreshNeeded)
            {
                __block MSIDBaseToken<MSIDRefreshableToken> *refreshableToken = nil;
                [self fetchCachedTokenAndCheckForFRTFirst:YES shouldComplete:NO completionHandler:^(MSIDBaseToken<MSIDRefreshableToken> *token, __unused MSIDRefreshTokenTypes tokenType, __unused NSError *error) {
                    refreshableToken = token;
                }];
                
                NSError *resultError = nil;
                MSIDTokenResult *tokenResult = [self resultWithAccessToken:accessToken
                                                              refreshToken:refreshableToken
                                                                     error:&resultError];
                
                if (tokenResult)
                {
#if !EXCLUDE_FROM_MSALCPP
                    [self.lastRequestTelemetry increaseSilentSuccessfulCount];
#endif
                    completionBlock(tokenResult, nil);
                    return;
                }
                
                MSID_LOG_WITH_CTX(MSIDLogLevelWarning, self.requestParameters, @"Couldn't create result for cached access token, error %@. Try to recover...", MSID_PII_LOG_MASKABLE(resultError));
            }
            else
            {
                // unexpired token exists, but needs refresh. Store token to return if refresh attempt fails due to AAD being down
                self.unexpiredRefreshNeededAccessToken = accessToken;
                CONDITIONAL_SET_REFRESH_TYPE(self.currentRequestTelemetry.tokenCacheRefreshType, TokenCacheRefreshTypeProactiveTokenRefresh);
                MSID_LOG_WITH_CTX(MSIDLogLevelInfo, self.requestParameters, @"Unexpired access token exists, but needs refresh, since refresh expired.");
            }
            
        }
        
        else if (accessToken && accessToken.isExtendedLifetimeValid && enrollmentIdMatch && accessTokenKeyThumbprintMatch)
        {
            MSID_LOG_WITH_CTX(MSIDLogLevelInfo, self.requestParameters, @"Access token has expired, but it is long-lived token.");
            
            self.extendedLifetimeAccessToken = accessToken;
            CONDITIONAL_SET_REFRESH_TYPE(self.currentRequestTelemetry.tokenCacheRefreshType, TokenCacheRefreshTypeExpiredAT);
        }
        else if (accessToken)
        {
            if (!enrollmentIdMatch)
            {
                MSID_LOG_WITH_CTX(MSIDLogLevelInfo, self.requestParameters, @"Cached enrollment id is different from access token's enrollment id, removing it..");
            }
            else if (!accessTokenKeyThumbprintMatch)
            {
                MSID_LOG_WITH_CTX(MSIDLogLevelInfo, self.requestParameters, @"Cached key thumbprint is different from access token's key thumbprint, removing it..");
            }
            else
            {
                MSID_LOG_WITH_CTX(MSIDLogLevelInfo, self.requestParameters, @"Access token has expired, removing it...");
                CONDITIONAL_SET_REFRESH_TYPE(self.currentRequestTelemetry.tokenCacheRefreshType, TokenCacheRefreshTypeExpiredAT);
            }
            
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
    [self fetchCachedTokenAndCheckForFRTFirst:NO shouldComplete:NO completionHandler:^(MSIDBaseToken<MSIDRefreshableToken> *refreshToken, MSIDRefreshTokenTypes tokenType, NSError *error) {
        if (!refreshToken)
        {
            NSError *interactionError = MSIDCreateError(MSIDErrorDomain, MSIDErrorInteractionRequired, @"No token matching arguments found in the cache, user interaction is required", error.msidOauthError, error.msidSubError, error, self.requestParameters.correlationId, nil, YES);
            completionBlock(nil, interactionError);
            return;
        }
        
        [self tryRefreshToken:refreshToken tokenType:tokenType completionBlock:completionBlock];
    }];
}

- (void)fetchCachedTokenAndCheckForFRTFirst:(BOOL)checkForFRT shouldComplete:(BOOL)shouldComplete completionHandler:(void (^)(MSIDBaseToken<MSIDRefreshableToken> *, MSIDRefreshTokenTypes, NSError *))completionHandler
{
    if (!completionHandler)
    {
        MSID_LOG_WITH_CTX(MSIDLogLevelInfo, self.requestParameters, @"No completionHandler when fetch local refresh token");
        return;
    }
    
    NSError *rtError = nil;
    MSIDBaseToken<MSIDRefreshableToken> *refreshableToken = nil;
    NSString *contextMsg = checkForFRT ? @"family refresh token" : @"app refresh token";
    MSIDRefreshTokenTypes checkForTokenType = checkForFRT ? MSIDFamilyRefreshTokenType : MSIDAppRefreshTokenType;
    
    MSID_LOG_WITH_CTX(MSIDLogLevelInfo, self.requestParameters, @"Looking for %@...", contextMsg);
    if (checkForFRT)
    {
        refreshableToken = [self familyRefreshTokenWithError:&rtError];
    }
    else
    {
        refreshableToken = [self appRefreshTokenWithError:&rtError];
    }
    
    if (rtError && shouldComplete)
    {
        MSID_LOG_WITH_CTX_PII(MSIDLogLevelError, self.requestParameters, @"Failed to read %@ token with error %@", contextMsg, MSID_PII_LOG_MASKABLE(rtError));
        completionHandler(nil, checkForTokenType, rtError);
        return;
    }
    
    if (!refreshableToken)
    {
        // Handle to continue or complete
        MSID_LOG_WITH_CTX_PII(MSIDLogLevelWarning, self.requestParameters, @"Didn't find %@", contextMsg);
        if (!shouldComplete)
        {
            [self fetchCachedTokenAndCheckForFRTFirst:!checkForFRT shouldComplete:!shouldComplete completionHandler:completionHandler];
        }
        else
        {
            // If no refreshableToken was found, simply return nil as token and token type that the last one it tries to find
            completionHandler(nil, checkForTokenType, nil);
        }
    }
    else
    {
        MSID_LOG_WITH_CTX(MSIDLogLevelInfo, self.requestParameters, @"Found %@.", contextMsg);
        completionHandler(refreshableToken, checkForTokenType, nil);
    }
}

- (void)tryRefreshToken:(MSIDBaseToken<MSIDRefreshableToken> *)refreshToken
              tokenType:(MSIDRefreshTokenTypes)tokenType
        completionBlock:(nonnull MSIDRequestCompletionBlock)completionBlock
{
    BOOL isTryingWithAppRefreshToken = tokenType == MSIDAppRefreshTokenType;
    MSID_LOG_WITH_CTX_PII(MSIDLogLevelVerbose, self.requestParameters, @"Trying to acquire access token using %@ for clientId %@, authority %@, account %@", (isTryingWithAppRefreshToken ? @"App Refresh Token" : @"Family Refresh Token"), self.requestParameters.authority, self.requestParameters.clientId, self.requestParameters.accountIdentifier.maskedHomeAccountId);
    
    // When using ART or FRT, it will go through the same method below, and handle differently within the completion block
    [self redeemAccessTokenWith:refreshToken
                completionBlock:^(MSIDTokenResult * _Nullable result, NSError * _Nullable error) {
        if (!error)
        {
            completionBlock(result, nil);
            return;
        }
        
        if ([self isErrorRecoverableByUserInteraction:error])
        {
            if (isTryingWithAppRefreshToken)
            {
                // Handle error case when try with App refresh token
                BOOL canTryWithFamilyRefreshToken = [self handleErrorResponseForAppRefreshToken:refreshToken
                                                                                completionBlock:completionBlock];
                if (canTryWithFamilyRefreshToken)
                {
                    return;
                }
            }
            else
            {
                // Handle error case when try with Family refresh token
                [self handleErrorResponseForFamilyRefreshToken:error];
            }
            
            NSError *interactionError = MSIDCreateError(MSIDErrorDomain, MSIDErrorInteractionRequired, @"User interaction is required", error.msidOauthError, error.msidSubError, error, self.requestParameters.correlationId, nil, YES);
            completionBlock(nil, interactionError);
        }
        else
        {
            completionBlock(nil, error);
        }
        
    }];
}

#pragma mark - Helpers

- (BOOL)handleErrorResponseForAppRefreshToken:(MSIDBaseToken<MSIDRefreshableToken> *)refreshToken
                              completionBlock:(nonnull MSIDRequestCompletionBlock)completionBlock
{
    NSError *error = nil;
    MSIDRefreshToken *familyRefreshToken = [self familyRefreshTokenWithError:&error];
    if (error)
    {
        MSID_LOG_WITH_CTX_PII(MSIDLogLevelError, self.requestParameters, @"Failed to retrieve Family Refresh token with error %@, and user interaction is required", MSID_PII_LOG_MASKABLE(error));
        return NO;
    }
    
    if (familyRefreshToken && ![[familyRefreshToken refreshToken] isEqualToString:[refreshToken refreshToken]])
    {
        [self tryRefreshToken:familyRefreshToken
                    tokenType:MSIDFamilyRefreshTokenType
              completionBlock:completionBlock];
        return YES;
    }
    
    return NO;
}

- (void)handleErrorResponseForFamilyRefreshToken:(NSError *)error
{
    NSError *msidError = nil;
    [self updateFamilyIdCacheWithServerError:error
                                  cacheError:&msidError];
    if (msidError)
    {
        MSID_LOG_WITH_CTX_PII(MSIDLogLevelError, self.requestParameters, @"Failed to update familyID cache status with error %@", MSID_PII_LOG_MASKABLE(error));
    }
}

- (BOOL)isErrorRecoverableByUserInteraction:(NSError *)msidError
{
    if ([msidError.domain isEqualToString:MSIDOAuthErrorDomain] && msidError.code == MSIDErrorServerProtectionPoliciesRequired)
    {
        return NO;
    }
    
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

- (void)redeemAccessTokenWith:(MSIDBaseToken<MSIDRefreshableToken> *) __unused refreshToken
              completionBlock:(MSIDRequestCompletionBlock) __unused completionBlock
{
#if !EXCLUDE_FROM_MSALCPP
    if (!refreshToken)
    {
        NSError *error = MSIDCreateError(MSIDErrorDomain, MSIDErrorInteractionRequired, @"No token matching arguments found in the cache, user interaction is required", nil, nil, nil, self.requestParameters.correlationId, nil, YES);
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
        
        // Check if token endpoint (from open id metadata) is the same cloud as the RT issuer cloud
        // If not the same cloud, we don't send RT to wrong cloud.
        if (![self.requestParameters.authority checkTokenEndpointForRTRefresh:self.requestParameters.tokenEndpoint])
        {
            NSError *interactionError = MSIDCreateError(MSIDErrorDomain, MSIDErrorInteractionRequired, @"User interaction is required (unable to use token from a different cloud).", nil, nil, nil, self.requestParameters.correlationId, nil, YES);
            completionBlock(nil, interactionError);
            return;
        }
        
        [self acquireTokenWithRefreshTokenImpl:refreshToken
                               completionBlock:completionBlock];
        
    }];
#endif
}

- (void)acquireTokenWithRefreshTokenImpl:(MSIDBaseToken<MSIDRefreshableToken> *) __unused refreshToken
                         completionBlock:(MSIDRequestCompletionBlock) __unused completionBlock
{
#if !EXCLUDE_FROM_MSALCPP
    MSID_LOG_WITH_CTX(MSIDLogLevelInfo, self.requestParameters, @"Acquiring Access token via Refresh token...");
    
    MSIDRefreshTokenGrantRequest *tokenRequest = [self.oauthFactory refreshTokenRequestWithRequestParameters:self.requestParameters
                                                                                                refreshToken:refreshToken.refreshToken];
    // Currently SilentTokenRequest has 3 child classes: Legacy, Default (local) and SSO. We will init the throttling service in Default and SSO and exclude Legacy. So the nil check of throttling service is needed
    if (!self.throttlingService || ![MSIDThrottlingService isThrottlingEnabled])
    {
        [self sendTokenRequestImpl:completionBlock refreshToken:refreshToken tokenRequest:tokenRequest];
    }
    else
    {
        // Invoke throttling service before making the call to server. If the request should be throttled, return the cached response (error) immediately
        [self.throttlingService shouldThrottleRequest:tokenRequest resultBlock:^(BOOL shouldBeThrottled, NSError * _Nullable cachedError)
         {
            MSID_LOG_WITH_CTX(MSIDLogLevelInfo, self.requestParameters, @"Throttle decision: %@" , (shouldBeThrottled ? @"YES" : @"NO"));
            
            if (cachedError)
            {
                MSID_LOG_WITH_CTX(MSIDLogLevelWarning, self.requestParameters, @"Throttling return error: %@ ", MSID_PII_LOG_MASKABLE(cachedError));
            }
            
            if (shouldBeThrottled && cachedError)
            {
                completionBlock(nil, cachedError);
                return;
            }
            else
            {
                [self sendTokenRequestImpl:completionBlock refreshToken:refreshToken tokenRequest:tokenRequest];
            }
        }];
    }
#endif
}

#if !EXCLUDE_FROM_MSALCPP
- (void)sendTokenRequestImpl:(MSIDRequestCompletionBlock)completionBlock
                refreshToken:(MSIDBaseToken<MSIDRefreshableToken> *)refreshToken
                tokenRequest:(MSIDRefreshTokenGrantRequest *)tokenRequest
{
    [tokenRequest sendWithBlock:^(MSIDTokenResponse *tokenResponse, NSError *error)
     {
        if (error)
        {
            /**
             * If server issue 429 Throttling, this step will have error object. If UIRequired, there is no error yet. Later after serialize the tokenResponse we will create the error
             */
            if ([MSIDThrottlingService isThrottlingEnabled])
            {
                [self.throttlingService updateThrottlingService:error tokenRequest:tokenRequest];
            }
            
            BOOL serverUnavailable = error.userInfo[MSIDServerUnavailableStatusKey] != nil;
            if (serverUnavailable && self.unexpiredRefreshNeededAccessToken)
            {
                
                MSID_LOG_WITH_CTX(MSIDLogLevelInfo, self.requestParameters, @"Server unavailable, using refresh expired access Token");
                
                NSError *cacheError = nil;
                MSIDTokenResult *tokenResult = [self resultWithAccessToken:self.unexpiredRefreshNeededAccessToken
                                                              refreshToken:refreshToken
                                                                     error:&cacheError];
                if (tokenResult)
                {
                    completionBlock(tokenResult, nil);
                    return;
                }
                
                MSID_LOG_WITH_CTX(MSIDLogLevelWarning, self.requestParameters, @"Couldn't create result for cached access token, error %@. Try to recover...", MSID_PII_LOG_MASKABLE(cacheError));
                
            }
            
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
        
#if TARGET_OS_OSX
        self.tokenResponseHandler.externalCacheSeeder = self.externalCacheSeeder;
#endif
        [self.tokenResponseHandler handleTokenResponse:tokenResponse
                                     requestParameters:self.requestParameters
                                         homeAccountId:self.requestParameters.accountIdentifier.homeAccountId
                                tokenResponseValidator:self.tokenResponseValidator
                                          oauthFactory:self.oauthFactory
                                            tokenCache:self.tokenCache
                                  accountMetadataCache:self.metadataCache
                                       validateAccount:NO
                                      saveSSOStateOnly:NO
                                                 error:nil
                                       completionBlock:^(MSIDTokenResult *result, NSError *localError)
         {
            /**
             * If we can't serialize the response from server to tokens and there is error, we want to update throttling service
             */
            if (localError && [MSIDThrottlingService isThrottlingEnabled])
            {
                [self.throttlingService updateThrottlingService:localError tokenRequest:tokenRequest];
            }
            
            if (!result && [self shouldRemoveRefreshToken:localError])
            {
                MSID_LOG_WITH_CTX(MSIDLogLevelInfo, self.requestParameters, @"Refresh token invalid, removing it...");
                NSError *removalError = nil;
                BOOL removalResult = [self.tokenCache validateAndRemoveRefreshToken:refreshToken
                                                                     context:self.requestParameters
                                                                       error:&removalError];
                
                if (!removalResult)
                {
                    MSID_LOG_WITH_CTX_PII(MSIDLogLevelWarning, self.requestParameters, @"Failed to remove invalid refresh token with error %@", MSID_PII_LOG_MASKABLE(removalError));
                }
            }
            
            completionBlock(result, localError);
        }];
    }];
}
#endif

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
