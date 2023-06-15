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
#import "MSIDAccountType.h"

NS_ASSUME_NONNULL_BEGIN

@interface MSIDDefaultAccountCacheKey : MSIDCacheKey <NSCopying>

@property (nullable, nonatomic) NSString *homeAccountId;
@property (nullable, nonatomic) NSString *environment;
@property (nullable, nonatomic) NSString *username;
@property (nullable, nonatomic) NSString *realm;
@property (nonatomic) MSIDAccountType accountType;

- (instancetype)initWithHomeAccountId:(NSString *)homeAccountId
                          environment:(NSString *)environment
                                realm:(NSString *)realm
                                 type:(MSIDAccountType)type;

@end

NS_ASSUME_NONNULL_END
