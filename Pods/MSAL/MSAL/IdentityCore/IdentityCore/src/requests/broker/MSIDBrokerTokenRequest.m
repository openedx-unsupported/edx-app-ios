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

#import "MSIDBrokerTokenRequest.h"
#import "MSIDInteractiveTokenRequestParameters.h"
#import "MSIDVersion.h"
#import "MSIDIntuneEnrollmentIdsCache.h"
#import "MSIDIntuneMAMResourcesCache.h"
#import "MSIDAuthority.h"
#import "NSDictionary+MSIDExtensions.h"
#import "MSIDConstants.h"
#import "NSString+MSIDExtensions.h"
#import "NSMutableDictionary+MSIDExtensions.h"
#import "MSIDClaimsRequest.h"
#import "MSIDAuthenticationScheme.h"

#if TARGET_OS_IPHONE
#import "MSIDKeychainTokenCache.h"
#endif

@interface MSIDBrokerTokenRequest()

@property (nonatomic, readwrite) MSIDInteractiveTokenRequestParameters *requestParameters;
@property (nonatomic, readwrite) NSDictionary *resumeDictionary;
@property (nonatomic, readwrite) NSString *brokerKey;
@property (nonatomic, readwrite) NSURL *brokerRequestURL;
@property (nonatomic, readwrite) NSString *brokerNonce;
@property (nonatomic, readwrite) NSString *brokerApplicationToken;

@end

@implementation MSIDBrokerTokenRequest

#pragma mark - Init

- (instancetype)initWithRequestParameters:(MSIDInteractiveTokenRequestParameters *)parameters
                                brokerKey:(NSString *)brokerKey
                   brokerApplicationToken:(NSString *)brokerApplicationToken
                          sdkCapabilities:(NSArray *)sdkCapabilities
                                    error:(NSError **)error
{
    self = [super init];

    if (self)
    {
        _requestParameters = parameters;
        _brokerKey = brokerKey;
        _brokerNonce = [[NSUUID new] UUIDString];
        _brokerApplicationToken = brokerApplicationToken;
        _sdkBrokerCapabilities = sdkCapabilities;

        if (![self initPayloadContentsWithError:error])
        {
            return nil;
        }

        [self initResumeDictionary];
    }

    return self;
}

- (BOOL)initPayloadContentsWithError:(NSError **)error
{
    NSMutableDictionary *contents = [NSMutableDictionary new];

    NSDictionary *defaultContents = [self defaultPayloadContents:error];

    if (!defaultContents)
    {
        return NO;
    }

    [contents addEntriesFromDictionary:defaultContents];

    NSDictionary *protocolContents = [self protocolPayloadContentsWithError:error];

    if (!protocolContents)
    {
        return NO;
    }

    [contents addEntriesFromDictionary:protocolContents];

    NSString *query = [NSString msidWWWFormURLEncodedStringFromDictionary:contents];

    NSURL *brokerRequestURL = [[NSURL alloc] initWithString:[NSString stringWithFormat:@"%@?%@", self.requestParameters.brokerInvocationOptions.brokerBaseUrlString, query]];

    if (!brokerRequestURL)
    {
        if (error)
        {
            *error = MSIDCreateError(MSIDErrorDomain, MSIDErrorInternal, @"Unable to create broker request URL", nil, nil, nil, self.requestParameters.correlationId, nil, YES);
        }

        MSID_LOG_WITH_CTX_PII(MSIDLogLevelError, self.requestParameters, @"Unable to create broker request URL with contents %@", MSID_EUII_ONLY_LOG_MASKABLE(contents));
        return NO;
    }

    _brokerRequestURL = brokerRequestURL;
    return YES;
}

- (void)initResumeDictionary
{
    NSMutableDictionary *contents = [NSMutableDictionary new];
    [contents addEntriesFromDictionary:[self defaultResumeDictionaryContents]];
    [contents addEntriesFromDictionary:[self protocolResumeDictionaryContents]];

    _resumeDictionary = contents;
}

#pragma mark - Default contents

