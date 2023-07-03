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
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.


#import "MSIDBrokerOperationGetSsoCookiesRequest.h"
#import "MSIDAccountIdentifier.h"
#import "MSIDJsonSerializableFactory.h"
#import "MSIDJsonSerializableTypes.h"
#import "MSIDConstants.h"
#import "NSString+MSIDExtensions.h"

@implementation MSIDBrokerOperationGetSsoCookiesRequest

+ (void)load
{
    [MSIDJsonSerializableFactory registerClass:self forClassType:self.operation];
}

#pragma mark - MSIDBrokerOperationRequest

+ (NSString *)operation
{
    return MSID_JSON_TYPE_OPERATION_REQUEST_GET_SSO_COOKIES;
}

#pragma mark - MSIDJsonSerializable

- (instancetype)initWithJSONDictionary:(NSDictionary *)json error:(NSError **)error
{
    self = [super initWithJSONDictionary:json error:error];
    
    if (self)
    {
        _ssoUrl = [json msidStringObjectForKey:MSID_BROKER_SSO_URL];
        if ([NSString msidIsStringNilOrBlank:_ssoUrl])
        {
            if (error)
            {
                *error = MSIDCreateError(MSIDErrorDomain, MSIDErrorInternal, @"sso_url is missing in get Sso Cookies operation call.", nil, nil, nil, nil, nil, YES);
            }
            
            return nil;
        }
        
        _accountIdentifier = [[MSIDAccountIdentifier alloc] initWithJSONDictionary:json error:nil];
        if (_accountIdentifier && [NSString msidIsStringNilOrBlank:_accountIdentifier.homeAccountId])
        {
            if (error)
            {
                *error = MSIDCreateError(MSIDErrorDomain, MSIDErrorInternal, @"Account is provided, but no homeAccountId is provided from account identifier.", nil, nil, nil, nil, nil, YES);
            }
            
            return  nil;
        }
        
        NSString *headerTypesStr = json[MSID_BROKER_TYPES_OF_HEADER];
        if ([NSString msidIsStringNilOrBlank:headerTypesStr])
        {
            if (error)
            {
                *error = MSIDCreateError(MSIDErrorDomain, MSIDErrorInternal, @"Types of header for sso cookie request is missing.", nil, nil, nil, nil, nil, YES);
            }
            
            return  nil;
        }
        _headerTypes = headerTypesStr;
    }
    
    return self;
}

- (NSDictionary *)jsonDictionary
{
    // homeAccountId is needed to query Sso Cookies.
    if (self.accountIdentifier && [NSString msidIsStringNilOrBlank:self.accountIdentifier.homeAccountId]) return nil;
    
    NSMutableDictionary *json = [[super jsonDictionary] mutableCopy];
    if (!json) return nil;

    // Map to Sso Url
    if ([NSString msidIsStringNilOrBlank:self.ssoUrl]) return nil;
    json[MSID_BROKER_SSO_URL] = self.ssoUrl;
    
    // Map to types of header
    if ([NSString msidIsStringNilOrBlank:self.headerTypes]) return nil;
    json[MSID_BROKER_TYPES_OF_HEADER] = self.headerTypes;
    
    // Map to account identifier, it is nullable.
    NSDictionary *accountIdentifierJson = [self.accountIdentifier jsonDictionary];
    if (accountIdentifierJson)
    {
        [json addEntriesFromDictionary:accountIdentifierJson];
    }

    return json;
}

@end
