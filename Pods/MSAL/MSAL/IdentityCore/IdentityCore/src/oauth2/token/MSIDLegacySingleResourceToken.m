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

#import "MSIDLegacySingleResourceToken.h"
#import "MSIDTokenResponse.h"
#import "MSIDAADTokenResponse.h"
#import "MSIDAADIdTokenClaimsFactory.h"
#import "MSIDLegacyTokenCacheItem.h"

@implementation MSIDLegacySingleResourceToken

#pragma mark - NSCopying

- (id)copyWithZone:(NSZone *)zone
{
    MSIDLegacySingleResourceToken *item = [super copyWithZone:zone];
    item->_refreshToken = [_refreshToken copyWithZone:zone];
    item->_familyId = [_familyId copyWithZone:zone];
    return item;
}

#pragma mark - NSObject

- (BOOL)isEqual:(id)object
{
    if (self == object)
    {
        return YES;
    }
    
    if (![object isKindOfClass:MSIDLegacySingleResourceToken.class])
    {
        return NO;
    }
    
    return [self isEqualToItem:(MSIDLegacySingleResourceToken *)object];
}

- (NSUInteger)hash
{
    NSUInteger hash = [super hash];
    hash = hash * 31 + self.refreshToken.hash;
    hash = hash * 31 + self.familyId.hash;
    return hash;
}

- (BOOL)isEqualToItem:(MSIDLegacySingleResourceToken *)token
{
    if (!token)
    {
        return NO;
    }
    
    BOOL result = [super isEqualToItem:token];
    result &= (!self.refreshToken && !token.refreshToken) || [self.refreshToken isEqualToString:token.refreshToken];
    result &= (!self.familyId && !token.familyId) || [self.familyId isEqualToString:token.familyId];
    return result;
}

#pragma mark - Cache

- (instancetype)initWithTokenCacheItem:(MSIDCredentialCacheItem *)tokenCacheItem
{
    self = [super initWithTokenCacheItem:tokenCacheItem];
    
    if (self)
    {
        _familyId = tokenCacheItem.familyId;
    }
    
    return self;
}

- (MSIDCredentialCacheItem *)tokenCacheItem
{
    MSIDCredentialCacheItem *cacheItem = [super tokenCacheItem];
    cacheItem.familyId = self.familyId;
    cacheItem.credentialType = MSIDLegacySingleResourceTokenType;
    return cacheItem;
}

- (instancetype)initWithLegacyTokenCacheItem:(MSIDLegacyTokenCacheItem *)tokenCacheItem
{
    self = [super initWithLegacyTokenCacheItem:tokenCacheItem];

    if (self)
    {
        _refreshToken = tokenCacheItem.refreshToken;
        _familyId = tokenCacheItem.familyId;
    }

    return self;
}

- (MSIDLegacyTokenCacheItem *)legacyTokenCacheItem
{
    MSIDLegacyTokenCacheItem *cacheItem = [super legacyTokenCacheItem];
    cacheItem.refreshToken = self.refreshToken;
    cacheItem.familyId = self.familyId;
    cacheItem.credentialType = MSIDLegacySingleResourceTokenType;
    return cacheItem;
}

#pragma mark - Token type

- (MSIDCredentialType)credentialType
{
    return MSIDLegacySingleResourceTokenType;
}

- (BOOL)supportsCredentialType:(MSIDCredentialType)credentialType
{
    // Allow initializing single resource token with access token to support legacy ADAL scenarios
    return [super supportsCredentialType:credentialType] || credentialType == MSIDAccessTokenType;
}

#pragma mark - Description

- (NSString *)description
{
    NSString *baseDescription = [super description];
    return [baseDescription stringByAppendingFormat:@"(refresh token=%@, family id=%@)", [_refreshToken msidSecretLoggingHash], _familyId];
}

@end