- (NSDictionary *)defaultPayloadContents:(NSError **)error
{
    if (![self checkParameter:self.requestParameters.authority parameterName:@"authority" error:error]) return nil;
    if (![self checkParameter:self.requestParameters.target parameterName:@"target" error:error]) return nil;
    if (![self checkParameter:self.requestParameters.clientId parameterName:@"clientId" error:error]) return nil;
    if (![self checkParameter:self.requestParameters.redirectUri parameterName:@"redirectUri" error:error]) return nil;
    if (![self checkParameter:self.requestParameters.correlationId parameterName:@"correlationId" error:error]) return nil;
    if (![self checkParameter:self.brokerKey parameterName:@"brokerKey" error:error]) return nil;

    NSString *enrollmentIds = [self intuneEnrollmentIdsParameter];
    NSString *mamResources = [self intuneMAMResourceParameter];

    NSString *capabilities = [self.requestParameters.clientCapabilities componentsJoinedByString:@","];
    NSDictionary *clientMetadata = self.requestParameters.appRequestMetadata;
    NSString *claimsString = [self claimsParameter];
    NSString *clientAppName = clientMetadata[MSID_APP_NAME_KEY];
    NSString *clientAppVersion = clientMetadata[MSID_APP_VER_KEY];
    NSDictionary *schemeParameters = self.requestParameters.authScheme.schemeParameters;
    NSString *tokenType = schemeParameters[MSID_OAUTH2_TOKEN_TYPE];
    NSString *requestConf = schemeParameters[MSID_OAUTH2_REQUEST_CONFIRMATION];
    
    NSMutableDictionary *queryDictionary = [NSMutableDictionary new];
    [queryDictionary msidSetNonEmptyString:self.requestParameters.authority.url.absoluteString forKey:@"authority"];
    [queryDictionary msidSetNonEmptyString:self.requestParameters.clientId forKey:@"client_id"];
    [queryDictionary msidSetNonEmptyString:self.requestParameters.redirectUri forKey:@"redirect_uri"];
    [queryDictionary msidSetNonEmptyString:self.requestParameters.correlationId.UUIDString forKey:@"correlation_id"];
#if TARGET_OS_IPHONE
    [queryDictionary msidSetNonEmptyString:self.brokerKey forKey:@"broker_key"];
    [queryDictionary msidSetNonEmptyString:self.brokerNonce forKey:@"broker_nonce"];
#endif
    [queryDictionary msidSetNonEmptyString:[MSIDVersion sdkVersion] forKey:@"client_version"];
    [queryDictionary msidSetNonEmptyString:claimsString forKey:@"claims"];
    [queryDictionary msidSetNonEmptyString:enrollmentIds forKey:@"intune_enrollment_ids"];
    [queryDictionary msidSetNonEmptyString:mamResources forKey:@"intune_mam_resource"];
    [queryDictionary msidSetNonEmptyString:capabilities forKey:@"client_capabilities"];
    [queryDictionary msidSetNonEmptyString:clientAppName forKey:@"client_app_name"];
    [queryDictionary msidSetNonEmptyString:clientAppVersion forKey:@"client_app_version"];
    [queryDictionary msidSetNonEmptyString:self.brokerApplicationToken forKey:@"application_token"];
    [queryDictionary msidSetNonEmptyString:tokenType forKey:MSID_OAUTH2_TOKEN_TYPE];
    [queryDictionary msidSetNonEmptyString:requestConf forKey:MSID_OAUTH2_REQUEST_CONFIRMATION];
    
    if ([self.sdkBrokerCapabilities count])
    {
        NSString *capabilitiesString = [self.sdkBrokerCapabilities componentsJoinedByString:@","];
        [queryDictionary msidSetNonEmptyString:capabilitiesString forKey:MSID_BROKER_SDK_CAPABILITIES_KEY];
    }

    return queryDictionary;
}

