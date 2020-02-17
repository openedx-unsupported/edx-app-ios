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

#import "MSIDTokenResult.h"
#import "MSIDAccessToken.h"
#import "MSIDIdToken.h"
#import "MSIDAuthority.h"

@implementation MSIDTokenResult

- (nullable instancetype)initWithAccessToken:(nonnull MSIDAccessToken *)accessToken
                                refreshToken:(nullable id<MSIDRefreshableToken>)refreshToken
                                     idToken:(nonnull NSString *)rawIdToken
                                     account:(nonnull MSIDAccount *)account
                                   authority:(nonnull MSIDAuthority *)authority
                               correlationId:(nonnull NSUUID *)correlationId
                               tokenResponse:(nullable MSIDTokenResponse *)tokenResponse
{
    self = [super init];

    if (self)
    {
        _accessToken = accessToken;
        _refreshToken = refreshToken;
        _rawIdToken = rawIdToken;
        _authority = authority;
        _correlationId = correlationId;
        _tokenResponse = tokenResponse;
        _account = account;
        _correlationId = correlationId;
    }

    return self;
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"MSIDTokenResult: access token %@, refresh token %@, raw ID token %@, authority %@, correlationID %@, token response %@, account %@", _PII_NULLIFY(_accessToken), _PII_NULLIFY(_refreshToken), _PII_NULLIFY(_rawIdToken), _authority, _correlationId, _PII_NULLIFY(_tokenResponse), _account];
}

@end
