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

#import "MSIDCredentialCacheItem.h"
#import "MSIDCredentialCacheItem+MSIDBaseToken.h"
#import "MSIDCredentialType.h"
#import "MSIDBaseToken.h"
#import "MSIDAccessToken.h"
#import "MSIDRefreshToken.h"
#import "MSIDLegacySingleResourceToken.h"
#import "MSIDIdToken.h"
#import "MSIDAADIdTokenClaimsFactory.h"
#import "MSIDPrimaryRefreshToken.h"
#import "MSIDV1IdToken.h"

@implementation MSIDCredentialCacheItem (MSIDBaseToken)

- (MSIDBaseToken *)tokenWithType:(MSIDCredentialType)credentialType
{
    switch (credentialType)
    {
        case MSIDAccessTokenType:
        {
            return [[MSIDAccessToken alloc] initWithTokenCacheItem:self];
        }
        case MSIDRefreshTokenType:
        {
            return [[MSIDRefreshToken alloc] initWithTokenCacheItem:self];
        }
        case MSIDLegacySingleResourceTokenType:
        {
            return [[MSIDLegacySingleResourceToken alloc] initWithTokenCacheItem:self];
        }
        case MSIDIDTokenType:
        {
            return [[MSIDIdToken alloc] initWithTokenCacheItem:self];
        }
        case MSIDLegacyIDTokenType:
        {
            return [[MSIDV1IdToken alloc] initWithTokenCacheItem:self];
        }
        case MSIDPrimaryRefreshTokenType:
        {
            return [[MSIDPrimaryRefreshToken alloc] initWithTokenCacheItem:self];
        }
        default:
            return [[MSIDBaseToken alloc] initWithTokenCacheItem:self];
    }

    return nil;
}

@end
