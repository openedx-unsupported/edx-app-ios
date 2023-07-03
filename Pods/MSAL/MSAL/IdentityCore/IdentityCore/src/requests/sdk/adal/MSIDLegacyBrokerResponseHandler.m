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

#import "MSIDLegacyBrokerResponseHandler.h"
#import "MSIDOauth2Factory.h"
#import "MSIDBrokerResponse.h"
#import "MSIDAADV1BrokerResponse.h"
#import "MSIDLegacyTokenCacheAccessor.h"
#import "MSIDDefaultTokenCacheAccessor.h"
#import "MSIDBrokerCryptoProvider.h"
#import "MSIDTokenResponseValidator.h"
#import "MSIDTokenResult.h"
#import "MSIDAccount.h"
#import "MSIDConstants.h"
#import "MSIDBrokerResponseHandler+Internal.h"
#import "MSIDRequestParameters.h"

#if TARGET_OS_IPHONE
#import "MSIDKeychainTokenCache.h"
#endif
#import "MSIDAuthenticationScheme.h"

@implementation MSIDLegacyBrokerResponseHandler

- (id<MSIDCacheAccessor>)cacheAccessorWithKeychainGroup:(__unused NSString *)keychainGroup
                                                  error:(__unused NSError **)error
{
#if TARGET_OS_IPHONE
    MSIDKeychainTokenCache *dataSource = [[MSIDKeychainTokenCache alloc] initWithGroup:keychainGroup error:error];
    
    if (!dataSource)
    {
        if (error)
        {
            *error = MSIDCreateError(MSIDErrorDomain, MSIDErrorInternal, @"Failed to initialize keychain cache.", nil, nil, nil, nil, nil, YES);
        }
        
        return nil;
    }
    
    MSIDDefaultTokenCacheAccessor *otherAccessor = [[MSIDDefaultTokenCacheAccessor alloc] initWithDataSource:dataSource otherCacheAccessors:nil];
    MSIDLegacyTokenCacheAccessor *cache = [[MSIDLegacyTokenCacheAccessor alloc] initWithDataSource:dataSource otherCacheAccessors:@[otherAccessor]];
    return cache;
#else
    if (error)
    {
        *error = MSIDCreateError(MSIDErrorDomain, MSIDErrorInternal, @"Broker responses not supported on macOS", nil, nil, nil, nil, nil, YES);
    }

    return nil;
#endif
}

- (MSIDBrokerResponse *)brokerResponseFromEncryptedQueryParams:(NSDictionary *)encryptedParams
                                                     oidcScope:(NSString *)oidcScope
                                                 correlationId:(NSUUID *)correlationID
                                                    authScheme:(MSIDAuthenticationScheme *)authScheme
                                                         error:(NSError **)error
{
    // Successful case
    if ([NSString msidIsStringNilOrBlank:encryptedParams[@"error_code"]])
    {
        NSDictionary *decryptedResponse = [self.brokerCryptoProvider decryptBrokerResponse:encryptedParams
                                                                             correlationId:correlationID
                                                                                     error:error];

        if (!decryptedResponse)
        {
            return nil;
        }
        
        if (![self checkBrokerNonce:decryptedResponse])
        {
            MSIDFillAndLogError(error, MSIDErrorBrokerMismatchedResumeState, @"Broker nonce mismatch!", correlationID);
            return nil;
        }

        return [[MSIDAADV1BrokerResponse alloc] initWithDictionary:decryptedResponse error:error];
    }
    
    if (![self checkBrokerNonce:encryptedParams])
    {
        MSIDFillAndLogError(error, MSIDErrorBrokerMismatchedResumeState, @"Broker nonce mismatch!", correlationID);
        return nil;
    }

    NSString *userDisplayableId = nil;

    // In the case where Intune App Protection Policies are required, the broker may send back the Intune MAM Resource token
    if (encryptedParams[@"intune_mam_token_hash"] && encryptedParams[@"intune_mam_token"])
    {
        NSDictionary *intuneResponseDictionary = @{@"response": encryptedParams[@"intune_mam_token"],
                                                   @"hash": encryptedParams[@"intune_mam_token_hash"],
                                                   MSID_BROKER_PROTOCOL_VERSION_KEY: encryptedParams[MSID_BROKER_PROTOCOL_VERSION_KEY] ?: @(MSID_BROKER_PROTOCOL_VERSION_2)};

        NSDictionary *decryptedResponse = [self.brokerCryptoProvider decryptBrokerResponse:intuneResponseDictionary
                                                                             correlationId:correlationID
                                                                                     error:error];

        if (!decryptedResponse)
        {
            return nil;
        }

        NSError *intuneError = nil;
        MSIDAADV1BrokerResponse *brokerResponse = [[MSIDAADV1BrokerResponse alloc] initWithDictionary:decryptedResponse error:&intuneError];
        MSIDTokenResult *intuneResult = [self.tokenResponseValidator validateAndSaveBrokerResponse:brokerResponse
                                                                                         oidcScope:oidcScope
                                                                                  requestAuthority:self.providedAuthority
                                                                                     instanceAware:self.instanceAware
                                                                                      oauthFactory:self.oauthFactory
                                                                                        tokenCache:self.tokenCache
                                                                              accountMetadataCache:self.accountMetadataCacheAccessor
                                                                                     correlationID:correlationID
                                                                                  saveSSOStateOnly:brokerResponse.ignoreAccessTokenCache
                                                                                        authScheme:authScheme
                                                                                             error:&intuneError];

        if (!intuneResult)
        {
            MSID_LOG_WITH_CORR_PII(MSIDLogLevelWarning, correlationID, @"Unable to save intune token with error %@", MSID_PII_LOG_MASKABLE(intuneError));
        }
        else
        {
            userDisplayableId = intuneResult.account.username;
        }
    }

    // V1 protocol doesn't return encrypted response in the case of a failure
    MSIDAADV1BrokerResponse *brokerResponse = [[MSIDAADV1BrokerResponse alloc] initWithDictionary:encryptedParams error:error];

    if (!brokerResponse)
    {
        return nil;
    }

    NSError *brokerError = [self resultFromBrokerErrorResponse:brokerResponse userDisplayableId:userDisplayableId];

    if (error)
    {
        *error = brokerError;
    }

    return nil;
}

