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

#import "MSIDLegacyTokenCacheKey.h"
#import "MSIDHelpers.h"
#import "NSURL+MSIDAADUtils.h"

//A special attribute to write, instead of nil/empty one.
NSString *const MSID_LEGACY_CACHE_NIL_KEY = @"CC3513A0-0E69-4B4D-97FC-DFB6C91EE132";
static NSString *const s_adalLibraryString = @"MSOpenTech.ADAL.1";
static NSString *const s_adalServiceFormat = @"%@|%@|%@|%@";

@interface MSIDLegacyTokenCacheKey()

@end

@implementation MSIDLegacyTokenCacheKey

#pragma mark - Helpers

//We should not put nil keys in the keychain. The method substitutes nil with a special GUID:
- (NSString *)getAttributeName:(NSString *)attribute
{
    return ([NSString msidIsStringNilOrBlank:attribute]) ? MSID_LEGACY_CACHE_NIL_KEY : [attribute msidBase64UrlEncode];
}

- (NSString *)serviceWithAuthority:(NSURL *)authority
                          resource:(NSString *)resource
                          clientId:(NSString *)clientId
                            appKey:(NSString *)appKey
{
    // Trim first for faster nil or empty checks. Also lowercase and trimming is
    // needed to ensure that the cache handles correctly same items with different
    // character case:
    NSString *authorityString = authority.absoluteString.msidTrimmedString.lowercaseString;
    resource = resource.msidTrimmedString.lowercaseString;
    clientId = clientId.msidTrimmedString.lowercaseString;
    
    NSString *adalCachePrefix = s_adalLibraryString;
    
    if (![NSString msidIsStringNilOrBlank:self.applicationIdentifier])
    {
        adalCachePrefix = [adalCachePrefix stringByAppendingFormat:@"-%@", self.applicationIdentifier.msidBase64UrlEncode];
    }

    NSString *service = [NSString stringWithFormat:s_adalServiceFormat,
                         adalCachePrefix,
                         authorityString.msidBase64UrlEncode,
                         [self getAttributeName:resource],
                         clientId.msidBase64UrlEncode];
    
    if (![NSString msidIsStringNilOrBlank:appKey])
    {
        service  = [NSString stringWithFormat:@"%@|%@", service, appKey];
    }
    
    return service;
}

- (instancetype)initWithAccount:(NSString *)account
                        service:(NSString *)service
                        generic:(NSData *)generic
                           type:(NSNumber *)type
{
    self = [super initWithAccount:account service:service generic:generic type:type];

    if (self)
    {
        [self setServiceKeyComponents];
    }

    return self;
}

- (instancetype)initWithEnvironment:(NSString *)environment
                              realm:(NSString *)realm
                           clientId:(NSString *)clientId
                           resource:(nullable NSString *)resource
                       legacyUserId:(NSString *)legacyUserId
{
    self = [super init];

    if (self)
    {
        _authority = [NSURL msidAADURLWithEnvironment:environment tenant:realm];
        _clientId = clientId;
        _resource = resource;
        _legacyUserId = legacyUserId;
    }

    return self;
}

- (instancetype)initWithAuthority:(NSURL *)authority
                         clientId:(NSString *)clientId
                         resource:(nullable NSString *)resource
                     legacyUserId:(NSString *)legacyUserId
{
    self = [super init];
    
    if (self)
    {
        _authority = authority;
        _clientId = clientId;
        _resource = resource;
        _legacyUserId = legacyUserId;
    }
    
    return self;
}

- (NSString *)account
{
    return _account ? _account : [self adalAccountWithUserId:self.legacyUserId];
}

- (NSString *)service
{
    return _service ? _service : [self serviceWithAuthority:self.authority resource:self.resource clientId:self.clientId appKey:self.appKey];
}

