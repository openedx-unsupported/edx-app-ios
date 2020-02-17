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

#import "MSIDPrimaryRefreshToken.h"
#import "MSIDPRTCacheItem.h"
#import "NSData+MSIDExtensions.h"
#import "MSIDAccountIdentifier.h"
#import "MSIDIdTokenClaims.h"
#import "MSIDAuthority.h"

@implementation MSIDPrimaryRefreshToken

- (instancetype)initWithTokenCacheItem:(MSIDCredentialCacheItem *)tokenCacheItem
{
    self = [super initWithTokenCacheItem:tokenCacheItem];
    
    if (self)
    {
        _sessionKey = [NSData msidDataFromBase64UrlEncodedString:tokenCacheItem.jsonDictionary[MSID_SESSION_KEY_CACHE_KEY]];
        
        if (!_sessionKey)
        {
            MSID_LOG_WITH_CTX(MSIDLogLevelWarning,nil, @"Trying to initialize primary refresh token when missing session key field");
            return nil;
        }
    }
    
    return self;
}

- (MSIDCredentialCacheItem *)tokenCacheItem
{
    MSIDCredentialCacheItem *cacheItem = [super tokenCacheItem];
    
    NSError *error;
    MSIDPRTCacheItem *prtCacheItem = [[MSIDPRTCacheItem alloc] initWithJSONDictionary:cacheItem.jsonDictionary error:&error];
    if (!prtCacheItem) return nil;
    
    prtCacheItem.sessionKey = self.sessionKey;
    prtCacheItem.credentialType = MSIDPrimaryRefreshTokenType;
    
    return prtCacheItem;
}

// for legacy PRT reading from cache
- (instancetype)initWithLegacyTokenCacheItem:(MSIDLegacyTokenCacheItem *)tokenCacheItem
{
    self = [super initWithLegacyTokenCacheItem:tokenCacheItem];
    
    if (self)
    {
        _sessionKey = [NSData msidDataFromBase64UrlEncodedString:tokenCacheItem.jsonDictionary[MSID_SESSION_KEY_CACHE_KEY]];
        
        if (!_sessionKey)
        {
            MSID_LOG_WITH_CTX(MSIDLogLevelWarning,nil, @"Trying to initialize primary refresh token when missing session key field");
            return nil;
        }
    }
    
    return self;
}

// for legacy PRT deletion from cache
- (MSIDLegacyTokenCacheItem *)legacyTokenCacheItem
{
    MSIDLegacyTokenCacheItem *legacyPrtCacheItem = [MSIDLegacyTokenCacheItem new];
    
    legacyPrtCacheItem.credentialType = MSIDPrimaryRefreshTokenType;
    legacyPrtCacheItem.environment = self.storageEnvironment ? self.storageEnvironment : self.environment;
    legacyPrtCacheItem.clientId = self.clientId;
    
    return legacyPrtCacheItem;
}

#pragma mark - NSObject

- (BOOL)isEqual:(id)object
{
    if (self == object)
    {
        return YES;
    }
    
    if (![object isKindOfClass:MSIDPrimaryRefreshToken.class])
    {
        return NO;
    }
    
    return [self isEqualToItem:(MSIDPrimaryRefreshToken *)object];
}

- (NSUInteger)hash
{
    NSUInteger hash = [super hash];
    hash = hash * 31 + self.sessionKey.hash;
    return hash;
}

- (BOOL)isEqualToItem:(MSIDPrimaryRefreshToken *)token
{
    if (!token)
    {
        return NO;
    }
    
    BOOL result = [super isEqualToItem:token];
    result &= (!self.sessionKey && !token.sessionKey) || [self.sessionKey isEqualToData:token.sessionKey];
    return result;
}

#pragma mark - NSCopying

- (id)copyWithZone:(NSZone *)zone
{
    MSIDPrimaryRefreshToken *item = [super copyWithZone:zone];
    item->_sessionKey = [_sessionKey copyWithZone:zone];
    return item;
}

#pragma mark - Token type

- (MSIDCredentialType)credentialType
{
    return MSIDPrimaryRefreshTokenType;
}

#pragma mark - Description

- (NSString *)description
{
    NSString *baseDescription = [super description];
    return [baseDescription stringByAppendingFormat:@"(primary refresh token=%@)", [_refreshToken msidSecretLoggingHash]];
}

@end