- (NSDictionary *)defaultResumeDictionaryContents
{
    NSMutableDictionary *resumeDictionary = [NSMutableDictionary new];
    [resumeDictionary msidSetNonEmptyString:self.requestParameters.authority.url.absoluteString forKey:@"authority"];
    [resumeDictionary msidSetNonEmptyString:self.requestParameters.clientId forKey:@"client_id"];
    [resumeDictionary msidSetNonEmptyString:self.requestParameters.redirectUri forKey:@"redirect_uri"];
    [resumeDictionary msidSetNonEmptyString:self.requestParameters.correlationId.UUIDString forKey:@"correlation_id"];
#if TARGET_OS_IPHONE
    [resumeDictionary msidSetNonEmptyString:self.requestParameters.keychainAccessGroup ?: MSIDKeychainTokenCache.defaultKeychainGroup forKey:@"keychain_group"];
    [resumeDictionary msidSetNonEmptyString:self.brokerNonce forKey:@"broker_nonce"];
#endif
    NSDictionary *schemeParameters = self.requestParameters.authScheme.schemeParameters;
    NSString *tokenType = schemeParameters[MSID_OAUTH2_TOKEN_TYPE];
    NSString *requestConf = schemeParameters[MSID_OAUTH2_REQUEST_CONFIRMATION];
    [resumeDictionary msidSetNonEmptyString:tokenType forKey:MSID_OAUTH2_TOKEN_TYPE];
    [resumeDictionary msidSetNonEmptyString:requestConf forKey:MSID_OAUTH2_REQUEST_CONFIRMATION];
    
    return resumeDictionary;
}

- (BOOL)checkParameter:(id)parameter
         parameterName:(NSString *)parameterName
                 error:(NSError **)error
{
    if (!parameter)
    {
        NSString *errorDescription = [NSString stringWithFormat:@"%@ is nil, but is a required parameter", parameterName];
        MSID_LOG_WITH_CTX(MSIDLogLevelError, self.requestParameters, @"%@", errorDescription);

        if (error)
        {
            *error = MSIDCreateError(MSIDErrorDomain, MSIDErrorInvalidDeveloperParameter, errorDescription, nil, nil, nil, self.requestParameters.correlationId, nil, NO);
        }

        return NO;
    }

    return YES;
}

#pragma mark - Helpers

- (NSString *)claimsParameter
{
    NSDictionary *claimJsonDictionary = [self.requestParameters.claimsRequest jsonDictionary];
    if (!claimJsonDictionary)
    {
        return nil;
    }

    NSString *claimsString = [claimJsonDictionary msidJSONSerializeWithContext:self.requestParameters];

    if (!claimsString)
    {
        MSID_LOG_WITH_CTX(MSIDLogLevelWarning,self.requestParameters, @"Failed to serialize claims parameter");
        return nil;
    }

    return [claimsString msidWWWFormURLEncode];
}

- (NSString *)intuneEnrollmentIdsParameter
{
    NSError *cacheError = nil;
    NSDictionary *enrollmentIds = [[MSIDIntuneEnrollmentIdsCache sharedCache] enrollmentIdsJsonDictionaryWithContext:self.requestParameters
                                                                                                               error:&cacheError];

    if (cacheError)
    {
        MSID_LOG_WITH_CTX_PII(MSIDLogLevelError, self.requestParameters, @"Failed to retrieve valid intune enrollment IDs with error %@", MSID_PII_LOG_MASKABLE(cacheError));
        return nil;
    }

    return [enrollmentIds msidJSONSerializeWithContext:self.requestParameters];
}

- (NSString *)intuneMAMResourceParameter
{
    NSError *cacheError = nil;
    NSDictionary *mamResources = [[MSIDIntuneMAMResourcesCache sharedCache] resourcesJsonDictionaryWithContext:self.requestParameters
                                                                                                         error:&cacheError];

    if (cacheError)
    {
        MSID_LOG_WITH_CTX_PII(MSIDLogLevelError, self.requestParameters, @"Failed to retrieve valid intune MAM resource with error %@", MSID_PII_LOG_MASKABLE(cacheError));
        return nil;
    }

    return [mamResources msidJSONSerializeWithContext:self.requestParameters];
}

- (NSString *)brokerNonce
{
    if (!_brokerNonce)
    {
        _brokerNonce = [[NSUUID new] UUIDString];
    }
    
    return _brokerNonce;
}

#pragma mark - Abstract

// Thos parameters will be different depending on the broker protocol version
- (NSDictionary *)protocolPayloadContentsWithError:(__unused NSError **)error
{
    return @{};
}

- (NSDictionary *)protocolResumeDictionaryContents
{
    return @{};
}

@end
