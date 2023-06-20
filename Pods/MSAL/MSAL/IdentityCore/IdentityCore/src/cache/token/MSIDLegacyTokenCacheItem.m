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

#import "MSIDLegacyTokenCacheItem.h"
#import "MSIDUserInformation.h"
#import "MSIDLegacyAccessToken.h"
#import "MSIDLegacyRefreshToken.h"
#import "MSIDLegacySingleResourceToken.h"
#import "MSIDAADIdTokenClaimsFactory.h"
#import "MSIDIdTokenClaims.h"
#import "MSIDPrimaryRefreshToken.h"
#import "NSURL+MSIDAADUtils.h"

@interface MSIDLegacyTokenCacheItem()
{
    MSIDIdTokenClaims *_idTokenClaims;
}

@end

@implementation MSIDLegacyTokenCacheItem

#pragma mark - MSIDCacheItem

- (BOOL)isEqual:(id)object
{
    if (self == object)
    {
        return YES;
    }

    if (![object isKindOfClass:self.class])
    {
        return NO;
    }

    return [self isEqualToItem:(MSIDLegacyTokenCacheItem *)object];
}

- (BOOL)isEqualToItem:(MSIDLegacyTokenCacheItem *)item
{
    BOOL result = [super isEqualToItem:item];
    result &= (!self.accessToken && !item.accessToken) || [self.accessToken isEqualToString:item.accessToken];
    result &= (!self.refreshToken && !item.refreshToken) || [self.refreshToken isEqualToString:item.refreshToken];
    result &= (!self.idToken && !item.idToken) || [self.idToken isEqualToString:item.idToken];
    result &= (!self.oauthTokenType && !item.oauthTokenType) || [self.oauthTokenType isEqualToString:item.oauthTokenType];
    result &= (!self.additionalInfo && !item.additionalInfo) || [self.additionalInfo isEqual:item.additionalInfo];
    return result;
}

#pragma mark - NSObject

- (NSUInteger)hash
{
    NSUInteger hash = [super hash];
    hash = hash * 31 + self.accessToken.hash;
    hash = hash * 31 + self.refreshToken.hash;
    hash = hash * 31 + self.idToken.hash;
    hash = hash * 31 + self.oauthTokenType.hash;
    hash = hash * 31 + self.additionalInfo.hash;
    return hash;
}

#pragma mark - NSCopying

- (id)copyWithZone:(NSZone *)zone
{
    MSIDLegacyTokenCacheItem *item = [super copyWithZone:zone];
    item.accessToken = [self.accessToken copyWithZone:zone];
    item.refreshToken = [self.refreshToken copyWithZone:zone];
    item.idToken = [self.idToken copyWithZone:zone];
    item.oauthTokenType = [self.oauthTokenType copyWithZone:zone];
    item.additionalInfo = [self.additionalInfo copyWithZone:zone];
    return item;
}

#pragma mark - NSSecureCoding

+ (BOOL)supportsSecureCoding
{
    return YES;
}

