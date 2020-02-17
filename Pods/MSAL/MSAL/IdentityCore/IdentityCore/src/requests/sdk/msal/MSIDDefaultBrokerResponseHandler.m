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

#import "MSIDDefaultBrokerResponseHandler.h"
#import "MSIDLegacyTokenCacheAccessor.h"
#import "MSIDDefaultTokenCacheAccessor.h"
#import "MSIDBrokerCryptoProvider.h"
#import "MSIDAADV2BrokerResponse.h"
#import "MSIDDefaultTokenResponseValidator.h"
#import "MSIDTokenResult.h"
#import "MSIDAccount.h"
#import "MSIDConstants.h"
#import "MSIDBrokerResponseHandler+Internal.h"

#if TARGET_OS_IPHONE
#import "MSIDKeychainTokenCache.h"
#endif

@implementation MSIDDefaultBrokerResponseHandler
{
    NSDictionary *_userInfoKeyMapping;
}

- (instancetype)initWithOauthFactory:(MSIDOauth2Factory *)factory
              tokenResponseValidator:(MSIDTokenResponseValidator *)responseValidator
{
    self = [super initWithOauthFactory:factory tokenResponseValidator:responseValidator];
    
    if (self)
    {
        _userInfoKeyMapping = @{@"correlation_id" : MSIDCorrelationIdKey,
                                @"http_response_headers" : MSIDHTTPHeadersKey,
                                @"http_response_code" : MSIDHTTPResponseCodeKey,
                                @"x-broker-app-ver" : MSIDBrokerVersionKey,
                                @"username" : MSIDUserDisplayableIdkey,
                                @"home_account_id" : MSIDHomeAccountIdkey,
                                @"declined_scopes" : MSIDDeclinedScopesKey,
                                @"granted_scopes" : MSIDGrantedScopesKey,
                                };
    }
    
    return self;
}

#pragma mark - Abstract impl

- (MSIDBrokerResponse *)brokerResponseFromEncryptedQueryParams:(NSDictionary *)encryptedParams
                                                     oidcScope:(NSString *)oidcScope
                                                 correlationId:(NSUUID *)correlationID
                                                         error:(NSError **)error
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
    
    // Save additional tokens,
    // assuming they could come in both successful case and failure case.
    if (decryptedResponse[@"additional_tokens"])
    {
        MSIDTokenResult *tokenResult = nil;
        NSError *additionalTokensError = nil;
        
        NSDictionary *additionalTokensDict = [decryptedResponse[@"additional_tokens"] msidJson];
        if (additionalTokensDict)
        {
            MSIDAADV2BrokerResponse *brokerResponse = [[MSIDAADV2BrokerResponse alloc] initWithDictionary:additionalTokensDict error:&additionalTokensError];
            
            if (!additionalTokensError)
            {
                tokenResult = [self.tokenResponseValidator validateAndSaveBrokerResponse:brokerResponse
                                                                               oidcScope:oidcScope
                                                                            oauthFactory:self.oauthFactory
                                                                              tokenCache:self.tokenCache
                                                                           correlationID:correlationID
                                                                                   error:&additionalTokensError];
            }
        }
        else
        {
            additionalTokensError = MSIDCreateError(MSIDErrorDomain, MSIDErrorBrokerCorruptedResponse, @"Unable to parse additional tokens.", nil, nil, nil, nil, nil, YES);
        }
        
        if (!tokenResult)
        {
            MSID_LOG_WITH_CORR_PII(MSIDLogLevelWarning, correlationID, @"Unable to save additional token with error %@", MSID_PII_LOG_MASKABLE(additionalTokensError));
        }
    }
    
    // Successful case
    if ([NSString msidIsStringNilOrBlank:decryptedResponse[@"broker_error_domain"]]
        && [decryptedResponse[@"success"] boolValue])
    {
        return [[MSIDAADV2BrokerResponse alloc] initWithDictionary:decryptedResponse error:error];
    }
    
    // Failure case
    MSIDAADV2BrokerResponse *brokerResponse = [[MSIDAADV2BrokerResponse alloc] initWithDictionary:decryptedResponse error:error];
    
    if (!brokerResponse)
    {
        return nil;
    }
    
    NSError *brokerError = [self resultFromBrokerErrorResponse:brokerResponse];
    
    if (error)
    {
        *error = brokerError;
    }
    
    return nil;
}

