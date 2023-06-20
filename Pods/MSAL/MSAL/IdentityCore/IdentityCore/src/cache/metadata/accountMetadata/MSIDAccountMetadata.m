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

#import "MSIDAccountMetadata.h"
#import "MSIDAccountIdentifier.h"
#import "MSIDAuthority.h"
#import "MSIDAuthorityFactory.h"
#import "NSDictionary+MSIDExtensions.h"
#import "MSIDAccountMetadataCacheKey.h"
#import "MSIDRequestParameters.h"

static const NSString *AccountMetadataURLMapKey = @"URLMap";

@interface MSIDAccountMetadata()

@property (nonatomic) NSMutableDictionary *auhtorityMap;

@end

@implementation MSIDAccountMetadata

- (instancetype)initWithHomeAccountId:(NSString *)homeAccountId
                             clientId:(NSString *)clientId

{
    if (!homeAccountId || !clientId) return nil;
    
    self = [super init];
    if (self)
    {
        _homeAccountId = homeAccountId;
        _clientId = clientId;
        _auhtorityMap = [NSMutableDictionary new];
        _signInState = MSIDAccountMetadataStateSignedIn;
    }
    return self;
}

#pragma mark - URL caching
- (BOOL)setCachedURL:(NSURL *)cachedURL
       forRequestURL:(NSURL *)requestURL
       instanceAware:(BOOL)instanceAware
               error:(NSError **)error
{
    _signInState = MSIDAccountMetadataStateSignedIn;
    
    if ([NSString msidIsStringNilOrBlank:cachedURL.absoluteString]
        || [NSString msidIsStringNilOrBlank:requestURL.absoluteString])
    {
        if (error) *error = MSIDCreateError(MSIDErrorDomain, MSIDErrorInvalidInternalParameter, @"Either a target or request URL produces a nil string", nil, nil, nil, nil, nil, YES);
        
        return NO;
    }
    
    NSString *urlMapKey = [self URLMapKey:instanceAware];
    NSMutableDictionary *urlMap = self.auhtorityMap[urlMapKey];
    if (!urlMap)
    {
        urlMap = [NSMutableDictionary new];
        _auhtorityMap[urlMapKey] = urlMap;
    }
    
    urlMap[requestURL.absoluteString] = cachedURL.absoluteString;
    return YES;
}

- (NSURL *)cachedURL:(NSURL *)requestURL instanceAware:(BOOL)instanceAware
{
    if (self.signInState != MSIDAccountMetadataStateSignedOut)
    {
        NSString *urlMapKey = [self URLMapKey:instanceAware];
        NSDictionary *urlMap = _auhtorityMap[urlMapKey];
        
        return [NSURL URLWithString:urlMap[requestURL.absoluteString]];
    }
    
    return nil;
}

#pragma mark - Signed out
- (void)updateSignInState:(MSIDAccountMetadataState)state
{
    _signInState = state;
    if (state == MSIDAccountMetadataStateSignedOut)
    {
        _auhtorityMap = [NSMutableDictionary new];
    }
    
}

- (instancetype)initWithJSONDictionary:(NSDictionary *)json
                                 error:(__unused NSError * __autoreleasing *)error
{
    if (!(self = [super init]))
    {
        return nil;
    }
    
    if (!json)
    {
        MSID_LOG_WITH_CTX(MSIDLogLevelWarning,nil, @"Tried to decode an authority map item from nil json");
        return nil;
    }
    
    _clientId = [json msidStringObjectForKey:MSID_CLIENT_ID_CACHE_KEY];
    _homeAccountId = [json msidStringObjectForKey:MSID_HOME_ACCOUNT_ID_CACHE_KEY];
    _auhtorityMap = [[json msidObjectForKey:MSID_AUTHORITY_MAP_CACHE_KEY ofClass:NSDictionary.class] mutableDeepCopy];
    _signInState = [self accountMetadataStateEnumFromString:[json msidStringObjectForKey:MSID_SIGN_IN_STATE_CACHE_KEY]];
    
    return self;
}

- (NSDictionary *)jsonDictionary
{
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
    
    dictionary[MSID_CLIENT_ID_CACHE_KEY] = self.clientId;
    dictionary[MSID_HOME_ACCOUNT_ID_CACHE_KEY] = self.homeAccountId;
    dictionary[MSID_AUTHORITY_MAP_CACHE_KEY] = self.auhtorityMap;
    dictionary[MSID_SIGN_IN_STATE_CACHE_KEY] = [self accountMetadataStateStringFromEnum:self.signInState];
    
    return dictionary;
}

- (NSString *)URLMapKey:(BOOL)instanceAware
{
    // The subkey is in the format of @"URLMap-key1=value1&key2=value2...",
    // where key1, key2... are the request parameters that may affect the url mapping.
    // Currently the only parameter that affects the mapping is instance aware flag.
    //
    // Example of subkeys:
    // "URLMap-" : with all possible keys being their default value repectively. Default
    //             value of instance_aware is NO, so "URLMap-" represents "URLMap-instance_aware=NO"
    // "URLMap-instance_aware=YES" : with instance_aware being YES.
    //
    // The benefit of such a design is, if we are introducing new parameters what will affect the
    // mapping, there will be no breaking change to existing clients who don't use the new parameters.
    
    return instanceAware ? @"URLMap-instance_aware=YES" : @"URLMap-";
}

- (NSString *)accountMetadataStateStringFromEnum:(MSIDAccountMetadataState)state
{
    switch (state) {
        case MSIDAccountMetadataStateUnknown:
            return @"unknown";
            break;
        case MSIDAccountMetadataStateSignedIn:
            return @"signed_in";
            break;
        case MSIDAccountMetadataStateSignedOut:
            return @"signed_out";
            break;
        default:
            return nil;
    }
}

- (MSIDAccountMetadataState)accountMetadataStateEnumFromString:(NSString *)stateString
{
    if ([stateString isEqualToString:@"unknown"])    return MSIDAccountMetadataStateUnknown;
    if ([stateString isEqualToString:@"signed_in"])  return MSIDAccountMetadataStateSignedIn;
    if ([stateString isEqualToString:@"signed_out"]) return MSIDAccountMetadataStateSignedOut;
        
    return MSIDAccountMetadataStateUnknown;
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
    
    return [self isEqualToItem:(MSIDAccountMetadata *)object];
}

- (BOOL)isEqualToItem:(MSIDAccountMetadata *)item
{
    BOOL result = YES;
    result &= (!self.clientId && !item.clientId) || [self.clientId isEqualToString:item.clientId];
    result &= (!self.homeAccountId && !item.homeAccountId) || [self.homeAccountId isEqualToString:item.homeAccountId];
    result &= ([self.auhtorityMap isEqualToDictionary:item->_auhtorityMap]);
    result &= (self.signInState == item.signInState);
    
    return result;
}

#pragma mark - NSObject

- (NSUInteger)hash
{
    NSUInteger hash = [super hash];
    hash = hash * 31 + self.clientId.hash;
    hash = hash * 31 + self.homeAccountId.hash;
    hash = hash * 31 + self.auhtorityMap.hash;
    hash = hash * 31 + @(self.signInState).hash;
    
    return hash;
}

#pragma mark - NSCopying

- (id)copyWithZone:(NSZone *)zone
{
    MSIDAccountMetadata *item = [[self class] allocWithZone:zone];
    item->_homeAccountId = [self.homeAccountId copyWithZone:zone];
    item->_clientId = [self.clientId copyWithZone:zone];
    item->_auhtorityMap = [self->_auhtorityMap mutableDeepCopy];
    item->_signInState = self.signInState;
    
    return item;
}


@end
