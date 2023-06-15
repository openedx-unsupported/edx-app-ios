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

#import "MSIDDefaultAccountCacheKey.h"

static NSString *keyDelimiter = @"-";
static NSInteger kAccountTypePrefix = 1000;

@implementation MSIDDefaultAccountCacheKey

- (NSNumber *)accountTypeNumber:(MSIDAccountType)accountType
{
    return @(kAccountTypePrefix + accountType);
}

- (instancetype)initWithHomeAccountId:(NSString *)homeAccountId
                          environment:(NSString *)environment
                                realm:(NSString *)realm
                                 type:(MSIDAccountType)type
{
    self = [super init];

    if (self)
    {
        _homeAccountId = homeAccountId;
        _environment = environment;
        _realm = realm ? realm : @"";
        _accountType = type;
    }

    return self;
}

- (NSData *)generic
{
    return [self.username.msidTrimmedString.lowercaseString dataUsingEncoding:NSUTF8StringEncoding];
}

- (NSNumber *)type
{
    return [self accountTypeNumber:self.accountType];
}

- (NSString *)account
{
    NSString *uniqueId = self.homeAccountId.msidTrimmedString.lowercaseString;

    return [NSString stringWithFormat:@"%@%@%@",
            uniqueId, keyDelimiter, self.environment.msidTrimmedString.lowercaseString];
}

- (NSString *)service
{
    return self.realm.msidTrimmedString.lowercaseString;
}

- (BOOL)isShared
{
    return YES;
}

#pragma mark - NSObject

- (id)copyWithZone:(NSZone *)zone
{
    MSIDDefaultAccountCacheKey *item = [[self.class allocWithZone:zone] init];
    item->_homeAccountId = [_homeAccountId copyWithZone:zone];
    item->_environment = [_environment copyWithZone:zone];
    item->_realm = [_realm copyWithZone:zone];
    item->_username = [_username copyWithZone:zone];
    item->_accountType = _accountType;
    return item;
}

@end
