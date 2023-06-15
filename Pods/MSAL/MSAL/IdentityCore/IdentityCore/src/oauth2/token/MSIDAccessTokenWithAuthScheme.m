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

#import "MSIDAccessTokenWithAuthScheme.h"
#import "MSIDCredentialCacheItem.h"

@implementation MSIDAccessTokenWithAuthScheme

#pragma mark - Token type

- (MSIDCredentialType)credentialType
{
    return MSIDAccessTokenWithAuthSchemeType;
}

- (MSIDCredentialCacheItem *)tokenCacheItem
{
    MSIDCredentialCacheItem *cacheItem = [super tokenCacheItem];
    cacheItem.kid = self.kid;
    cacheItem.tokenType = self.tokenType;
    return cacheItem;
}

#pragma mark - NSCopying

- (id)copyWithZone:(NSZone *)zone
{
    MSIDAccessTokenWithAuthScheme *item = [super copyWithZone:zone];
    item->_kid = [_kid copyWithZone:zone];
    item->_tokenType = [_tokenType copyWithZone:zone];
    return item;
}

#pragma mark - NSObject

- (BOOL)isEqual:(id)object
{
    if (self == object)
    {
        return YES;
    }
    
    if (![object isKindOfClass:MSIDAccessTokenWithAuthScheme.class])
    {
        return NO;
    }
    
    return [self isEqualToItem:(MSIDAccessTokenWithAuthScheme *)object];
}

- (NSUInteger)hash
{
    NSUInteger hash = [super hash];
    hash = hash * 31 + self.kid.hash;
    hash = hash * 31 + self.tokenType.hash;
    return hash;
}

- (BOOL)isEqualToItem:(MSIDAccessTokenWithAuthScheme *)token
{
    if (!token)
    {
        return NO;
    }
    
    BOOL result = [super isEqualToItem:token];
    result &= (!self.kid && !token.kid) || [self.kid isEqualToString:token.kid];
    result &= (!self.tokenType && !token.tokenType) || [self.tokenType isEqualToString:token.tokenType];
    return result;
}

#pragma mark - Cache

- (instancetype)initWithTokenCacheItem:(MSIDCredentialCacheItem *)tokenCacheItem
{
    self = [super initWithTokenCacheItem:tokenCacheItem];
    
    if (self)
    {
        _kid = tokenCacheItem.kid;
        
        if (!_kid)
        {
            MSID_LOG_WITH_CTX(MSIDLogLevelWarning,nil, @"Trying to initialize access token when missing kid field");
            return nil;
        }
        
        _tokenType = tokenCacheItem.tokenType;
        if (!_tokenType)
        {
            MSID_LOG_WITH_CTX(MSIDLogLevelWarning,nil, @"Trying to initialize access token when missing token type field");
            return nil;
        }
    }
    
    return self;
}

@end
