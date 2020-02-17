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


#import "MSIDPRTCacheItem.h"
#import "NSString+MSIDExtensions.h"
#import "NSData+MSIDExtensions.h"

@implementation MSIDPRTCacheItem

#pragma mark - NSSecureCoding

+ (BOOL)supportsSecureCoding
{
    return YES;
}

- (void)encodeWithCoder:(NSCoder *)coder
{
    [super encodeWithCoder:coder];
    
    [coder encodeObject:self.sessionKey forKey:@"sessionKey"];
}

- (id)initWithCoder:(NSCoder *)decoder
{
    self = [super initWithCoder:decoder];
    if (self)
    {
        self.sessionKey = [decoder decodeObjectOfClass:[NSString class] forKey:@"sessionKey"];
        self.credentialType = MSIDPrimaryRefreshTokenType;
    }
    return self;
}

#pragma mark - MSIDJsonSerializable

- (instancetype)initWithJSONDictionary:(NSDictionary *)json error:(NSError **)error
{
    if (!(self = [super initWithJSONDictionary:json error:error]))
    {
        return nil;
    }
    
    if ([json msidStringObjectForKey:MSID_SESSION_KEY_CACHE_KEY])
    {
        _sessionKey = [NSData msidDataFromBase64UrlEncodedString:[json msidStringObjectForKey:MSID_SESSION_KEY_CACHE_KEY]];
    }
    
    return self;
}

- (NSDictionary *)jsonDictionary
{
    NSMutableDictionary *dictionary = [[super jsonDictionary] mutableCopy];
    
    if (!dictionary)
    {
        dictionary = [NSMutableDictionary new];
    }
    
    dictionary[MSID_SESSION_KEY_CACHE_KEY] = [self.sessionKey msidBase64UrlEncodedString];
    return dictionary;
}

#pragma mark - NSObject

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
    
    return [self isEqualToItem:(MSIDPRTCacheItem *)object];
}

- (BOOL)isEqualToItem:(MSIDPRTCacheItem *)item
{
    BOOL result = [super isEqualToItem:item];
    result &= (!self.sessionKey && !item.sessionKey) || [self.sessionKey isEqualToData:item.sessionKey];
    return result;
}

- (NSUInteger)hash
{
    NSUInteger hash = [super hash];
    hash = hash * 31 + self.sessionKey.hash;
    return hash;
}

@end
