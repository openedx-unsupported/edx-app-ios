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
#import "MSIDRefreshableToken.h"

NS_ASSUME_NONNULL_BEGIN

@class MSIDAccessToken;
@class MSIDIdToken;
@class MSIDAccount;
@class MSIDAuthority;
@class MSIDTokenResponse;

@interface MSIDTokenResult : NSObject

/*! The Access Token requested. */
@property (nonatomic) MSIDAccessToken *accessToken;

/*! The Refresh Token for this request. */
@property (nonatomic, nullable) id<MSIDRefreshableToken> refreshToken;

/*! ID token */
@property (nonatomic) NSString *rawIdToken;

/*! Account object */
@property (nonatomic) MSIDAccount *account;

/*!
 Some access tokens have extended lifetime when server is in an unavailable state.
 This property indicates whether the access token is returned in such a state.
 */
@property (nonatomic) BOOL extendedLifeTimeToken;

/*!
 Represents the authority used for getting the token from STS and caching it.
 This authority should be used for subsequent silent requests.
 It will be different from the authority provided by developer for sovereign cloud scenarios.
 */
@property (nonatomic) MSIDAuthority *authority;

/*! The correlation ID of the request(s) that get this result. */
@property (nonatomic) NSUUID *correlationId;

/* Token response from server */
@property (nonatomic, nullable) MSIDTokenResponse *tokenResponse;

/* Broker app version used for brokered authentication */
@property (nonatomic, nullable) NSString *brokerAppVersion;

- (nullable instancetype)initWithAccessToken:(nonnull MSIDAccessToken *)accessToken
                                refreshToken:(nullable id<MSIDRefreshableToken>)refreshToken
                                     idToken:(nonnull NSString *)rawIdToken
                                     account:(nonnull MSIDAccount *)account
                                   authority:(nonnull MSIDAuthority *)authority
                               correlationId:(nonnull NSUUID *)correlationId
                               tokenResponse:(nullable MSIDTokenResponse *)tokenResponse;

@end

NS_ASSUME_NONNULL_END