- (NSError *)resultFromBrokerErrorResponse:(MSIDAADV1BrokerResponse *)errorResponse userDisplayableId:(NSString *)userId
{
    NSUUID *correlationId = [[NSUUID alloc] initWithUUIDString:errorResponse.correlationId];
    NSString *errorDescription = errorResponse.errorDescription;

    if (!errorDescription)
    {
        errorDescription = @"Broker did not provide any details";
    }

    NSMutableDictionary *userInfo = [NSMutableDictionary new];

    NSString *errorCodeString = errorResponse.errorCode;
    NSInteger errorCode = MSIDErrorBrokerUnknown;

    if (errorCodeString && ![errorCodeString isEqualToString:@"0"])
    {
        errorCode = [errorCodeString integerValue];
    }

    userInfo[MSIDOAuthSubErrorKey] = errorResponse.subError;
    userInfo[MSIDUserDisplayableIdkey] = errorResponse.userId ? errorResponse.userId : userId;
    userInfo[MSIDBrokerVersionKey] = errorResponse.brokerAppVer;

    NSString *oauthErrorCode = errorResponse.oauthErrorCode;
    NSString *errorDomain = errorResponse.errorDomain ?: MSIDErrorDomain;

    if (errorResponse.httpHeaders)
    {
        NSDictionary *httpHeaders = [NSDictionary msidDictionaryFromWWWFormURLEncodedString:errorResponse.httpHeaders];
        userInfo[MSIDHTTPHeadersKey] = httpHeaders;
    }
    
    MSID_LOG_WITH_CORR_PII(MSIDLogLevelError, correlationId, @"Broker returned error with domain %@, code %@, oauth error %@, suberror %@, broker version %@, description %@", errorDomain, errorCodeString, oauthErrorCode, errorResponse.subError, errorResponse.brokerAppVer, MSID_PII_LOG_MASKABLE(errorDescription));

    NSError *brokerError = MSIDCreateError(errorDomain, errorCode, errorDescription, oauthErrorCode, errorResponse.subError, nil, correlationId, userInfo, NO);

    return brokerError;
}

- (MSIDAccountMetadataCacheAccessor *)accountMetadataCacheWithKeychainGroup:(__unused NSString *)keychainGroup
                                                                      error:(__unused NSError **)error
{
    return nil;
}

- (BOOL)canHandleBrokerResponse:(NSURL *)response
             hasCompletionBlock:(BOOL)hasCompletionBlock
{
    return [self canHandleBrokerResponse:response
                      hasCompletionBlock:hasCompletionBlock
                         protocolVersion:MSID_ADAL_BROKER_MESSAGE_VERSION
                                 sdkName:MSID_ADAL_SDK_NAME];
}

@end

#endif
