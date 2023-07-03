//------------------------------------------------------------------------------
//
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
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.
//
//------------------------------------------------------------------------------

#import "MSIDBrokerOperationSignoutFromDeviceRequest.h"
#import "MSIDConfiguration.h"
#import "MSIDBrokerConstants.h"
#import "MSIDJsonSerializableFactory.h"
#import "MSIDJsonSerializableTypes.h"

NSString *const MSID_SIGNOUT_FROM_BROWSER_KEY = @"signout_from_browser";
NSString *const MSID_CLEAR_SSO_EXT_COOKIES_KEY = @"clear_sso_extension_cookies";
NSString *const MSID_WIPE_ACCOUNT_KEY = @"wipe_account";
NSString *const MSID_WIPE_CACHE_ALL_ACCOUNTS_KEY = @"wipe_cache_all_accounts";

@implementation MSIDBrokerOperationSignoutFromDeviceRequest

+ (void)load
{
    [MSIDJsonSerializableFactory registerClass:self forClassType:self.operation];
}

#pragma mark - MSIDBrokerOperationRequest

+ (NSString *)operation
{
    return MSID_JSON_TYPE_OPERATION_REQUEST_SIGNOUT_ACCOUNT;
}

#pragma mark - MSIDJsonSerializable

- (instancetype)initWithJSONDictionary:(NSDictionary *)json error:(NSError **)error
{
    self = [super initWithJSONDictionary:json error:error];
    
    if (self)
    {
        MSIDAuthority *authority = (MSIDAuthority *)[MSIDJsonSerializableFactory createFromJSONDictionary:json classTypeJSONKey:MSID_PROVIDER_TYPE_JSON_KEY assertKindOfClass:MSIDAuthority.class error:error];
        if (!authority) return nil;

        _authority = authority;
        
        if (![json msidAssertType:NSString.class ofKey:MSID_REDIRECT_URI_JSON_KEY required:YES error:error]) return nil;
        
        _redirectUri = [json msidStringObjectForKey:MSID_REDIRECT_URI_JSON_KEY];
        _providerType = MSIDProviderTypeFromString([json msidStringObjectForKey:MSID_PROVIDER_TYPE_JSON_KEY]);
        _signoutFromBrowser = [json msidBoolObjectForKey:MSID_SIGNOUT_FROM_BROWSER_KEY];
        _clearSSOExtensionCookies = [json msidBoolObjectForKey:MSID_CLEAR_SSO_EXT_COOKIES_KEY];
        _wipeAccount = [json msidBoolObjectForKey:MSID_WIPE_ACCOUNT_KEY];
        _wipeCacheForAllAccounts = [json msidBoolObjectForKey:MSID_WIPE_CACHE_ALL_ACCOUNTS_KEY];
    }
    
    return self;
}

- (NSDictionary *)jsonDictionary
{
    NSMutableDictionary *json = [[super jsonDictionary] mutableCopy];
    if (!json) return nil;
    
    NSDictionary *authorityJson = [self.authority jsonDictionary];
    
    if (!authorityJson)
    {
        MSID_LOG_WITH_CORR(MSIDLogLevelError, nil, @"Failed to create json for %@ class, authority json is nil.", self.class);
        return nil;
    }
    [json addEntriesFromDictionary:authorityJson];
    json[MSID_REDIRECT_URI_JSON_KEY] = self.redirectUri;
    
    if (!self.redirectUri)
    {
        MSID_LOG_WITH_CORR(MSIDLogLevelError, nil, @"Failed to create json for %@ class, redirectUri is nil.", self.class);
        return nil;
    }
    
    json[MSID_PROVIDER_TYPE_JSON_KEY] = MSIDProviderTypeToString(self.providerType);
    json[MSID_SIGNOUT_FROM_BROWSER_KEY] = [NSString stringWithFormat:@"%d", (int)_signoutFromBrowser];
    json[MSID_CLEAR_SSO_EXT_COOKIES_KEY] = [NSString stringWithFormat:@"%d", (int)_clearSSOExtensionCookies];
    json[MSID_WIPE_ACCOUNT_KEY] = [NSString stringWithFormat:@"%d", (int)_wipeAccount];
    json[MSID_WIPE_CACHE_ALL_ACCOUNTS_KEY] = [NSString stringWithFormat:@"%d", (int)_wipeCacheForAllAccounts];
    
    return json;
}

@end
