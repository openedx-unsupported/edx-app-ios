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

#import "MSIDAppMetadataCacheItem.h"
#import "NSDictionary+MSIDExtensions.h"
#import "MSIDAppMetadataCacheKey.h"

@interface MSIDAppMetadataCacheItem()

@property (atomic, readwrite) NSDictionary *json;

@end

@implementation MSIDAppMetadataCacheItem

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
    
    return [self isEqualToItem:(MSIDAppMetadataCacheItem *)object];
}

- (BOOL)isEqualToItem:(MSIDAppMetadataCacheItem *)item
{
    BOOL result = YES;
    result &= (!self.clientId && !item.clientId) || [self.clientId isEqualToString:item.clientId];
    result &= (!self.environment && !item.environment) || [self.environment isEqualToString:item.environment];
    result &= (!self.familyId && !item.familyId) || [self.familyId isEqualToString:item.familyId];
    return result;
}

#pragma mark - NSObject

- (NSUInteger)hash
{
    NSUInteger hash = [super hash];
    hash = hash * 31 + self.clientId.hash;
    hash = hash * 31 + self.environment.hash;
    hash = hash * 31 + self.familyId.hash;
    return hash;
}

#pragma mark - NSCopying

- (id)copyWithZone:(NSZone *)zone
{
    MSIDAppMetadataCacheItem *item = [[self class] allocWithZone:zone];
    item.clientId = [self.clientId copyWithZone:zone];
    item.environment = [self.environment copyWithZone:zone];
    item.familyId = [self.familyId copyWithZone:zone];
    return item;
}

#pragma mark - JSON

- (instancetype)initWithJSONDictionary:(NSDictionary *)json error:(__unused NSError **)error
{
    if (!(self = [super init]))
    {
        return nil;
    }
    
    if (!json)
    {
        MSID_LOG_WITH_CTX(MSIDLogLevelWarning,nil, @"Tried to decode an account cache item from nil json");
        return nil;
    }
    
    _json = json;
    
    _clientId = [json msidStringObjectForKey:MSID_CLIENT_ID_CACHE_KEY];
    _environment = [json msidStringObjectForKey:MSID_ENVIRONMENT_CACHE_KEY];
    _familyId = [json msidStringObjectForKey:MSID_FAMILY_ID_CACHE_KEY];
    return self;
}

- (NSDictionary *)jsonDictionary
{
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
    
    if (_json)
    {
        [dictionary addEntriesFromDictionary:_json];
    }
    
    dictionary[MSID_CLIENT_ID_CACHE_KEY] = _clientId;
    dictionary[MSID_ENVIRONMENT_CACHE_KEY] = _environment;
    dictionary[MSID_FAMILY_ID_CACHE_KEY] = _familyId;
    return dictionary;
}

- (BOOL)matchesWithClientId:(nullable NSString *)clientId
                environment:(nullable NSString *)environment
         environmentAliases:(nullable NSArray<NSString *> *)environmentAliases
{
    if (clientId && ![self.clientId isEqualToString:clientId])
    {
        return NO;
    }
    
    return [self matchByEnvironment:environment environmentAliases:environmentAliases];
}

- (BOOL)matchByEnvironment:(nullable NSString *)environment
        environmentAliases:(nullable NSArray<NSString *> *)environmentAliases
{
    if (environment && ![self.environment isEqualToString:environment])
    {
        return NO;
    }
    
    if ([environmentAliases count] && ![self.environment msidIsEquivalentWithAnyAlias:environmentAliases])
    {
        return NO;
    }
    
    return YES;
}

- (nullable MSIDCacheKey *)generateCacheKey
{
    MSIDAppMetadataCacheKey *key = [[MSIDAppMetadataCacheKey alloc] initWithClientId:self.clientId
                                                                         environment:self.environment
                                                                            familyId:self.familyId
                                                                         generalType:MSIDAppMetadataType];
    
    return key;
}

#pragma mark - Description

- (NSString *)description
{
    return [NSString stringWithFormat:@"(clientId=%@ environment=%@ familyId=%@)",
            _clientId, _environment, _familyId];
}

@end
