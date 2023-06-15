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

#import "MSIDCacheKey.h"

NS_ASSUME_NONNULL_BEGIN

extern NSString *const MSID_LEGACY_CACHE_NIL_KEY;

@interface MSIDLegacyTokenCacheKey : MSIDCacheKey <NSCopying, NSSecureCoding>

@property (nullable, nonatomic) NSURL *authority;
@property (nullable, nonatomic) NSString *clientId;
@property (nullable, nonatomic) NSString *resource;
@property (nullable, nonatomic) NSString *legacyUserId;
@property (nullable, nonatomic) NSString *applicationIdentifier;

- (instancetype)initWithEnvironment:(NSString *)environment
                              realm:(NSString *)realm
                           clientId:(NSString *)clientId
                           resource:(nullable NSString *)resource
                       legacyUserId:(NSString *)legacyUserId;

- (instancetype)initWithAuthority:(NSURL *)authority
                         clientId:(NSString *)clientId
                         resource:(nullable NSString *)resource
                     legacyUserId:(NSString *)legacyUserId;

- (NSString *)serviceWithAuthority:(NSURL *)authority
                          resource:(nullable NSString *)resource
                          clientId:(NSString *)clientId
                            appKey:(nullable NSString *)appKey;

- (NSString *)adalAccountWithUserId:(NSString *)userId;

NS_ASSUME_NONNULL_END

@end
