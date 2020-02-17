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

#import <Foundation/Foundation.h>
#import "MSIDCacheAccessor.h"

NS_ASSUME_NONNULL_BEGIN

@class MSIDOauth2Factory;
@class MSIDBrokerResponse;
@class MSIDTokenResult;
@class MSIDTokenResponseValidator;
@class MSIDBrokerCryptoProvider;

@interface MSIDBrokerResponseHandler : NSObject

@property (nonatomic, readonly, nonnull) MSIDOauth2Factory *oauthFactory;
@property (nonatomic, readonly, nullable) MSIDBrokerCryptoProvider *brokerCryptoProvider;
@property (nonatomic, readonly, nonnull) MSIDTokenResponseValidator *tokenResponseValidator;
@property (nonatomic, readonly, nullable) id<MSIDCacheAccessor> tokenCache;

@property (nonatomic, readonly) BOOL sourceApplicationAvailable;
@property (nonatomic, readonly) NSString *brokerNonce;

- (nullable instancetype)initWithOauthFactory:(MSIDOauth2Factory *)factory
                       tokenResponseValidator:(MSIDTokenResponseValidator *)responseValidator;

- (nullable MSIDTokenResult *)handleBrokerResponseWithURL:(NSURL *)url sourceApplication:(nullable NSString *)sourceApplication error:(NSError * _Nullable * _Nullable)error;

- (BOOL)canHandleBrokerResponse:(NSURL *)response
             hasCompletionBlock:(BOOL)hasCompletionBlock;

- (BOOL)checkBrokerNonce:(NSDictionary *)responseDict;

@end

NS_ASSUME_NONNULL_END
