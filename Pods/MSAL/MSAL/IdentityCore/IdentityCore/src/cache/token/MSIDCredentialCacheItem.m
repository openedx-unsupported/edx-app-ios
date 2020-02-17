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

#import "MSIDCredentialCacheItem.h"
#import "MSIDCredentialCacheItem+MSIDBaseToken.h"
#import "MSIDUserInformation.h"
#import "MSIDCredentialType.h"
#import "NSDate+MSIDExtensions.h"
#import "NSURL+MSIDExtensions.h"
#import "MSIDIdTokenClaims.h"
#import "MSIDBaseToken.h"
#import "MSIDAccessToken.h"
#import "MSIDRefreshToken.h"
#import "MSIDLegacySingleResourceToken.h"
#import "MSIDIdToken.h"
#import "MSIDAADIdTokenClaimsFactory.h"
#import "MSIDClientInfo.h"
#import "MSIDLogger+Trace.h"
#import "NSData+MSIDExtensions.h"
#import "NSString+MSIDExtensions.h"
#import "NSOrderedSet+MSIDExtensions.h"
#import "NSDate+MSIDExtensions.h"
#import "NSDictionary+MSIDExtensions.h"

@interface MSIDCredentialCacheItem()

@property (readwrite) NSDictionary *json;

@end

@implementation MSIDCredentialCacheItem

- (NSString *)description
{
    return [NSString stringWithFormat:@"MSIDCredentialCacheItem: clientId: %@, credentialType: %@, target: %@, realm: %@, environment: %@, expiresOn: %@, extendedExpiresOn: %@, cachedAt: %@, familyId: %@, homeAccountId: %@, enrollmentId: %@, speInfo: %@, secret: %@",
            self.clientId, [MSIDCredentialTypeHelpers credentialTypeAsString:self.credentialType], self.target, self.realm, self.environment, self.expiresOn,
            self.extendedExpiresOn, self.cachedAt, self.familyId, self.homeAccountId, self.enrollmentId, self.speInfo, [self.secret msidSecretLoggingHash]];
}

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

    return [self isEqualToItem:(MSIDCredentialCacheItem *)object];
}

- (BOOL)isEqualToItem:(MSIDCredentialCacheItem *)item
{
    BOOL result = YES;
    result &= (!self.clientId && !item.clientId) || [self.clientId isEqualToString:item.clientId];
    result &= self.credentialType == item.credentialType;
    result &= (!self.secret && !item.secret) || [self.secret isEqualToString:item.secret];
    result &= (!self.target && !item.target) || [self.target isEqualToString:item.target];
    result &= (!self.realm && !item.realm) || [self.realm isEqualToString:item.realm];
    result &= (!self.environment && !item.environment) || [self.environment isEqualToString:item.environment];
    result &= (!self.expiresOn && !item.expiresOn) || [self.expiresOn isEqual:item.expiresOn];
    result &= (!self.extendedExpiresOn && !item.extendedExpiresOn) || [self.extendedExpiresOn isEqual:item.extendedExpiresOn];
    result &= (!self.cachedAt && !item.cachedAt) || [self.cachedAt isEqual:item.cachedAt];
    result &= (!self.familyId && !item.familyId) || [self.familyId isEqualToString:item.familyId];
    result &= (!self.homeAccountId && !item.homeAccountId) || [self.homeAccountId isEqualToString:item.homeAccountId];
    result &= (!self.applicationIdentifier || !item.applicationIdentifier) || [self.applicationIdentifier isEqualToString:item.applicationIdentifier];
    result &= (!self.speInfo && !item.speInfo) || [self.speInfo isEqual:item.speInfo];
    // Ignore the lastMod properties (two otherwise-identical items with different
    // last modification informational values should be considered equal)
    return result;
}

#pragma mark - NSObject

- (NSUInteger)hash
{
    NSUInteger hash = [super hash];
    hash = hash * 31 + self.clientId.hash;
    hash = hash * 31 + self.credentialType;
    hash = hash * 31 + self.secret.hash;
    hash = hash * 31 + self.target.hash;
    hash = hash * 31 + self.realm.hash;
    hash = hash * 31 + self.environment.hash;
    hash = hash * 31 + self.expiresOn.hash;
    hash = hash * 31 + self.extendedExpiresOn.hash;
    hash = hash * 31 + self.cachedAt.hash;
    hash = hash * 31 + self.familyId.hash;
    hash = hash * 31 + self.homeAccountId.hash;
    hash = hash * 31 + self.speInfo.hash;
    hash = hash * 31 + self.applicationIdentifier.hash;
    return hash;
}

#pragma mark - NSCopying

