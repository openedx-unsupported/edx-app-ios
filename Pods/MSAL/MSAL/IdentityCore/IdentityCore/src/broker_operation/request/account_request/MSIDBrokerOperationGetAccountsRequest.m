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

#import "MSIDBrokerOperationGetAccountsRequest.h"
#import "MSIDJsonSerializableFactory.h"
#import "MSIDJsonSerializableTypes.h"
#import "MSIDConstants.h"

@implementation MSIDBrokerOperationGetAccountsRequest

+ (void)load
{
    [MSIDJsonSerializableFactory registerClass:self forClassType:self.operation];
}

#pragma mark - MSIDBrokerOperationRequest

+ (NSString *)operation
{
    return MSID_JSON_TYPE_OPERATION_REQUEST_GET_ACCOUNTS;
}

#pragma mark - MSIDJsonSerializable

- (instancetype)initWithJSONDictionary:(NSDictionary *)json error:(NSError **)error
{
    self = [super initWithJSONDictionary:json error:error];
    
    if (self)
    {
        _familyId = [json msidStringObjectForKey:MSID_BROKER_FAMILY_ID_KEY];
        
        _clientId = [json msidStringObjectForKey:MSID_BROKER_CLIENT_ID_KEY];
        if (!_clientId)
        {
            if (error)
            {
                *error = MSIDCreateError(MSIDErrorDomain, MSIDErrorInternal, @"client id is missing in get accounts operation call!", nil, nil, nil, nil, nil, YES);
            }
            return nil;
        }
        
        _returnOnlySignedInAccounts = YES;
        if ([json msidAssertTypeIsOneOf:@[NSString.class, NSNumber.class] ofKey:MSID_BROKER_SIGNED_IN_ACCOUNTS_ONLY_KEY required:YES error:nil])
        {
            _returnOnlySignedInAccounts = [json msidBoolObjectForKey:MSID_BROKER_SIGNED_IN_ACCOUNTS_ONLY_KEY];
        }
    }
    
    return self;
}

- (NSDictionary *)jsonDictionary
{
    NSMutableDictionary *json = [[super jsonDictionary] mutableCopy];
    if (!json) return nil;
    
    if (!self.clientId) return nil;
    json[MSID_BROKER_CLIENT_ID_KEY] = self.clientId;
    
    json[MSID_BROKER_FAMILY_ID_KEY] = self.familyId;
    json[MSID_BROKER_SIGNED_IN_ACCOUNTS_ONLY_KEY] = [@(self.returnOnlySignedInAccounts) stringValue];
    
    return json;
}

@end
