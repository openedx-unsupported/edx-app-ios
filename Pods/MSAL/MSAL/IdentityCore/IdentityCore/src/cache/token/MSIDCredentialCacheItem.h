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

#import "MSIDCredentialType.h"
#import "MSIDDefaultCredentialCacheQuery.h"
#import "MSIDJsonSerializable.h"
#import "MSIDKeyGenerator.h"

@class MSIDBaseToken;

@interface MSIDCredentialCacheItem : NSObject <NSCopying, MSIDJsonSerializable, MSIDKeyGenerator>

// Client id
@property (atomic, readwrite, nonnull) NSString *clientId;

// Token type
@property (atomic, readwrite) MSIDCredentialType credentialType;

// Token
@property (atomic, readwrite, nonnull) NSString *secret;

// Target
@property (atomic, readwrite, nullable) NSString *target;

// Realm
@property (atomic, readwrite, nullable) NSString *realm;

// Environment
@property (atomic, readwrite, nullable) NSString *environment;

// Dates
@property (atomic, readwrite, nullable) NSDate *expiresOn;
@property (atomic, readwrite, nullable) NSDate *extendedExpiresOn;
@property (atomic, readwrite, nullable) NSDate *refreshOn;
@property (atomic, readwrite, nullable) NSDate *cachedAt;
@property (atomic, readwrite, nullable) NSString *expiryInterval;
@property (atomic, readwrite, nullable) NSDate *lastRecoveryAttempt;

// Family ID
@property (atomic, readwrite, nullable) NSString *familyId;

// Unique user ID
@property (atomic, readwrite, nonnull) NSString *homeAccountId;

// Enrollment ID (access tokens only)
@property (atomic, readwrite, nullable) NSString *enrollmentId;

// speInfo
@property (atomic, readwrite, nullable) NSString *speInfo;

// Storing for latter token deletion purpose, not serialized
@property (atomic, readwrite, nullable) NSString *appKey;

// Application identifier
@property (atomic, readwrite, nullable) NSString *applicationIdentifier;

// Last Modification info (currently used on macOS only)
@property (atomic, readwrite, nullable) NSDate *lastModificationTime;
@property (atomic, readwrite, nullable) NSString *lastModificationApp;

@property (atomic, readwrite, nullable) NSString *tokenType;
@property (atomic, readwrite, nullable) NSString *kid;

// Requested claims for access tokens, currently only used by MSAL C++
@property (atomic, readwrite, nullable) NSString *requestedClaims;

- (BOOL)isEqualToItem:(nullable MSIDCredentialCacheItem *)item;

- (BOOL)matchesTarget:(nullable NSString *)target comparisonOptions:(MSIDComparisonOptions)comparisonOptions;

- (BOOL)matchesWithHomeAccountId:(nullable NSString *)homeAccountId
                     environment:(nullable NSString *)environment
              environmentAliases:(nullable NSArray<NSString *> *)environmentAliases;

- (BOOL)matchesWithRealm:(nullable NSString *)realm
                clientId:(nullable NSString *)clientId
                familyId:(nullable NSString *)familyId
                  target:(nullable NSString *)target
         requestedClaims:(nullable NSString *)requestedClaims
          targetMatching:(MSIDComparisonOptions)matchingOptions
        clientIdMatching:(MSIDComparisonOptions)clientIDMatchingOptions;

- (BOOL)isTombstone;

@end
