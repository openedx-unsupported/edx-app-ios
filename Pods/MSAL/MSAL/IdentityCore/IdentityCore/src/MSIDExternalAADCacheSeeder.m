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

#if !EXCLUDE_FROM_MSALCPP

#import "MSIDExternalAADCacheSeeder.h"
#import "MSIDAADV2Oauth2Factory.h"
#import "MSIDRefreshTokenGrantRequest.h"
#import "MSIDTokenResponse.h"
#import "MSIDLegacyRefreshToken.h"
#import "MSIDLegacyTokenCacheAccessor.h"
#import "MSIDDefaultTokenCacheAccessor.h"
#import "MSIDIdToken.h"
#import "MSIDRequestParameters.h"
#import "MSIDAADV2Oauth2FactoryForV1Request.h"
#import "MSIDTelemetry+Internal.h"
#import "MSIDTelemetryEventStrings.h"
#import "MSIDTelemetryCacheEvent.h"
#import "MSIDTelemetry+Cache.h"
#import "MSIDGetV1IdTokenHttpEvent.h"
#import "MSIDTelemetryEventStrings.h"
#import "MSIDGetV1IdTokenCacheEvent.h"

@interface MSIDExternalAADCacheSeeder()

@property (nonatomic) MSIDLegacyTokenCacheAccessor *externalLegacyAccessor;
@property (nonatomic) MSIDDefaultTokenCacheAccessor *defaultAccessor;
@property (nonatomic) MSIDTelemetry *telemetry;

@end

@implementation MSIDExternalAADCacheSeeder

- (instancetype)initWithDefaultAccessor:(MSIDDefaultTokenCacheAccessor *)defaultAccessor
                 externalLegacyAccessor:(MSIDLegacyTokenCacheAccessor *)externalLegacyAccessor
{
    NSParameterAssert(defaultAccessor);
    NSParameterAssert(externalLegacyAccessor);
    
    self = [super init];
    if (self)
    {
        _defaultAccessor = defaultAccessor;
        _externalLegacyAccessor = externalLegacyAccessor;
        _telemetry = [MSIDTelemetry sharedInstance];
    }
    
    return self;
}

- (void)seedTokenResponse:(MSIDTokenResponse *)originalTokenResponse
                  factory:(MSIDOauth2Factory *)factory
        requestParameters:(MSIDRequestParameters *)requestParameters
          completionBlock:(void(^)(void))completionBlock
{
    NSParameterAssert(originalTokenResponse);
    NSParameterAssert(factory);
    NSParameterAssert(requestParameters);
    NSParameterAssert(completionBlock);
    
    MSID_LOG_WITH_CTX(MSIDLogLevelInfo, requestParameters, @"Beginning external cache seeding.");
    
    [self.telemetry startEvent:requestParameters.telemetryRequestId eventName:MSID_TELEMETRY_EVENT_EXTERNAL_CACHE_SEEDING];
    
    void (^completionBlockWrapper)(BOOL success) = ^(BOOL success)
    {
        MSID_LOG_WITH_CTX(MSIDLogLevelInfo, requestParameters, @"External cache seeding finished.");
        
        MSIDTelemetryCacheEvent *event = [MSIDTelemetry startCacheEventWithName:MSID_TELEMETRY_EVENT_EXTERNAL_CACHE_SEEDING
                                                                        context:requestParameters];
        [event setExternalCacheSeedingStatus:success ? MSID_TELEMETRY_VALUE_YES : MSID_TELEMETRY_VALUE_NO];
        
        [MSIDTelemetry stopCacheEvent:event withItem:nil success:success context:requestParameters];
        
        completionBlock();
    };
    
    MSIDIdToken *idToken = [factory idTokenFromResponse:originalTokenResponse
                                          configuration:requestParameters.msidConfiguration];
    
    __auto_type accountIdentifier = idToken.accountIdentifier;
    
    NSError *error;
    MSIDConfiguration *configuration = [requestParameters.msidConfiguration copy];
    configuration.authority = originalTokenResponse.idTokenObj.issuerAuthority;
    
    MSID_LOG_WITH_CTX(MSIDLogLevelInfo, requestParameters, @"Trying to get legacy id token from cache.");
    
    MSIDIdToken *legacyIdToken = [self.defaultAccessor getIDTokenForAccount:accountIdentifier
                                                              configuration:configuration
                                                                idTokenType:MSIDLegacyIDTokenType
                                                                    context:requestParameters
                                                                      error:&error];
    
    if (legacyIdToken)
    {
        [self.telemetry startEvent:requestParameters.telemetryRequestId eventName:MSID_TELEMETRY_EVENT_FOUND_V1_ID_TOKEN_IN_CACHE];
        __auto_type event = [[MSIDGetV1IdTokenCacheEvent alloc] initWithName:MSID_TELEMETRY_EVENT_FOUND_V1_ID_TOKEN_IN_CACHE
                                                                                      context:requestParameters];
        [self.telemetry stopEvent:requestParameters.telemetryRequestId event:event];
        
        MSID_LOG_WITH_CTX(MSIDLogLevelInfo, requestParameters, @"Found legacy id token in cache.");
        
        [self seedExternalCacheWithIdToken:legacyIdToken
                             tokenResponse:originalTokenResponse
                                   factory:factory
                             configuration:requestParameters.msidConfiguration
                         providedAuthority:requestParameters.providedAuthority
                                   context:requestParameters
                           completionBlock:completionBlockWrapper];
        return;
    }
    
    MSID_LOG_WITH_CTX(MSIDLogLevelInfo, requestParameters, @"Legacy id token wasn't found in cache, sending network request to acquire legacy id token.");
    
    __auto_type refreshToken = [factory refreshTokenFromResponse:originalTokenResponse
                                                   configuration:requestParameters.msidConfiguration];
    
    NSMutableDictionary *extraTokenRequestParameters = [requestParameters.extraTokenRequestParameters mutableCopy];
    extraTokenRequestParameters[@"itver"] = @"1";
    requestParameters.extraTokenRequestParameters = extraTokenRequestParameters;
    
    factory = [MSIDAADV2Oauth2FactoryForV1Request new];
    MSIDRefreshTokenGrantRequest *tokenRequest = [factory refreshTokenRequestWithRequestParameters:requestParameters
                                                                                      refreshToken:refreshToken.refreshToken];

    [self.telemetry startEvent:requestParameters.telemetryRequestId eventName:MSID_TELEMETRY_EVENT_HTTP_V1_IDTOKEN_REQUEST];
    
    [tokenRequest sendWithBlock:^(MSIDTokenResponse *tokenResponse, NSError *requestError)
     {
         __auto_type event = [[MSIDGetV1IdTokenHttpEvent alloc] initWithName:MSID_TELEMETRY_EVENT_HTTP_V1_IDTOKEN_REQUEST
                                                                                     context:requestParameters];
         [self.telemetry stopEvent:requestParameters.telemetryRequestId event:event];
         
         if (requestError)
         {
             MSID_LOG_WITH_CTX_PII(MSIDLogLevelError, requestParameters, @"Failed to acquire V1 Id Token token via Refresh token, error: %@", MSID_PII_LOG_MASKABLE(requestError));
             
             completionBlockWrapper(false);
             return;
         }
         
         MSIDIdToken *v1IdToken = [factory idTokenFromResponse:tokenResponse
                                                     configuration:requestParameters.msidConfiguration];
         
         if (!v1IdToken)
         {
             MSID_LOG_WITH_CTX_PII(MSIDLogLevelError, requestParameters, @"Failed to parse V1 Id Token, error: %@", MSID_PII_LOG_MASKABLE(requestError));
             
             completionBlockWrapper(false);
         }
         
         MSID_LOG_WITH_CTX(MSIDLogLevelInfo, requestParameters, @"Saving V1 id token in default cache.");
         
         NSError *localError;
         BOOL result = [self.defaultAccessor saveToken:v1IdToken context:requestParameters error:&localError];
         if (result)
         {
             MSID_LOG_WITH_CTX(MSIDLogLevelInfo, requestParameters, @"Saved V1 id token in default cache.");
         }
         else
         {
             MSID_LOG_WITH_CTX_PII(MSIDLogLevelError, requestParameters, @"Failed to save V1 id token in default cache, error: %@", MSID_PII_LOG_MASKABLE(error));
         }
         
         [self seedExternalCacheWithIdToken:v1IdToken
                              tokenResponse:originalTokenResponse
                                    factory:factory
                              configuration:requestParameters.msidConfiguration
                          providedAuthority:requestParameters.providedAuthority
                                    context:requestParameters
                            completionBlock:completionBlockWrapper];
     }];
}

