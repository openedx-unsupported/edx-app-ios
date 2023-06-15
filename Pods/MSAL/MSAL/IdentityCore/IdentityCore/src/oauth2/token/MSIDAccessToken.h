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

#import "MSIDBaseToken.h"

@interface MSIDAccessToken : MSIDBaseToken
{
    NSString *_accessToken;
    NSString *_tokenType;
    NSString *_kid;
}

@property (atomic, readwrite) NSDate *expiresOn;
@property (atomic, readwrite) NSDate *extendedExpiresOn;
@property (atomic, readwrite) NSDate *refreshOn;
@property (atomic, readwrite) NSDate *cachedAt;
@property (atomic, readwrite) NSString *accessToken;

// v1 access tokens are scoped down to resources
@property (atomic, readwrite) NSString *resource;

// v2 access tokens are scoped down to resources
@property (atomic, readwrite) NSOrderedSet<NSString *> *scopes;

// Intune Enrollment ID. Application trying to retrieve access token from cache will need to present a valid intune enrollment ID to complete cache lookup.
@property (atomic, readwrite) NSString *enrollmentId;

// Unique app identifier used for cases when access token storage needs to be partitioned per application
@property (atomic, readwrite) NSString *applicationIdentifier;

// Public key identifier used to bound the access tokens.
@property (nonatomic) NSString *kid;
@property (nonatomic) NSString *tokenType;

// Claims string sent to the server to produce this AT. Used by MSAL C++
@property (atomic, readwrite) NSString *requestedClaims;

- (BOOL)isExpired;
- (BOOL)isExpiredWithExpiryBuffer:(NSUInteger)expiryBuffer;
- (BOOL)isExtendedLifetimeValid;
- (BOOL)refreshNeeded;

@end
