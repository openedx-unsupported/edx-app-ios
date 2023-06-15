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

static NSUInteger kDefaultPRTRefreshInterval = 10800;
static NSString *kMinSupportedPRTVersion = @"3.0";

@implementation MSIDPrimaryRefreshToken

- (instancetype)initWithTokenCacheItem:(MSIDCredentialCacheItem *)tokenCacheItem
{
    self = [super initWithTokenCacheItem:tokenCacheItem];
    
    if (self)
    {
        NSDictionary *jsonDictionary = tokenCacheItem.jsonDictionary;
        
        _sessionKey = [NSData msidDataFromBase64UrlEncodedString:jsonDictionary[MSID_SESSION_KEY_CACHE_KEY]];
        
        _deviceID = [jsonDictionary msidObjectForKey:MSID_DEVICE_ID_CACHE_KEY ofClass:[NSString class]];
        
        if (!_sessionKey)
        {
            MSID_LOG_WITH_CTX(MSIDLogLevelWarning,nil, @"Trying to initialize primary refresh token when missing session key field");
            return nil;
        }
        
        _prtProtocolVersion = [jsonDictionary msidObjectForKey:MSID_PRT_PROTOCOL_VERSION_CACHE_KEY ofClass:[NSString class]];
        
        if ([_prtProtocolVersion floatValue] < [kMinSupportedPRTVersion floatValue])
        {
            MSID_LOG_WITH_CTX(MSIDLogLevelWarning, nil, @"Upgrading PRT from version %@ to min required version %@", _prtProtocolVersion, kMinSupportedPRTVersion);
            _prtProtocolVersion = kMinSupportedPRTVersion;
        }
        
        _expiresOn = tokenCacheItem.expiresOn;
        _cachedAt = tokenCacheItem.cachedAt;
        _lastRecoveryAttempt = tokenCacheItem.lastRecoveryAttempt;
        _expiryInterval = [tokenCacheItem.expiryInterval integerValue];
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
    prtCacheItem.deviceID = self.deviceID;
    prtCacheItem.prtProtocolVersion = self.prtProtocolVersion;
    prtCacheItem.expiresOn = self.expiresOn;
    prtCacheItem.cachedAt = self.cachedAt;
    prtCacheItem.lastRecoveryAttempt = self.lastRecoveryAttempt;
    prtCacheItem.expiryInterval = [NSString stringWithFormat:@"%lu", (long)self.expiryInterval];
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
    hash = hash * 31 + self.deviceID.hash;
    hash = hash * 31 + self.prtProtocolVersion.hash;
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
    result &= (!self.deviceID && !token.deviceID) || [self.deviceID isEqualToString:token.deviceID];
    result &= (!self.prtProtocolVersion && !token.prtProtocolVersion) || [self.prtProtocolVersion isEqualToString:token.prtProtocolVersion];
    return result;
}

#pragma mark - NSCopying

- (id)copyWithZone:(NSZone *)zone
{
    MSIDPrimaryRefreshToken *item = [super copyWithZone:zone];
    item->_sessionKey = [_sessionKey copyWithZone:zone];
    item->_deviceID = [_deviceID copyWithZone:zone];
    item->_prtProtocolVersion = [_prtProtocolVersion copyWithZone:zone];
    item->_expiresOn = [_expiresOn copyWithZone:zone];
    item->_cachedAt = [_cachedAt copyWithZone:zone];
    item->_lastRecoveryAttempt = [_lastRecoveryAttempt copyWithZone:zone];
    item->_expiryInterval = _expiryInterval;
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

#pragma mark - Utils

 - (BOOL)isDevicelessPRT
{
    CGFloat prtVersion = [self.prtProtocolVersion floatValue];
    return prtVersion >= 3.0 && [NSString msidIsStringNilOrBlank:self.deviceID];
}

- (BOOL)shouldRefreshWithInterval:(NSUInteger)refreshInterval
{
    if (!self.expiresOn)
    {
        return YES;
    }
    
    NSDate *nowPlusBuffer = [NSDate dateWithTimeIntervalSinceNow:refreshInterval];
    BOOL isCloseToExpiry = [self.expiresOn compare:nowPlusBuffer] == NSOrderedAscending;
    
    if (isCloseToExpiry)
    {
        return YES;
    }
    
    BOOL shouldRefresh = [[NSDate date] timeIntervalSinceDate:self.cachedAt] >= refreshInterval;
    return shouldRefresh;
}

- (NSUInteger)refreshInterval
{
    if (self.expiryInterval > 0)
    {
        return self.expiryInterval / 30;
    }
    
    return kDefaultPRTRefreshInterval;
}

@end