- (NSData *)generic
{
    return [s_adalLibraryString dataUsingEncoding:NSUTF8StringEncoding];
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

    _account = [coder decodeObjectOfClass:[NSString class] forKey:@"account"];
    _service = [coder decodeObjectOfClass:[NSString class] forKey:@"service"];
    _type = [coder decodeObjectOfClass:[NSNumber class] forKey:@"type"];
    _legacyUserId = [coder decodeObjectOfClass:[NSString class] forKey:@"userId"];

    // Backward compatibility with ADAL.
    if (!_service)
    {
        NSString *authority = [coder decodeObjectOfClass:[NSString class] forKey:@"authority"];
        self.authority = [NSURL URLWithString:authority];

        NSString *resource = [coder decodeObjectOfClass:[NSString class] forKey:@"resource"];
        self.resource = resource;

        NSString *clientId = [coder decodeObjectOfClass:[NSString class] forKey:@"clientId"];
        self.clientId = clientId;

        _service = self.service;
    }
    
    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder
{
    [self setServiceKeyComponents];

    [coder encodeObject:self.authority.absoluteString forKey:@"authority"];
    [coder encodeObject:self.resource forKey:@"resource"];
    [coder encodeObject:self.clientId forKey:@"clientId"];
    [coder encodeObject:self.legacyUserId forKey:@"userId"];
    [coder encodeObject:self.service forKey:@"service"];
    [coder encodeObject:self.account forKey:@"account"];
    [coder encodeObject:self.type forKey:@"type"];
}

#pragma mark - NSObject

- (BOOL)isEqual:(id)object
{
    if (self == object)
    {
        return YES;
    }
    
    if (![object isKindOfClass:MSIDCacheKey.class])
    {
        return NO;
    }
    
    return [self isEqualToTokenCacheKey:(MSIDLegacyTokenCacheKey *)object];
}

- (BOOL)isEqualToTokenCacheKey:(MSIDLegacyTokenCacheKey *)key
{
    if (!key)
    {
        return NO;
    }
    
    // Check for account match
    BOOL isAccountMatch = YES;
    if ((self.account && !key.account) || (!self.account && key.account))
    {
        isAccountMatch = NO;
    }
    else
    {
        isAccountMatch = (!self.account && !key.account) || [self.account isEqualToString:key.account];
    }
        
    // Check for service match
    BOOL isServiceMatch = YES;
    if ((self.service && !key.service) || (!self.service && key.service))
    {
        isServiceMatch = NO;
    }
    else
    {
        isServiceMatch = (!self.service && !key.service) || [self.service isEqualToString:key.service];
    }
    
    // Check for type match
    BOOL isTypeMatch = YES;
    if ((self.type == nil && key.type != nil) || (self.type != nil && key.type == nil))
    {
        isTypeMatch = NO;
    }
    else
    {
        isTypeMatch = (self.type == nil && key.type == nil) || [self.type isEqualToNumber:key.type];
    }
    
    return isAccountMatch && isServiceMatch && isTypeMatch;
}

- (NSUInteger)hash
{
    NSUInteger hash = 17;
    hash = hash * 31 + self.account.hash;
    hash = hash * 31 + self.service.hash;
    hash = hash * 31 + self.type.hash;
    
    return hash;
}

#pragma mark - NSCopying

- (id)copyWithZone:(NSZone *)zone
{
    MSIDLegacyTokenCacheKey *key = [[MSIDLegacyTokenCacheKey allocWithZone:zone] init];
    key->_account = [self.account copyWithZone:zone];
    key->_service = [self.service copyWithZone:zone];
    key->_generic = [self.generic copyWithZone:zone];
    key->_type = [self.type copyWithZone:zone];
    key->_authority = [self.authority copyWithZone:zone];
    key->_legacyUserId = [self.legacyUserId copyWithZone:zone];
    key->_resource = [self.resource copyWithZone:zone];
    key->_clientId = [self.clientId copyWithZone:zone];
    return key;
}

#pragma mark - Private
/*
 In order to be backward compatable with legacy format
 in ADAL we must to encode userId as base64 string
 for iOS only. For ADAL Mac we don't encode upn.
 */
- (NSString *)adalAccountWithUserId:(NSString *)userId
{
    if ([userId length])
    {
        userId = [MSIDHelpers normalizeUserId:userId];
    }
    
#if TARGET_OS_IPHONE
    return [userId msidBase64UrlEncode];
#endif
    
    return userId;
}

- (void)setServiceKeyComponents
{
    // Backward compatibility with ADAL.
    if (_service)
    {
        NSArray<NSString *> * items = [_service componentsSeparatedByString:@"|"];
        if (items.count == 4) // See s_adalServiceFormat.
        {
            NSString *authority = [items[1] msidBase64UrlDecode];
            self.authority = [NSURL URLWithString:authority];

            NSString *resource = [items[2] isEqualToString:MSID_LEGACY_CACHE_NIL_KEY] ? nil : [items[2] msidBase64UrlDecode];
            self.resource = resource;

            NSString *clientId = [items[3] msidBase64UrlDecode];
            self.clientId = clientId;
        }
    }
}

@end
