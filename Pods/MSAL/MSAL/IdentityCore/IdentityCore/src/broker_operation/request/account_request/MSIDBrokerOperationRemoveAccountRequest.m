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

#import "MSIDBrokerOperationRemoveAccountRequest.h"
#import "MSIDJsonSerializableFactory.h"
#import "NSDictionary+MSIDExtensions.h"
#import "MSIDAccountIdentifier.h"
#import "MSIDJsonSerializableTypes.h"
#import "MSIDConstants.h"

@implementation MSIDBrokerOperationRemoveAccountRequest

+ (void)load
{
    [MSIDJsonSerializableFactory registerClass:self forClassType:self.operation];
}

#pragma mark - MSIDBrokerOperationRequest

+ (NSString *)operation
{
    return MSID_JSON_TYPE_OPERATION_REQUEST_REMOVE_ACCOUNT;
}

#pragma mark - MSIDJsonSerializable

- (instancetype)initWithJSONDictionary:(NSDictionary *)json error:(NSError **)error
{
    self = [super initWithJSONDictionary:json error:error];
    
    if (self)
    {
        _accountIdentifier = [[MSIDAccountIdentifier alloc] initWithJSONDictionary:json error:error];
        if (!_accountIdentifier || (!_accountIdentifier.homeAccountId && !_accountIdentifier.displayableId))
        {
            if (error) *error = MSIDCreateError(MSIDErrorDomain, MSIDErrorInvalidInternalParameter, @"homeAccountId and displayableId could not both be nil for remove account operation!", nil, nil, nil, nil, nil, YES);
            return nil;
        }
        
        _clientId = [json msidStringObjectForKey:MSID_BROKER_CLIENT_ID_KEY];
        if (!_clientId)
        {
            if (error)
            {
                *error = MSIDCreateError(MSIDErrorDomain, MSIDErrorInvalidInternalParameter, @"client id is missing in remove account operation call!", nil, nil, nil, nil, nil, YES);
            }
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
    
    if (!self.clientId) return nil;
    [json setValue:self.clientId forKey:MSID_BROKER_CLIENT_ID_KEY];
    
    return json;
}

@end
