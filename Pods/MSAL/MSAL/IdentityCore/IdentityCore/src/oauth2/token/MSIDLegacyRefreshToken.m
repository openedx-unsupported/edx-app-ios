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

#import "MSIDLegacyRefreshToken.h"
#import "MSIDLegacyTokenCacheItem.h"
#import "MSIDAADIdTokenClaimsFactory.h"
#import "MSIDAuthority.h"
#import "MSIDAccountIdentifier.h"

@implementation MSIDLegacyRefreshToken

#pragma mark - NSCopying

- (id)copyWithZone:(NSZone *)zone
{
    MSIDLegacyRefreshToken *item = [super copyWithZone:zone];
    item->_idToken = [_idToken copyWithZone:zone];
    item->_accountIdentifier = [_accountIdentifier copyWithZone:zone];
    return item;
}

#pragma mark - NSObject

- (BOOL)isEqual:(id)object
{
    if (self == object)
    {
        return YES;
    }

    if (![object isKindOfClass:MSIDLegacyRefreshToken.class])
    {
        return NO;
    }

    return [self isEqualToItem:(MSIDLegacyRefreshToken *)object];
}

- (NSUInteger)hash
{
    NSUInteger hash = [super hash];
    hash = hash * 31 + self.idToken.hash;
    hash = hash * 31 + self.accountIdentifier.hash;
    return hash;
}

- (BOOL)isEqualToItem:(MSIDLegacyRefreshToken *)token
{
    if (!token)
    {
        return NO;
    }

    BOOL result = [super isEqualToItem:token];
    result &= (!self.accountIdentifier && !token.accountIdentifier) || [self.accountIdentifier isEqual:token.accountIdentifier];
    result &= (!self.idToken && !token.idToken) || [self.idToken isEqualToString:token.idToken];

    return result;
}

#pragma mark - Cache

- (MSIDCredentialCacheItem *)tokenCacheItem
{
    MSIDCredentialCacheItem *cacheItem = [super tokenCacheItem];
    cacheItem.credentialType = MSIDRefreshTokenType;
    return cacheItem;
}

- (instancetype)initWithLegacyTokenCacheItem:(MSIDLegacyTokenCacheItem *)tokenCacheItem
{
    self = [self initWithTokenCacheItem:tokenCacheItem];

    if (self)
    {
        _idToken = tokenCacheItem.idToken;
        _refreshToken = tokenCacheItem.refreshToken;
        
        if (!_refreshToken)
        {
            MSID_LOG_WITH_CTX(MSIDLogLevelError, nil, @"Trying to initialize refresh token when missing refresh token field in cache");
            return nil;
        }

        MSIDIdTokenClaims *claims = tokenCacheItem.idTokenClaims;
        _accountIdentifier = [[MSIDAccountIdentifier alloc] initWithDisplayableId:claims.userId homeAccountId:tokenCacheItem.homeAccountId];
        _idTokenClaims = tokenCacheItem.idTokenClaims;
        _additionalServerInfo = tokenCacheItem.additionalInfo;
    }

    return self;
}

- (MSIDLegacyTokenCacheItem *)legacyTokenCacheItem
{
    MSIDLegacyTokenCacheItem *cacheItem = [MSIDLegacyTokenCacheItem new];
    cacheItem.credentialType = MSIDRefreshTokenType;
    cacheItem.idToken = self.idToken;
    cacheItem.environment = self.storageEnvironment ? self.storageEnvironment : self.environment;
    cacheItem.realm = self.realm;
    cacheItem.clientId = self.clientId;
    cacheItem.additionalInfo = self.additionalServerInfo;
    cacheItem.homeAccountId = self.accountIdentifier.homeAccountId;
    cacheItem.refreshToken = self.refreshToken;
    cacheItem.familyId = self.familyId;
    cacheItem.secret = self.refreshToken;
    return cacheItem;
}

#pragma mark - Token type

- (MSIDCredentialType)credentialType
{
    return MSIDRefreshTokenType;
}

#pragma mark - Description

- (NSString *)description
{
    NSString *baseDescription = [super description];
    return [baseDescription stringByAppendingFormat:@"(id token=%@, legacy user ID=%@)", [_idToken msidSecretLoggingHash], _accountIdentifier.displayableId];
}

@end
