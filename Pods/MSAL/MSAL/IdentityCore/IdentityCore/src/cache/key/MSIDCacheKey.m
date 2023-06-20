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

#import "MSIDCacheKey.h"
#import "MSIDCredentialType.h"

@implementation MSIDCacheKey

- (id)initWithAccount:(NSString *)account
              service:(NSString *)service
              generic:(NSData *)generic
                 type:(NSNumber *)type
{
    if (!(self = [super init]))
    {
        return nil;
    }
    
    _account = account;
    _service = service;
    _type = type;
    _generic = generic;
    
    return self;
}

+ (NSString *)familyClientId:(NSString *)familyId
{
    if (!familyId)
    {
        familyId = @"1";
    }
    
    return [NSString stringWithFormat:@"foci-%@", familyId];
}

- (NSString *)logDescription
{
    return [NSString stringWithFormat:@"service=%@, type=%@, account=%@", _service, _type, _PII_NULLIFY(_account)];
}

- (NSString *)piiLogDescription
{
    return [NSString stringWithFormat:@"service=%@, type=%@, account=%@", _service, _type, _account];
}

#pragma mark - NSObject

- (id)copyWithZone:(NSZone *)zone
{
    MSIDCacheKey *key = [[self.class allocWithZone:zone] init];
    key->_account = [_account copyWithZone:zone];
    key->_service = [_service copyWithZone:zone];
    key->_type = [_type copyWithZone:zone];
    key->_generic = [_generic copyWithZone:zone];
    key->_appKey = [_appKey copyWithZone:zone];
    return key;
}

- (BOOL)isEqual:(id)object
{
    if (self == object)
    {
        return YES;
    }
    
    if (![object isKindOfClass:MSIDCacheKey.class])
    {
        return NO;
    }
    
    return [self isEqualToItem:(MSIDCacheKey *)object];
}

- (NSUInteger)hash
{
    NSUInteger hash = 0;
    hash = hash * 31 + self.account.hash;
    hash = hash * 31 + self.service.hash;
    return hash;
}

- (BOOL)isEqualToItem:(MSIDCacheKey *)cacheKey
{
    if (!cacheKey)
    {
        return NO;
    }
    
    BOOL result = YES;
    
    result &= (!self.account && !cacheKey.account) || [self.account isEqualToString:cacheKey.account];
    result &= (!self.service && !cacheKey.service) || [self.service isEqualToString:cacheKey.service];
    return result;
}

#pragma mark - Broker

- (NSNumber *)appKeyHash
{
    return nil;
}

@end
