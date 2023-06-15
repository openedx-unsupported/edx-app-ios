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

#import "MSIDIdToken.h"
#import "MSIDUserInformation.h"
#import "MSIDTokenResponse.h"
#import "NSURL+MSIDExtensions.h"

@implementation MSIDIdToken

#pragma mark - NSCopying

- (id)copyWithZone:(NSZone *)zone
{
    MSIDIdToken *item = [super copyWithZone:zone];
    item->_rawIdToken = [_rawIdToken copyWithZone:zone];
    return item;
}

#pragma mark - NSObject

- (BOOL)isEqual:(id)object
{
    if (self == object)
    {
        return YES;
    }
    
    if (![object isKindOfClass:MSIDIdToken.class])
    {
        return NO;
    }
    
    return [self isEqualToItem:(MSIDIdToken *)object];
}

- (NSUInteger)hash
{
    NSUInteger hash = [super hash];
    hash = hash * 31 + self.rawIdToken.hash;
    return hash;
}

- (BOOL)isEqualToItem:(MSIDIdToken *)token
{
    if (!token)
    {
        return NO;
    }
    
    BOOL result = [super isEqualToItem:token];
    result &= (!self.rawIdToken && !token.rawIdToken) || [self.rawIdToken isEqualToString:token.rawIdToken];
    return result;
}

#pragma mark - Cache

- (instancetype)initWithTokenCacheItem:(MSIDCredentialCacheItem *)tokenCacheItem
{
    self = [super initWithTokenCacheItem:tokenCacheItem];
    
    if (self)
    {
        _rawIdToken = tokenCacheItem.secret;
        
        if (!_rawIdToken)
        {
            MSID_LOG_WITH_CTX(MSIDLogLevelWarning,nil, @"Trying to initialize ID token when missing ID token field");
            return nil;
        }
    }
    
    return self;
}

- (MSIDCredentialCacheItem *)tokenCacheItem
{
    MSIDCredentialCacheItem *cacheItem = [super tokenCacheItem];
    cacheItem.secret = self.rawIdToken;
    cacheItem.credentialType = MSIDIDTokenType;
    return cacheItem;
}

#pragma mark - Token type

- (MSIDCredentialType)credentialType
{
    return MSIDIDTokenType;
}

#pragma mark - Description

- (NSString *)description
{
    NSString *baseDescription = [super description];
    return [baseDescription stringByAppendingFormat:@"(id token=%@)", [_rawIdToken msidSecretLoggingHash]];
}

@end
