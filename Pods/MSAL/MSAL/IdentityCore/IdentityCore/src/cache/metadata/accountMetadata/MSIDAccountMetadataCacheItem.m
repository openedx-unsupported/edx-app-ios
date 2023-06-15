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

#import "MSIDAccountMetadataCacheItem.h"
#import "MSIDAccountMetadata.h"
#import "MSIDAccountMetadataCacheKey.h"
#import "MSIDAccountIdentifier.h"

@implementation MSIDAccountMetadataCacheItem
{
    NSMutableDictionary <NSString *, MSIDAccountMetadata *> *_accountMetadataMap;
}

- (instancetype)initWithClientId:(NSString *)clientId
{
    if ([NSString msidIsStringNilOrBlank:clientId])
    {
        MSID_LOG_WITH_CTX(MSIDLogLevelError,nil, @"Cannot initialize account metadata cache item with nil client id!");
        return nil;
    }
    
    self = [super init];
    
    if (self)
    {
        _clientId = clientId;
        _accountMetadataMap = [NSMutableDictionary new];
    }
    
    return self;
}

- (MSIDAccountMetadata *)accountMetadataForHomeAccountId:(NSString *)homeAccountId
{
    if (!homeAccountId)
    {
        MSID_LOG_WITH_CTX(MSIDLogLevelError,nil, @"Cannot lookup account metadata with nil homeAccountId!");
        return nil;
    }
    
    return _accountMetadataMap[homeAccountId];
}

- (BOOL)addAccountMetadata:(MSIDAccountMetadata *)accountMetadata forHomeAccountId:(NSString *)homeAccountId error:(NSError **)error
{
    if (!homeAccountId || !accountMetadata)
    {
        NSError *localError = MSIDCreateError(MSIDErrorDomain, MSIDErrorInvalidInternalParameter, @"Cannot add account metadata with nil accountMetadata or homeAccountId!", nil, nil, nil, nil, nil, YES);
        if (error) *error = localError;
        return NO;
    }
    
    _accountMetadataMap[homeAccountId] = accountMetadata;
    
    return YES;
}

- (BOOL)removeAccountMetadataForHomeAccountId:(NSString *)homeAccountId
                                        error:(NSError **)error
{
    if ([NSString msidIsStringNilOrBlank:homeAccountId])
    {
        NSError *localError = MSIDCreateError(MSIDErrorDomain, MSIDErrorInvalidInternalParameter, @"Cannot remove account metadata with empty homeAccountId!", nil, nil, nil, nil, nil, YES);
        if (error) *error = localError;
        return NO;
    }
    
    [_accountMetadataMap removeObjectForKey:homeAccountId];
    return YES;
}


#pragma mark - MSIDJsonSerializable

- (instancetype)initWithJSONDictionary:(NSDictionary *)json
                                 error:(NSError *__autoreleasing *)error
{
    if (!(self = [super init]))
    {
        return nil;
    }
    
    if (!json)
    {
        MSID_LOG_WITH_CTX(MSIDLogLevelWarning,nil, @"Tried to decode an account metadata item from nil json!");
        if (error) *error = MSIDCreateError(MSIDErrorDomain, MSIDErrorInvalidInternalParameter, @"Tried to decode an account metadata item from nil json!", nil, nil, nil, nil, nil, NO);
        
        return nil;
    }
    
    _accountMetadataMap = [NSMutableDictionary new];
    _clientId = [json msidStringObjectForKey:MSID_CLIENT_ID_CACHE_KEY];
    
    NSString *principalHomeAccountId = [json msidStringObjectForKey:MSID_PRINCIPAL_HOME_ACCOUNT_ID_CACHE_KEY];
    NSString *principalDisplayableId = [json msidStringObjectForKey:MSID_PRINCIPAL_DISPLAYABLE_ID_CACHE_KEY];
    
    if (principalHomeAccountId || principalDisplayableId)
    {
        _principalAccountId = [[MSIDAccountIdentifier alloc] initWithDisplayableId:principalDisplayableId homeAccountId:principalHomeAccountId];
    }
    
    _principalAccountEnvironment = [json msidStringObjectForKey:MSID_PRINCIPAL_ACCOUNT_ENVIRONMENT_CACHE_KEY];
    
    NSDictionary *accountMetaMapJson = [json msidObjectForKey:MSID_ACCOUNT_METADATA_MAP_CACHE_KEY ofClass:NSDictionary.class];
    for (NSString *key in accountMetaMapJson)
    {
        NSError *localError;
        MSIDAccountMetadata *accountMetadata = [[MSIDAccountMetadata alloc] initWithJSONDictionary:accountMetaMapJson[key] error:&localError];
        if (localError)
        {
            MSID_LOG_WITH_CTX(MSIDLogLevelWarning,nil, @"Failed to decode account metadata from json!");
        }
        
        if (accountMetadata)
        {
            _accountMetadataMap[key] = accountMetadata;
        }
    }
    
    return self;
}

