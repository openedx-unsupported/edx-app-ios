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
#import "MSIDBrokerOperationInteractiveTokenRequest.h"
#import "MSIDPromptType_Internal.h"
#import "MSIDJsonSerializableFactory.h"
#import "MSIDPromptType_Internal.h"
#import "MSIDAccountIdentifier.h"
#import "MSIDInteractiveTokenRequestParameters.h"

@implementation MSIDBrokerOperationInteractiveTokenRequest

+ (void)load
{
    if (@available(iOS 13.0, macOS 10.15, *))
    {
        [MSIDJsonSerializableFactory registerClass:self forClassType:self.operation];
    }
}

+ (instancetype)tokenRequestWithParameters:(MSIDInteractiveTokenRequestParameters *)parameters
                              providerType:(MSIDProviderType)providerType
                             enrollmentIds:(NSDictionary *)enrollmentIds
                              mamResources:(NSDictionary *)mamResources
{
    __auto_type request = [MSIDBrokerOperationInteractiveTokenRequest new];
    [self fillRequest:request withParameters:parameters providerType:providerType enrollmentIds:enrollmentIds mamResources:mamResources];
    
    request.accountIdentifier = parameters.accountIdentifier;
    if (!request.accountIdentifier && parameters.loginHint)
    {
        request.accountIdentifier = [[MSIDAccountIdentifier alloc] initWithDisplayableId:parameters.loginHint homeAccountId:nil];
    }
    request.promptType = parameters.promptType;
    request.extraQueryParameters = [parameters allAuthorizeRequestExtraParametersWithMetadata:NO];
    request.extraScopesToConsent = parameters.extraScopesToConsent;
    
    return request;
}

#pragma mark - MSIDBrokerOperationRequest

+ (NSString *)operation
{
    if (@available(iOS 13.0, macOS 10.15, *))
    {
        return ASAuthorizationOperationLogin;
    }
    
    return @"login";
}

#pragma mark - MSIDJsonSerializable

- (instancetype)initWithJSONDictionary:(NSDictionary *)json error:(NSError **)error
{
    self = [super initWithJSONDictionary:json error:error];
    
    if (self)
    {
        // We have flat json dictionary, that is why we are passing the whole json to the MSIDAccountIdentifier.
        _accountIdentifier = [[MSIDAccountIdentifier alloc] initWithJSONDictionary:json error:nil];
        
        NSString *promptString = [json msidStringObjectForKey:MSID_BROKER_PROMPT_KEY];
        _promptType = MSIDPromptTypeFromString(promptString);
        _extraScopesToConsent = [json msidStringObjectForKey:MSID_BROKER_EXTRA_CONSENT_SCOPES_KEY];
    }
    
    return self;
}

- (NSDictionary *)jsonDictionary
{
    NSMutableDictionary *json = [[super jsonDictionary] mutableCopy];
    if (!json) return nil;
    
    NSDictionary *accountIdentifierJson = [self.accountIdentifier jsonDictionary];
    if (accountIdentifierJson) [json addEntriesFromDictionary:accountIdentifierJson];
    
    NSString *promptString = MSIDPromptParamFromType(self.promptType);
    json[MSID_BROKER_PROMPT_KEY] = promptString;
    json[MSID_BROKER_EXTRA_CONSENT_SCOPES_KEY] = self.extraScopesToConsent;
    
    return json;
}

@end
#endif