#pragma mark - Private

- (void)seedExternalCacheWithIdToken:(MSIDIdToken *)idToken
                       tokenResponse:(MSIDTokenResponse *)tokenResponse
                             factory:(MSIDOauth2Factory *)factory
                       configuration:(MSIDConfiguration *)configuration
                   providedAuthority:(MSIDAuthority *)providedAuthority
                             context:(id<MSIDRequestContext>)context
                     completionBlock:(void(^)(BOOL success))completionBlock
{
    NSParameterAssert(completionBlock);
    
    if (providedAuthority)
    {
        // If we have original authority provided by the developer, use it
        // for caching RT in Legacy Cache.
        configuration = [configuration copy];
        configuration.authority = providedAuthority;
    }
    
    MSIDLegacyRefreshToken *refreshToken = [factory legacyRefreshTokenFromResponse:tokenResponse
                                                                     configuration:configuration];
    refreshToken.idToken = idToken.rawIdToken;
    
    MSID_LOG_WITH_CTX(MSIDLogLevelInfo, context, @"Checking refresh token existence in external cache.");
    
    NSError *error;
    MSIDRefreshToken *existingRefreshToken = [self.externalLegacyAccessor getRefreshTokenWithAccount:refreshToken.accountIdentifier
                                                                                            familyId:refreshToken.familyId
                                                                                       configuration:configuration
                                                                                             context:context
                                                                                               error:&error];
    
    if (error)
    {
        MSID_LOG_WITH_CTX_PII(MSIDLogLevelError, context, @"Failed to read refresh token from external cache, error: %@", MSID_PII_LOG_MASKABLE(error));
        completionBlock(NO);
        return;
    }
    
    if (existingRefreshToken)
    {
        MSID_LOG_WITH_CTX(MSIDLogLevelInfo, context, @"Found existing refresh token in external cache. Returning early.");
        completionBlock(YES);
        return;
    }
    
    MSID_LOG_WITH_CTX(MSIDLogLevelInfo, context, @"Saving refresh token in external cache.");
    
    BOOL result = [self.externalLegacyAccessor saveRefreshToken:refreshToken
                                                  configuration:configuration
                                                        context:context
                                                          error:&error];
    
    if (result)
    {
        MSID_LOG_WITH_CTX(MSIDLogLevelInfo, context, @"Refresh token was saved in external cache.");
    }
    else
    {
        MSID_LOG_WITH_CTX_PII(MSIDLogLevelError, context, @"Failed to save refresh token in external cache, error: %@", MSID_PII_LOG_MASKABLE(error));
    }
    
    completionBlock(result);
}

@end

#endif