- (id)copyWithZone:(NSZone *)zone
{
    MSIDCredentialCacheItem *item = [[self class] allocWithZone:zone];
    item.clientId = [self.clientId copyWithZone:zone];
    item.credentialType = self.credentialType;
    item.secret = [self.secret copyWithZone:zone];
    item.target = [self.target copyWithZone:zone];
    item.realm = [self.realm copyWithZone:zone];
    item.environment = [self.environment copyWithZone:zone];
    item.expiresOn = [self.expiresOn copyWithZone:zone];
    item.extendedExpiresOn = [self.extendedExpiresOn copyWithZone:zone];
    item.cachedAt = [self.cachedAt copyWithZone:zone];
    item.familyId = [self.familyId copyWithZone:zone];
    item.homeAccountId = [self.homeAccountId copyWithZone:zone];
    item.speInfo = [self.speInfo copyWithZone:zone];
    item.lastModificationTime = [self.lastModificationTime copyWithZone:zone];
    item.lastModificationApp = [self.lastModificationApp copyWithZone:zone];
    item.enrollmentId = [self.enrollmentId copyWithZone:zone];
    item.applicationIdentifier = [self.applicationIdentifier copyWithZone:zone];
    return item;
}

#pragma mark - JSON

- (instancetype)initWithJSONDictionary:(NSDictionary *)json error:(__unused NSError **)error
{
    MSID_TRACE;
    if (!(self = [super init]))
    {
        return nil;
    }

    if (!json)
    {
        MSID_LOG_WITH_CTX(MSIDLogLevelWarning,nil, @"Tried to decode a credential cache item from nil json");
        return nil;
    }

    _json = json;

    _clientId = [json msidStringObjectForKey:MSID_CLIENT_ID_CACHE_KEY];
    _credentialType = [MSIDCredentialTypeHelpers credentialTypeFromString:[json msidStringObjectForKey:MSID_CREDENTIAL_TYPE_CACHE_KEY]];
    _secret = [json msidStringObjectForKey:MSID_TOKEN_CACHE_KEY];

    if (!_secret)
    {
        MSID_LOG_WITH_CTX(MSIDLogLevelWarning,nil, @"No secret present in the credential");
        return nil;
    }

    _target = [json msidStringObjectForKey:MSID_TARGET_CACHE_KEY];
    _realm = [json msidStringObjectForKey:MSID_REALM_CACHE_KEY];
    _environment = [json msidStringObjectForKey:MSID_ENVIRONMENT_CACHE_KEY];
    _expiresOn = [NSDate msidDateFromTimeStamp:[json msidStringObjectForKey:MSID_EXPIRES_ON_CACHE_KEY]];
    _extendedExpiresOn = [NSDate msidDateFromTimeStamp:[json msidStringObjectForKey:MSID_EXTENDED_EXPIRES_ON_CACHE_KEY]];
    _cachedAt = [NSDate msidDateFromTimeStamp:[json msidStringObjectForKey:MSID_CACHED_AT_CACHE_KEY]];
    _familyId = [json msidStringObjectForKey:MSID_FAMILY_ID_CACHE_KEY];
    _homeAccountId = [json msidStringObjectForKey:MSID_HOME_ACCOUNT_ID_CACHE_KEY];
    _enrollmentId = [json msidStringObjectForKey:MSID_ENROLLMENT_ID_CACHE_KEY];
    _speInfo = [json msidStringObjectForKey:MSID_SPE_INFO_CACHE_KEY];

    // Last Modification info (currently used on macOS only)
    _lastModificationTime = [NSDate msidDateFromTimeStamp:[json msidStringObjectForKey:MSID_LAST_MOD_TIME_CACHE_KEY]];
    _lastModificationApp = [json msidStringObjectForKey:MSID_LAST_MOD_APP_CACHE_KEY];

    _enrollmentId = [json msidStringObjectForKey:MSID_ENROLLMENT_ID_CACHE_KEY];
    _applicationIdentifier = [json msidStringObjectForKey:MSID_APPLICATION_IDENTIFIER_CACHE_KEY];
    return self;
}

