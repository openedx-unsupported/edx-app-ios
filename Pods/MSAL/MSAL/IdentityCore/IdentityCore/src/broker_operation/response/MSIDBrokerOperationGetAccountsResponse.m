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

#import "MSIDBrokerOperationGetAccountsResponse.h"
#import "MSIDAccount.h"
#import "MSIDJsonSerializableFactory.h"
#import "MSIDJsonSerializableTypes.h"
#import "MSIDAccountIdentifier.h"
#import "MSIDJsonSerializer.h"

@implementation MSIDBrokerOperationGetAccountsResponse

+ (void)load
{
    [MSIDJsonSerializableFactory registerClass:self forClassType:self.responseType];
}

+ (NSString *)responseType
{
    return MSID_JSON_TYPE_BROKER_OPERATION_GET_ACCOUNTS_RESPONSE;
}

#pragma mark - MSIDJsonSerializable

- (instancetype)initWithJSONDictionary:(NSDictionary *)json error:(NSError **)error
{
    self = [super initWithJSONDictionary:json error:error];
    
    if (self)
    {
        if (![json msidAssertType:NSString.class ofKey:@"accounts" required:NO error:error])
        {
            return nil;
        }
        
        NSString *accountsString = json[@"accounts"];
        
        if ([NSString msidIsStringNilOrBlank:accountsString])
        {
            self.accounts = @[];
            self.success = YES;
            return self;
        }
        
        NSData *jsonData = [accountsString dataUsingEncoding:NSUTF8StringEncoding];
        NSArray *accountsJson = [NSJSONSerialization JSONObjectWithData:jsonData options:0 error:error];
                  
        if (!accountsJson || ![accountsJson isKindOfClass:[NSArray class]])
        {
            MSID_LOG_WITH_CTX_PII(MSIDLogLevelError, nil, @"Failed to deserialize accounts data");
            return nil;
        }
                
        NSMutableArray *accounts = [NSMutableArray new];
        for (NSDictionary *accountJson in accountsJson)
        {
            if (![accountJson isKindOfClass:NSDictionary.class])
            {
                continue;
            }
            
            NSError *localError;
            MSIDAccount *account = [[MSIDAccount alloc] initWithJSONDictionary:accountJson error:&localError];
            if (!account)
            {
                // We log the error and continue to parse other accounts data
                MSID_LOG_WITH_CTX(MSIDLogLevelError, nil, @"MSIDBrokerOperationGetAccountsResponse - could not parse accounts with error domain (%@) + error code (%ld).", localError.domain, (long)localError.code);
                continue;
            }
            
            [accounts addObject:account];
        }
        
        self.success = YES;
        self.accounts = accounts;
    }
    
    return self;
}

- (NSDictionary *)jsonDictionary
{
    NSMutableDictionary *json = [[super jsonDictionary] mutableCopy];
    if (!json) return nil;
    
    NSMutableArray *accountsJson = [NSMutableArray new];
    
    for (MSIDAccount *account in self.accounts)
    {
        NSDictionary *accountJson = [account jsonDictionary];
        if (accountJson) [accountsJson addObject:accountJson];
    }
    
    NSError *jsonError;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:accountsJson options:0 error:&jsonError];
    
    if (jsonError)
    {
        MSID_LOG_WITH_CTX_PII(MSIDLogLevelWarning, nil, @"Failed to serialize accounts with error %@", MSID_PII_LOG_MASKABLE(jsonError));
    }
    else if (jsonData)
    {
        json[@"accounts"] = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    }

    return json;
}

@end