- (id<MSIDCacheAccessor>)cacheAccessorWithKeychainGroup:(__unused NSString *)keychainGroup
                                                  error:(NSError **)error
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
    
    MSIDLegacyTokenCacheAccessor *otherAccessor = [[MSIDLegacyTokenCacheAccessor alloc] initWithDataSource:dataSource otherCacheAccessors:nil];
    MSIDDefaultTokenCacheAccessor *cache = [[MSIDDefaultTokenCacheAccessor alloc] initWithDataSource:dataSource otherCacheAccessors:@[otherAccessor]];
    return cache;
#else
    if (error)
    {
        *error = MSIDCreateError(MSIDErrorDomain, MSIDErrorInternal, @"Broker responses not supported on macOS", nil, nil, nil, nil, nil, YES);
    }
    
    return nil;
#endif
}

- (NSError *)resultFromBrokerErrorResponse:(MSIDAADV2BrokerResponse *)errorResponse
{
    NSString *errorDomain = errorResponse.errorDomain;
    
    NSString *errorCodeString = errorResponse.errorCode;
    NSInteger errorCode = MSIDErrorBrokerUnknown;
    if (errorCodeString && ![errorCodeString isEqualToString:@"0"])
    {
        errorCode = [errorCodeString integerValue];
    }
    
    NSString *errorDescription = errorResponse.errorDescription;
    if (!errorDescription)
    {
        errorDescription = @"Broker did not provide any details";
    }
    
    NSString *oauthErrorCode = errorResponse.oauthErrorCode;
    NSString *subError = errorResponse.subError;
    NSUUID *correlationId = [[NSUUID alloc] initWithUUIDString:errorResponse.correlationId];
    
    //Add string-type error metadata to userInfo
    NSMutableDictionary *userInfo = [NSMutableDictionary new];
    for (NSString *metadataKey in errorResponse.errorMetadata.allKeys)
    {
        NSString *userInfokey = _userInfoKeyMapping[metadataKey];
        if (userInfokey)
        {
            [userInfo setValue:errorResponse.errorMetadata[metadataKey] forKey:userInfokey];
        }
    }
    //Special handling for non-string error metadata
    NSDictionary *httpHeaders = [NSDictionary msidDictionaryFromWWWFormURLEncodedString:errorResponse.httpHeaders];
    if (httpHeaders)
        userInfo[MSIDHTTPHeadersKey] = httpHeaders;
    
    userInfo[MSIDBrokerVersionKey] = errorResponse.brokerAppVer;
    
    MSID_LOG_WITH_CORR_PII(MSIDLogLevelError, correlationId, @"Broker failed with error domain %@, error code %@, oauth error %@, sub error %@, description %@", errorDomain, errorCodeString, oauthErrorCode, subError, MSID_PII_LOG_MASKABLE(errorDescription));

    NSError *brokerError = MSIDCreateError(errorDomain, errorCode, errorDescription, oauthErrorCode, subError, nil, correlationId, userInfo, NO);
    
    return brokerError;
}

- (BOOL)canHandleBrokerResponse:(NSURL *)response
             hasCompletionBlock:(BOOL)hasCompletionBlock
{
    return [self canHandleBrokerResponse:response
                      hasCompletionBlock:hasCompletionBlock
                         protocolVersion:MSID_MSAL_BROKER_MESSAGE_VERSION
                                 sdkName:MSID_MSAL_SDK_NAME];
}

@end