- (instancetype)initWithCoder:(NSCoder *)coder
{
    if (!(self = [super init]))
    {
        return nil;
    }

    NSString *authorityString = [coder decodeObjectOfClass:[NSString class] forKey:@"authority"];

    if (authorityString)
    {
        NSURL *authorityURL = [NSURL URLWithString:authorityString];
        self.environment = authorityURL.msidHostWithPortIfNecessary;
        self.realm = authorityURL.msidAADTenant;
    }

    self.clientId = [coder decodeObjectOfClass:[NSString class] forKey:@"clientId"];
    self.target = [coder decodeObjectOfClass:[NSString class] forKey:@"resource"];
    self.expiresOn = [coder decodeObjectOfClass:[NSDate class] forKey:@"expiresOn"];
    self.cachedAt = [coder decodeObjectOfClass:[NSDate class] forKey:@"cachedAt"];
    self.familyId = [coder decodeObjectOfClass:[NSString class] forKey:@"familyId"];

    self.accessToken = [coder decodeObjectOfClass:[NSString class] forKey:@"accessToken"];
    self.refreshToken = [coder decodeObjectOfClass:[NSString class] forKey:@"refreshToken"];
    self.secret = self.accessToken ? self.accessToken : self.refreshToken;
    // Decode id_token from a backward compatible way
    MSIDUserInformation *userInfo = [coder decodeObjectOfClass:[MSIDUserInformation class] forKey:@"userInformation"];
    self.idToken = userInfo.rawIdToken;

    self.credentialType = [MSIDCredentialTypeHelpers credentialTypeWithRefreshToken:self.refreshToken accessToken:self.accessToken];
    self.oauthTokenType = [coder decodeObjectOfClass:[NSString class] forKey:@"accessTokenType"];

    NSString *homeAccountId = [coder decodeObjectOfClass:[NSString class] forKey:@"homeAccountId"];

    if (homeAccountId)
    {
        self.homeAccountId = homeAccountId;
    }
    
    self.enrollmentId = [coder decodeObjectOfClass:[NSString class] forKey:@"enrollmentId"];
    self.applicationIdentifier = [coder decodeObjectOfClass:[NSString class] forKey:@"applicationIdentifier"];
    
    NSSet *classes = [NSSet setWithObjects:[NSDictionary class], [NSDate class], [NSString class], [NSURL class], [NSNumber class], nil];
    NSMutableDictionary *additionalServer = [[coder decodeObjectOfClasses:classes forKey:@"additionalServer"] mutableCopy];
    self.extendedExpiresOn = additionalServer[MSID_EXTENDED_EXPIRES_ON_CACHE_KEY];
    [additionalServer removeObjectForKey:MSID_EXTENDED_EXPIRES_ON_CACHE_KEY];
    self.speInfo = additionalServer[MSID_SPE_INFO_CACHE_KEY];
    [additionalServer removeObjectForKey:MSID_SPE_INFO_CACHE_KEY];
    if (additionalServer.count)
    {
        self.additionalInfo = additionalServer;
    }
    
    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder
{
    NSURL *authorityURL = [NSURL msidAADURLWithEnvironment:self.environment tenant:self.realm];
    
    [coder encodeObject:authorityURL.absoluteString forKey:@"authority"];
    [coder encodeObject:self.accessToken forKey:@"accessToken"];
    [coder encodeObject:self.refreshToken forKey:@"refreshToken"];

    // Encode id_token in backward compatible way with ADAL
    MSIDUserInformation *userInformation = [[MSIDUserInformation alloc] initWithRawIdToken:self.idToken];
    [coder encodeObject:userInformation forKey:@"userInformation"];

    // Backward compatibility with ADAL.
    self.oauthTokenType = [NSString msidIsStringNilOrBlank:self.oauthTokenType] ? MSID_OAUTH2_BEARER : self.oauthTokenType;
    [coder encodeObject:self.oauthTokenType forKey:@"accessTokenType"];
    [coder encodeObject:self.clientId forKey:@"clientId"];
    [coder encodeObject:self.target forKey:@"resource"];
    [coder encodeObject:self.expiresOn forKey:@"expiresOn"];
    [coder encodeObject:self.cachedAt forKey:@"cachedAt"];
    [coder encodeObject:self.familyId forKey:@"familyId"];

    [coder encodeObject:[NSMutableDictionary dictionary] forKey:@"additionalClient"];

    NSMutableDictionary* additionalServer = [[NSMutableDictionary alloc] initWithDictionary:self.additionalInfo];
    if (self.extendedExpiresOn)
    {
        additionalServer[MSID_EXTENDED_EXPIRES_ON_CACHE_KEY] = self.extendedExpiresOn;
    }
    if (self.speInfo)
    {
        additionalServer[MSID_SPE_INFO_CACHE_KEY] = self.speInfo;
    }
    [coder encodeObject:additionalServer forKey:@"additionalServer"];

    [coder encodeObject:self.homeAccountId forKey:@"homeAccountId"];
    [coder encodeObject:self.enrollmentId forKey:@"enrollmentId"];
    [coder encodeObject:self.applicationIdentifier forKey:@"applicationIdentifier"];
}

- (MSIDBaseToken *)tokenWithType:(MSIDCredentialType)credentialType
{
    switch (credentialType)
    {
        case MSIDAccessTokenType:
            return [[MSIDLegacyAccessToken alloc] initWithLegacyTokenCacheItem:self];

        case MSIDRefreshTokenType:
            return [[MSIDLegacyRefreshToken alloc] initWithLegacyTokenCacheItem:self];

        case MSIDLegacySingleResourceTokenType:
            return [[MSIDLegacySingleResourceToken alloc] initWithLegacyTokenCacheItem:self];

        case MSIDPrimaryRefreshTokenType:
            return [[MSIDPrimaryRefreshToken alloc] initWithLegacyTokenCacheItem:self];

        default:
            return [super tokenWithType:credentialType];
    }
}

#pragma mark - Claims

- (MSIDIdTokenClaims *)idTokenClaims
{
    if (!self.idToken)
    {
        return nil;
    }

    if (_idTokenClaims)
    {
        return _idTokenClaims;
    }

    NSError *error = nil;
    _idTokenClaims = [MSIDAADIdTokenClaimsFactory claimsFromRawIdToken:self.idToken error:&error];

    if (error)
    {
        MSID_LOG_WITH_CTX_PII(MSIDLogLevelWarning, nil,  @"Invalid ID token, error %@", MSID_PII_LOG_MASKABLE(error));
    }

    return _idTokenClaims;
}

- (BOOL)isTombstone
{
    return self.refreshToken && [self.refreshToken isEqualToString:@"<tombstone>"];
}

@end