- (NSDictionary *)jsonDictionary
{
    MSID_TRACE;
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];

    if (_json)
    {
        [dictionary addEntriesFromDictionary:_json];
    }

    dictionary[MSID_CLIENT_ID_CACHE_KEY] = _clientId;
    dictionary[MSID_CREDENTIAL_TYPE_CACHE_KEY] = [MSIDCredentialTypeHelpers credentialTypeAsString:self.credentialType];
    dictionary[MSID_TOKEN_CACHE_KEY] = _secret;
    dictionary[MSID_TARGET_CACHE_KEY] = _target;
    dictionary[MSID_REALM_CACHE_KEY] = _realm;
    dictionary[MSID_ENVIRONMENT_CACHE_KEY] = _environment;
    dictionary[MSID_EXPIRES_ON_CACHE_KEY] = _expiresOn.msidDateToTimestamp;
    dictionary[MSID_EXTENDED_EXPIRES_ON_CACHE_KEY] = _extendedExpiresOn.msidDateToTimestamp;
    dictionary[MSID_CACHED_AT_CACHE_KEY] = _cachedAt.msidDateToTimestamp;
    dictionary[MSID_FAMILY_ID_CACHE_KEY] = _familyId;
    dictionary[MSID_HOME_ACCOUNT_ID_CACHE_KEY] = _homeAccountId;
    dictionary[MSID_ENROLLMENT_ID_CACHE_KEY] = _enrollmentId;
    dictionary[MSID_SPE_INFO_CACHE_KEY] = _speInfo;

    // Last Modification info (currently used on macOS only)
    dictionary[MSID_LAST_MOD_TIME_CACHE_KEY] = [_lastModificationTime msidDateToFractionalTimestamp:3];
    dictionary[MSID_LAST_MOD_APP_CACHE_KEY] = _lastModificationApp;
    dictionary[MSID_APPLICATION_IDENTIFIER_CACHE_KEY] = _applicationIdentifier;
    return dictionary;
}

#pragma mark - Helpers

- (BOOL)matchesTarget:(NSString *)target comparisonOptions:(MSIDComparisonOptions)comparisonOptions
{
    if (!target)
    {
        return YES;
    }
    
    if(comparisonOptions == MSIDExactStringMatch)
    {
        return [self.target.msidNormalizedString isEqualToString:target.msidNormalizedString];
    }

    NSOrderedSet *inputSet = [NSOrderedSet msidOrderedSetFromString:target normalize:YES];
    NSOrderedSet *tokenSet = [NSOrderedSet msidOrderedSetFromString:self.target normalize:YES];

    switch (comparisonOptions) {
        case MSIDSubSet:
            return [inputSet isSubsetOfOrderedSet:tokenSet];
        case MSIDIntersect:
            return [inputSet intersectsOrderedSet:tokenSet];
        case MSIDExactStringMatch:
        default:
            return NO;
    }

    return NO;
}

- (BOOL)matchesWithHomeAccountId:(nullable NSString *)homeAccountId
                     environment:(nullable NSString *)environment
              environmentAliases:(nullable NSArray<NSString *> *)environmentAliases
{
    if (homeAccountId && 
        ![self.homeAccountId.msidNormalizedString isEqualToString:homeAccountId.msidNormalizedString])
    {
        return NO;
    }

    return [self matchByEnvironment:environment environmentAliases:environmentAliases];
}

- (BOOL)matchByEnvironment:(nullable NSString *)environment
        environmentAliases:(nullable NSArray<NSString *> *)environmentAliases
{
    if (environment && 
        ![self.environment.msidNormalizedString isEqualToString:environment.msidNormalizedString])
    {
        return NO;
    }

    if ([environmentAliases count] && 
        ![self.environment.msidNormalizedString msidIsEquivalentWithAnyAlias:environmentAliases])
    {
        return NO;
    }

    return YES;
}

- (BOOL)matchesWithRealm:(nullable NSString *)realm
                clientId:(nullable NSString *)clientId
                familyId:(nullable NSString *)familyId
                  target:(nullable NSString *)target
          targetMatching:(MSIDComparisonOptions)matchingOptions
        clientIdMatching:(MSIDComparisonOptions)clientIDMatchingOptions
{
    if (realm && ![self.realm.msidNormalizedString isEqualToString:realm.msidNormalizedString])
    {
        return NO;
    }

    if (![self matchesTarget:target comparisonOptions:matchingOptions])
    {
        return NO;
    }

    if (!clientId && !familyId)
    {
        return YES;
    }

    if (clientIDMatchingOptions == MSIDSuperSet)
    {
        if ((clientId && [self.clientId.msidNormalizedString isEqualToString:clientId.msidNormalizedString])
            || (familyId && [self.familyId.msidNormalizedString isEqualToString:familyId.msidNormalizedString]))
        {
            return YES;
        }

        return NO;
    }
    else
    {
        if (clientId && ![self.clientId.msidNormalizedString isEqualToString:clientId.msidNormalizedString])
        {
            return NO;
        }

        if (familyId && ![self.familyId.msidNormalizedString isEqualToString:familyId.msidNormalizedString])
        {
            return NO;
        }
    }

    return YES;
}

- (BOOL)isTombstone
{
    return [self.secret isEqualToString:@"<tombstone>"];
}

- (nullable MSIDCacheKey *)generateCacheKey
{
    MSIDDefaultCredentialCacheKey *key = [[MSIDDefaultCredentialCacheKey alloc] initWithHomeAccountId:self.homeAccountId
                                                                                          environment:self.environment
                                                                                             clientId:self.clientId
                                                                                       credentialType:self.credentialType];
    
    key.familyId = self.familyId;
    key.realm = self.realm;
    key.target = self.target;
    key.applicationIdentifier = self.applicationIdentifier;
    return key;
}

@end
