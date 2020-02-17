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
#import "MSIDAccount.h"
#import "MSIDCredentialType.h"

NS_ASSUME_NONNULL_BEGIN

@interface MSIDDefaultCredentialCacheKey : MSIDCacheKey <NSCopying>

@property (nullable, nonatomic) NSString *homeAccountId;
@property (nullable, nonatomic) NSString *environment;
@property (nullable, nonatomic) NSString *realm;
@property (nullable, nonatomic) NSString *clientId;
@property (nullable, nonatomic) NSString *familyId;
@property (nullable, nonatomic) NSString *target;
@property (nullable, nonatomic) NSString *applicationIdentifier;
@property (nonatomic) MSIDCredentialType credentialType;

- (instancetype)initWithHomeAccountId:(NSString *)homeAccountId
                          environment:(NSString *)environment
                             clientId:(NSString *)clientId
                       credentialType:(MSIDCredentialType)type;

- (NSString *)serviceWithType:(MSIDCredentialType)type clientID:(NSString *)clientId realm:(nullable NSString *)realm applicationIdentifier:(nullable NSString *)applicationIdentifier target:(nullable NSString *)target appKey:(nullable NSString *)appKey;
- (NSString *)credentialIdWithType:(MSIDCredentialType)type clientId:(NSString *)clientId realm:(nullable NSString *)realm applicationIdentifier:(nullable NSString *)applicationIdentifier;
- (NSString *)accountIdWithHomeAccountId:(NSString *)homeAccountId environment:(NSString *)environment;
- (NSNumber *)credentialTypeNumber:(MSIDCredentialType)credentialType;

NS_ASSUME_NONNULL_END

@end
