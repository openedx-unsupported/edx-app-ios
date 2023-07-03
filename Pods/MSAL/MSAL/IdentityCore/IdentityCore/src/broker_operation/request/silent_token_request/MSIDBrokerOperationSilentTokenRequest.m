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

#if MSID_ENABLE_SSO_EXTENSION
#import <AuthenticationServices/ASAuthorizationOpenIDRequest.h>
#import "MSIDBrokerOperationSilentTokenRequest.h"
#import "MSIDJsonSerializableFactory.h"
#import "MSIDConstants.h"
#import "MSIDAccountIdentifier.h"
#import "MSIDRequestParameters.h"
#import "MSIDJsonSerializableTypes.h"
#import "MSIDThumbprintCalculator.h"
#import "MSIDConfiguration.h"


static NSString *const MSID_ACCOUNT_HOME_ID_JSON_KEY = @"home_account_id";
static NSString *const MSID_ACCOUNT_DISPLAYABLE_ID_JSON_KEY = @"username";

@implementation MSIDBrokerOperationSilentTokenRequest

+ (void)load
{
    if (@available(iOS 13.0, macOS 10.15, *))
    {
        [MSIDJsonSerializableFactory registerClass:self forClassType:self.operation];
    }
}

+ (instancetype)tokenRequestWithParameters:(MSIDRequestParameters *)parameters
                              providerType:(MSIDProviderType)providerType
                             enrollmentIds:(NSDictionary *)enrollmentIds
                              mamResources:(NSDictionary *)mamResources
{
    __auto_type request = [MSIDBrokerOperationSilentTokenRequest new];
    [self fillRequest:request withParameters:parameters providerType:providerType enrollmentIds:enrollmentIds mamResources:mamResources];
    
    request.accountIdentifier = parameters.accountIdentifier;
    
    return request;
}

#pragma mark - MSIDBrokerOperationRequest

+ (NSString *)operation
{
    if (@available(iOS 13.0, macOS 10.15, *))
    {
        return ASAuthorizationOperationRefresh;
    }
    
    return @"refresh";
}

#pragma mark - MSIDJsonSerializable

- (instancetype)initWithJSONDictionary:(NSDictionary *)json error:(NSError **)error
{
    self = [super initWithJSONDictionary:json error:error];
    
    if (self)
    {
        _accountIdentifier = [[MSIDAccountIdentifier alloc] initWithJSONDictionary:json error:error];
        if (!_accountIdentifier)
        {
            MSID_LOG_WITH_CORR(MSIDLogLevelError, self.correlationId, @"Failed to create json for %@ class, accountIdentifier is nil.", self.class);
            return nil;
        }
    }
    
    return self;
}

- (NSDictionary *)jsonDictionary
{
    NSMutableDictionary *json = [[super jsonDictionary] mutableCopy];
    if (!json) return nil;
    
    NSDictionary *accountIdentifierJson = [self.accountIdentifier jsonDictionary];
    if (!accountIdentifierJson) return nil;
    
    [json addEntriesFromDictionary:accountIdentifierJson];
    
    return json;
}

- (NSString *)fullRequestThumbprint
{
    return [MSIDThumbprintCalculator calculateThumbprint:[self jsonDictionary]
                                            filteringSet:[MSIDBrokerOperationSilentTokenRequest fullRequestThumbprintExcludeParams]
                                       shouldIncludeKeys:NO];
}

- (NSString *)strictRequestThumbprint
{
    return [MSIDThumbprintCalculator calculateThumbprint:[self jsonDictionary]
                                            filteringSet:[MSIDBrokerOperationSilentTokenRequest strictRequestThumbprintIncludeParams]
                                       shouldIncludeKeys:YES];
}


+ (NSSet *)fullRequestThumbprintExcludeParams
{
    static dispatch_once_t once_token;
    static NSSet *excludeSet;
    
    dispatch_once(&once_token, ^{
        excludeSet = [NSSet setWithArray:@[MSID_ACCOUNT_DISPLAYABLE_ID_JSON_KEY, //since we already use home account id, this is redundant
                                           MSID_BROKER_CLIENT_CAPABILITIES_KEY,
                                           MSID_BROKER_CLIENT_VERSION_KEY,
                                           MSID_BROKER_CLIENT_APP_VERSION_KEY,
                                           MSID_BROKER_CLIENT_APP_NAME_KEY,
                                           MSID_BROKER_CORRELATION_ID_KEY,
                                           MSID_BROKER_KEY]];
    });
    return excludeSet;
    
}

+ (NSSet *)strictRequestThumbprintIncludeParams
{
    static dispatch_once_t once_token;
    static NSSet *includeSet;
    
    dispatch_once(&once_token, ^{
        includeSet = [NSSet setWithArray:@[MSID_CLIENT_ID_JSON_KEY, MSID_SCOPE_JSON_KEY, MSID_AUTHORITY_URL_JSON_KEY, MSID_ACCOUNT_HOME_ID_JSON_KEY]];
    });
    return includeSet;
    
}


@end
#endif
