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

#import "MSIDLegacyAccessToken.h"
#import "MSIDLegacyTokenCacheItem.h"
#import "MSIDAADIdTokenClaimsFactory.h"
#import "MSIDAuthority.h"
#import "MSIDIdTokenClaims.h"
#import "MSIDAccountIdentifier.h"

@implementation MSIDLegacyAccessToken

#pragma mark - NSCopying

- (id)copyWithZone:(NSZone *)zone
{
    MSIDLegacyAccessToken *item = [super copyWithZone:zone];
    item->_idToken = [_idToken copyWithZone:zone];
    item->_accessTokenType = [_accessTokenType copyWithZone:zone];
    return item;
}

#pragma mark - NSObject

- (BOOL)isEqual:(id)object
{
    if (self == object)
    {
        return YES;
    }

    if (![object isKindOfClass:MSIDLegacyAccessToken.class])
    {
        return NO;
    }

    return [self isEqualToItem:(MSIDLegacyAccessToken *)object];
}

- (NSUInteger)hash
{
    NSUInteger hash = [super hash];
    hash = hash * 31 + self.idToken.hash;
    hash = hash * 31 + self.accessTokenType.hash;
    return hash;
}

- (BOOL)isEqualToItem:(MSIDLegacyAccessToken *)token
{
    if (!token)
    {
        return NO;
    }

    BOOL result = [super isEqualToItem:token];
    result &= (!self.accessTokenType && !token.accessTokenType) || [self.accessTokenType isEqualToString:token.accessTokenType];
    result &= (!self.idToken && !token.idToken) || [self.idToken isEqualToString:token.idToken];

    return result;
}

#pragma mark - Cache

- (MSIDCredentialCacheItem *)tokenCacheItem
{
    MSIDCredentialCacheItem *cacheItem = [super tokenCacheItem];
    cacheItem.credentialType = MSIDAccessTokenType;
    return cacheItem;
}

- (instancetype)initWithLegacyTokenCacheItem:(MSIDLegacyTokenCacheItem *)tokenCacheItem
{
    self = [self initWithTokenCacheItem:tokenCacheItem];

    if (self)
    {
        _accessToken = tokenCacheItem.accessToken;
        _idToken = tokenCacheItem.idToken;
        _accessTokenType = tokenCacheItem.oauthTokenType;
        _additionalServerInfo = tokenCacheItem.additionalInfo;
        MSIDIdTokenClaims *claims = tokenCacheItem.idTokenClaims;
        _accountIdentifier = [[MSIDAccountIdentifier alloc] initWithDisplayableId:claims.userId homeAccountId:tokenCacheItem.homeAccountId];
    }

    return self;
}

- (MSIDLegacyTokenCacheItem *)legacyTokenCacheItem
{
    MSIDLegacyTokenCacheItem *cacheItem = [MSIDLegacyTokenCacheItem new];
    cacheItem.expiresOn = self.expiresOn;
    cacheItem.extendedExpiresOn = self.extendedExpiresOn;
    cacheItem.cachedAt = self.cachedAt;
    cacheItem.secret = self.accessToken;
    cacheItem.target = self.resource;
    cacheItem.credentialType = MSIDAccessTokenType;
    cacheItem.accessToken = self.accessToken;
    cacheItem.idToken = self.idToken;
    cacheItem.oauthTokenType = self.accessTokenType;
    cacheItem.environment = self.storageEnvironment ? self.storageEnvironment : self.environment;
    cacheItem.realm = self.realm;
    cacheItem.clientId = self.clientId;
    cacheItem.additionalInfo = self.additionalServerInfo;
    cacheItem.homeAccountId = self.accountIdentifier.homeAccountId;
    cacheItem.applicationIdentifier = self.applicationIdentifier;
    cacheItem.enrollmentId = self.enrollmentId;
    return cacheItem;
}

#pragma mark - Token type

- (MSIDCredentialType)credentialType
{
    return MSIDAccessTokenType;
}

#pragma mark - Description

- (NSString *)description
{
    NSString *baseDescription = [super description];
    return [baseDescription stringByAppendingFormat:@"(id token=%@, access token=%@)", [_idToken msidSecretLoggingHash], [_accessToken msidSecretLoggingHash]];
}

@end
