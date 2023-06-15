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

#import "MSIDLegacyBrokerTokenRequest.h"
#import "MSIDInteractiveTokenRequestParameters.h"
#import "MSIDAccountIdentifier.h"
#import "NSMutableDictionary+MSIDExtensions.h"
#import "MSIDClaimsRequest.h"
#import "MSIDConstants.h"

@implementation MSIDLegacyBrokerTokenRequest

#pragma mark - Abstract impl

// Those parameters will be different depending on the broker protocol version
- (NSDictionary *)protocolPayloadContentsWithError:(__unused NSError **)error
{
    NSString *skipCacheValue = @"NO";

    if (self.requestParameters.claimsRequest.hasClaims)
    {
        skipCacheValue = @"YES";
    }

    NSString *usernameType = @"";
    NSString *username = @"";

    if (self.requestParameters.accountIdentifier.displayableId)
    {
        username = self.requestParameters.accountIdentifier.displayableId;
        usernameType = [MSIDAccountIdentifier legacyAccountIdentifierTypeAsString:self.requestParameters.accountIdentifier.legacyAccountIdentifierType];
    }
    else if (self.requestParameters.loginHint)
    {
        username = self.requestParameters.loginHint;
        usernameType = [MSIDAccountIdentifier legacyAccountIdentifierTypeAsString:MSIDLegacyIdentifierTypeOptionalDisplayableId];
    }
    
    NSString *extraQueryParameters = [self.requestParameters.extraAuthorizeURLQueryParameters count] ? [self.requestParameters.extraAuthorizeURLQueryParameters msidWWWFormURLEncode] : @"";

    NSMutableDictionary *contents = [NSMutableDictionary new];
    [contents msidSetNonEmptyString:extraQueryParameters forKey:@"extra_qp"];
    [contents msidSetNonEmptyString:skipCacheValue forKey:@"skip_cache"];
    [contents msidSetNonEmptyString:self.requestParameters.target forKey:@"resource"];
    [contents msidSetNonEmptyString:username forKey:@"username"];
    [contents msidSetNonEmptyString:usernameType forKey:@"username_type"];
    [contents setValue:MSID_ADAL_BROKER_MESSAGE_VERSION forKey:MSID_BROKER_MAX_PROTOCOL_VERSION];
    [contents setValue:self.requestParameters.uiBehaviorType == MSIDUIBehaviorForceType ? @"YES" : @"NO" forKey:@"force"];

    return contents;
}

- (NSDictionary *)protocolResumeDictionaryContents
{
    return @{@"resource": self.requestParameters.target ?: @"",
             MSID_SDK_NAME_KEY: MSID_ADAL_SDK_NAME};
}

@end

#endif
