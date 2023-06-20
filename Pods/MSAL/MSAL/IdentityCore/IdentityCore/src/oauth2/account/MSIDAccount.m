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

#import "MSIDAccount.h"
#import "MSIDClientInfo.h"
#import "MSIDAADTokenResponse.h"
#import "MSIDIdTokenClaims.h"
#import "MSIDAccountCacheItem.h"
#import "MSIDTokenResponse.h"
#import "MSIDAccountIdentifier.h"
#import "MSIDAuthority.h"

@implementation MSIDAccount

#pragma mark - NSCopying

- (id)copyWithZone:(NSZone *)zone
{
    MSIDAccount *item = [[self.class allocWithZone:zone] init];
    item->_accountIdentifier = [_accountIdentifier copyWithZone:zone];
    item->_localAccountId = [_localAccountId copyWithZone:zone];
    item->_accountType = _accountType;
    item->_environment = [_environment copyWithZone:zone];
    item->_storageEnvironment = [_storageEnvironment copyWithZone:zone];
    item->_realm = [_realm copyWithZone:zone];
    item->_username = [_username copyWithZone:zone];
    item->_givenName = [_givenName copyWithZone:zone];
    item->_middleName = [_middleName copyWithZone:zone];
    item->_familyName = [_familyName copyWithZone:zone];
    item->_name = [_name copyWithZone:zone];
    item->_clientInfo = [_clientInfo copyWithZone:zone];
    item->_alternativeAccountId = [_alternativeAccountId copyWithZone:zone];
    return item;
}

#pragma mark - NSObject

- (BOOL)isEqual:(id)object
{
    if (self == object)
    {
        return YES;
    }
    
    if (![object isKindOfClass:MSIDAccount.class])
    {
        return NO;
    }
    
    return [self isEqualToItem:(MSIDAccount *)object];
}

- (NSUInteger)hash
{
    NSUInteger hash = 0;
    hash = hash * 31 + self.accountIdentifier.displayableId.hash;
    hash = hash * 31 + self.accountType;
    hash = hash * 31 + self.environment.hash;
    hash = hash * 31 + self.realm.hash;
    hash = hash * 31 + self.alternativeAccountId.hash;
    hash = hash * 31 + self.username.hash;
    return hash;
}

- (BOOL)isEqualToItem:(MSIDAccount *)account
{
    if (!account)
    {
        return NO;
    }
    
    BOOL result = YES;

    if (self.accountIdentifier.homeAccountId && account.accountIdentifier.homeAccountId)
    {
        // In case we have 2 accounts in cache, but one of them doesn't have home account identifier,
        // we'll compare those accounts by legacy account ID instead to avoid duplicates being returned
        // due to presence of multiple caches
        result &= [self.accountIdentifier isEqual:account.accountIdentifier];
    }
    else
    {
        result &= [self.accountIdentifier.displayableId isEqual:account.accountIdentifier.displayableId];
    }

    result &= self.accountType == account.accountType;
    result &= (!self.alternativeAccountId && !account.alternativeAccountId) || [self.alternativeAccountId isEqualToString:account.alternativeAccountId];
    result &= (!self.environment && !account.environment) || [self.environment isEqualToString:account.environment];
    result &= (!self.realm && !account.realm) || [self.realm isEqualToString:account.realm];
    result &= (!self.username && !account.username) || [self.username isEqualToString:account.username];
    return result;
}

#pragma mark - Cache

- (instancetype)initWithAccountCacheItem:(MSIDAccountCacheItem *)cacheItem
{
    self = [super init];
    
    if (self)
    {
        if (!cacheItem)
        {
            return nil;
        }
        
        _accountType = cacheItem.accountType;
        _givenName = cacheItem.givenName;
        _familyName = cacheItem.familyName;
        _middleName = cacheItem.middleName;
        _name = cacheItem.name;
        _username = cacheItem.username;
        _accountIdentifier = [[MSIDAccountIdentifier alloc] initWithDisplayableId:cacheItem.username homeAccountId:cacheItem.homeAccountId];
        _clientInfo = cacheItem.clientInfo;
        _alternativeAccountId = cacheItem.alternativeAccountId;
        _localAccountId = cacheItem.localAccountId;
        _environment = cacheItem.environment;
        _realm = cacheItem.realm;
    }
    
    return self;
}

