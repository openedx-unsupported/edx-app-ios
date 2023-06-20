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

#import "MSIDDefaultBrokerTokenRequest.h"
#import "MSIDInteractiveTokenRequestParameters.h"
#import "MSIDAccountIdentifier.h"
#import "NSMutableDictionary+MSIDExtensions.h"
#import "MSIDPromptType_Internal.h"
#import "MSIDAuthority.h"

@implementation MSIDDefaultBrokerTokenRequest

// Those parameters will be different depending on the broker protocol version
- (NSDictionary *)protocolPayloadContentsWithError:(__unused NSError **)error
{
    NSString *homeAccountId = self.requestParameters.accountIdentifier.homeAccountId;
    NSString *username = self.requestParameters.accountIdentifier.displayableId;
    
    NSMutableDictionary *extraQueryParameters = [NSMutableDictionary new];
    [extraQueryParameters addEntriesFromDictionary:[self.requestParameters allAuthorizeRequestExtraParametersWithMetadata:NO]];
    
    if (self.requestParameters.instanceAware)
    {
        extraQueryParameters[MSID_BROKER_INSTANCE_AWARE_KEY] = @"true";
    }

    NSString *extraQueryParametersString = [extraQueryParameters count] ? [extraQueryParameters msidWWWFormURLEncode] : @"";
    
    // if value is nil, it won't appear in the dictionary
    NSMutableDictionary *contents = [NSMutableDictionary new];
    [contents msidSetNonEmptyString:self.requestParameters.target forKey:@"scope"];
    [contents msidSetNonEmptyString:self.requestParameters.oidcScope forKey:MSID_BROKER_EXTRA_OIDC_SCOPES_KEY];
    [contents msidSetNonEmptyString:homeAccountId forKey:@"home_account_id"];
    [contents msidSetNonEmptyString:username forKey:@"username"];
    [contents msidSetNonEmptyString:self.requestParameters.loginHint forKey:MSID_BROKER_LOGIN_HINT_KEY];
    [contents msidSetNonEmptyString:extraQueryParametersString forKey:MSID_BROKER_EXTRA_QUERY_PARAM_KEY];
    [contents msidSetNonEmptyString:self.requestParameters.extraScopesToConsent forKey:MSID_BROKER_EXTRA_CONSENT_SCOPES_KEY];
    NSString *promptParam = MSIDPromptParamFromType(self.requestParameters.promptType);
    [contents msidSetNonEmptyString:promptParam forKey:MSID_BROKER_PROMPT_KEY];
    [contents setValue:@(MSID_BROKER_PROTOCOL_VERSION_3) forKey:MSID_BROKER_PROTOCOL_VERSION_KEY];
    
    return contents;
}

- (NSDictionary *)protocolResumeDictionaryContents
{
    NSMutableDictionary *protocolResumeDictionary = [NSMutableDictionary new];
    [protocolResumeDictionary msidSetNonEmptyString:self.requestParameters.target ?: @"" forKey:@"scope"];
    [protocolResumeDictionary msidSetNonEmptyString:self.requestParameters.oidcScope ?: @"" forKey:@"oidc_scope"];
    [protocolResumeDictionary msidSetNonEmptyString:MSID_MSAL_SDK_NAME forKey:MSID_SDK_NAME_KEY];
    [protocolResumeDictionary msidSetNonEmptyString:self.requestParameters.providedAuthority.url.absoluteString forKey:@"provided_authority_url"];
    [protocolResumeDictionary msidSetNonEmptyString:self.requestParameters.instanceAware ? @"YES" : @"NO" forKey:@"instance_aware"];
    
    return protocolResumeDictionary;
}

@end