- (NSDictionary *)jsonDictionary
{
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
    
    dictionary[MSID_CLIENT_ID_CACHE_KEY] = self.clientId;
    dictionary[MSID_PRINCIPAL_HOME_ACCOUNT_ID_CACHE_KEY] = self.principalAccountId.homeAccountId;
    dictionary[MSID_PRINCIPAL_DISPLAYABLE_ID_CACHE_KEY] = self.principalAccountId.displayableId;
    dictionary[MSID_PRINCIPAL_ACCOUNT_ENVIRONMENT_CACHE_KEY] = self.principalAccountEnvironment;
    
    NSMutableDictionary *accountMetadataMapJson = [NSMutableDictionary new];
    for (NSString *key in _accountMetadataMap)
    {
        accountMetadataMapJson[key] = _accountMetadataMap[key].jsonDictionary;
    }
    
    dictionary[MSID_ACCOUNT_METADATA_MAP_CACHE_KEY] = accountMetadataMapJson;
    
    return dictionary;
}

#pragma mark - NSCopying

- (nonnull id)copyWithZone:(nullable NSZone *)zone {
    MSIDAccountMetadataCacheItem *item = [[self class] allocWithZone:zone];
    item->_clientId = [self.clientId copyWithZone:zone];
    item->_accountMetadataMap = [self->_accountMetadataMap mutableDeepCopy];
    item->_principalAccountId = [self->_principalAccountId copyWithZone:zone];
    item->_principalAccountEnvironment = [self.principalAccountEnvironment copyWithZone:zone];
    
    return item;
}

- (NSUInteger)hash
{
    NSUInteger hash = [super hash];
    hash = hash * 31 + self.clientId.hash;
    hash = hash * 31 + _accountMetadataMap.hash;
    hash = hash * 31 + self.principalAccountId.hash;
    hash = hash * 31 + self.principalAccountEnvironment.hash;
    
    return hash;
}

#pragma mark - Equal

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
    
    return [self isEqualToItem:(MSIDAccountMetadataCacheItem *)object];
}

- (BOOL)isEqualToItem:(MSIDAccountMetadataCacheItem *)item
{
    BOOL result = YES;
    result &= (!self.clientId && !item.clientId) || [self.clientId isEqualToString:item.clientId];
    result &= ([_accountMetadataMap isEqualToDictionary:item->_accountMetadataMap]);
    result &= (!self.principalAccountId && !item.principalAccountId) || [self.principalAccountId isEqual:item.principalAccountId];
    result &= (!self.principalAccountEnvironment && !item.principalAccountEnvironment) || [self.principalAccountEnvironment isEqualToString:item.principalAccountEnvironment];
    
    return result;
}

#pragma mark - MSIDKeyGenerator

- (nullable MSIDCacheKey *)generateCacheKey
{
    MSIDAccountMetadataCacheKey *key = [[MSIDAccountMetadataCacheKey alloc] initWithClientId:self.clientId];
    return key;
}

@end