- (MSIDAccountCacheItem *)accountCacheItem
{
    MSIDAccountCacheItem *cacheItem = [[MSIDAccountCacheItem alloc] init];
    
    cacheItem.environment = self.storageEnvironment ? self.storageEnvironment : self.environment;
    cacheItem.realm = self.realm;
    cacheItem.username = self.username;
    cacheItem.homeAccountId = self.accountIdentifier.homeAccountId;
    cacheItem.localAccountId = self.localAccountId;
    cacheItem.accountType = self.accountType;
    cacheItem.givenName = self.givenName;
    cacheItem.middleName = self.middleName;
    cacheItem.name = self.name;
    cacheItem.familyName = self.familyName;
    cacheItem.clientInfo = self.clientInfo;
    return cacheItem;
}

- (BOOL)isHomeTenantAccount
{
    if (self.accountType == MSIDAccountTypeMSSTS)
    {
        return [self.realm isEqualToString:self.accountIdentifier.utid];
    }
    
    return YES;
}

#pragma mark - Description

- (NSString *)description
{
    return [NSString stringWithFormat:@"MSIDAccount environment: %@ storage environment %@ realm: %@ username: %@ homeAccountId: %@ accountType: %@ localAccountId: %@", self.environment, self.storageEnvironment,  self.realm, MSID_PII_LOG_EMAIL(self.username), MSID_PII_LOG_TRACKABLE(self.accountIdentifier.homeAccountId), [MSIDAccountTypeHelpers accountTypeAsString:self.accountType], MSID_PII_LOG_TRACKABLE(self.localAccountId)];
}

#pragma mark - MSIDJsonSerializable

- (instancetype)initWithJSONDictionary:(NSDictionary *)json error:(NSError **)error
{
    if (!(self = [super init]))
    {
        return nil;
    }
    
    self.accountIdentifier = [[MSIDAccountIdentifier alloc] initWithJSONDictionary:json error:error];
    if (!self.accountIdentifier)
    {
        MSID_LOG_WITH_CTX(MSIDLogLevelWarning,nil, @"No valid account identifier present in the JSON");
        return nil;
    }
    
    self.accountType = [MSIDAccountTypeHelpers accountTypeFromString:[json msidStringObjectForKey:@"account_type"]];
    self.localAccountId = [json msidStringObjectForKey:@"local_account_id"];
    self.environment = [json msidStringObjectForKey:@"environment"];
    self.storageEnvironment = [json msidStringObjectForKey:@"storage_environment"];
    self.realm = [json msidStringObjectForKey:@"realm"];
    self.username = [json msidStringObjectForKey:@"username"];
    self.givenName = [json msidStringObjectForKey:@"given_name"];
    self.middleName = [json msidStringObjectForKey:@"middle_name"];
    self.familyName = [json msidStringObjectForKey:@"family_name"];
    self.name = [json msidStringObjectForKey:@"name"];
    self.clientInfo = [[MSIDClientInfo alloc] initWithRawClientInfo:[json msidStringObjectForKey:@"client_info"] error:nil];
    self.alternativeAccountId = [json msidStringObjectForKey:@"alternative_account_id"];
    
    if (![json msidAssertType:NSDictionary.class ofKey:@"id_token_claims" required:NO error:error])
    {
        return nil;
    }
    self.idTokenClaims = [[MSIDIdTokenClaims alloc] initWithJSONDictionary:json[@"id_token_claims"] error:nil];
    self.isSSOAccount = [json msidBoolObjectForKey:@"is_sso_account"];
    
    return self;
}

- (NSDictionary *)jsonDictionary
{
    NSMutableDictionary *json = [NSMutableDictionary new];
    json[@"local_account_id"] = self.localAccountId;
    json[@"account_type"] = [MSIDAccountTypeHelpers accountTypeAsString:self.accountType];
    json[@"environment"] = self.environment;
    json[@"storage_environment"] = self.storageEnvironment;
    json[@"realm"] = self.realm;
    json[@"username"] = self.username;
    json[@"given_name"] = self.givenName;
    json[@"middle_name"] = self.middleName;
    json[@"family_name"] = self.familyName;
    json[@"name"] = self.name;
    json[@"client_info"] = self.clientInfo.rawClientInfo;
    json[@"alternative_account_id"] = self.alternativeAccountId;
    json[@"id_token_claims"] = self.idTokenClaims.jsonDictionary;
    json[@"is_sso_account"] = @(self.isSSOAccount);
    [json addEntriesFromDictionary:[self.accountIdentifier jsonDictionary]];
    
    return json;
}

@end
