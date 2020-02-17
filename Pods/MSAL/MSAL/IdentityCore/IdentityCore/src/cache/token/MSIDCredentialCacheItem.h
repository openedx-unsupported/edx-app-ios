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
@class MSIDClientInfo;

@interface MSIDCredentialCacheItem : NSObject <NSCopying, MSIDJsonSerializable, MSIDKeyGenerator>

// Client id
@property (readwrite, nonnull) NSString *clientId;

// Token type
@property (readwrite) MSIDCredentialType credentialType;

// Token
@property (readwrite, nonnull) NSString *secret;

// Target
@property (readwrite, nullable) NSString *target;

// Realm
@property (readwrite, nullable) NSString *realm;

// Environment
@property (readwrite, nullable) NSString *environment;

// Dates
@property (readwrite, nullable) NSDate *expiresOn;
@property (readwrite, nullable) NSDate *extendedExpiresOn;
@property (readwrite, nullable) NSDate *cachedAt;

// Family ID
@property (readwrite, nullable) NSString *familyId;

// Unique user ID
@property (readwrite, nonnull) NSString *homeAccountId;

// Enrollment ID (access tokens only)
@property (readwrite, nullable) NSString *enrollmentId;

// speInfo
@property (readwrite, nullable) NSString *speInfo;

// Storing for latter token deletion purpose, not serialized
@property (readwrite, nullable) NSString *appKey;

// Application identifier
@property (readwrite, nullable) NSString *applicationIdentifier;

// Last Modification info (currently used on macOS only)
@property (readwrite, nullable) NSDate *lastModificationTime;
@property (readwrite, nullable) NSString *lastModificationApp;

- (BOOL)isEqualToItem:(nullable MSIDCredentialCacheItem *)item;

- (BOOL)matchesTarget:(nullable NSString *)target comparisonOptions:(MSIDComparisonOptions)comparisonOptions;

- (BOOL)matchesWithHomeAccountId:(nullable NSString *)homeAccountId
                     environment:(nullable NSString *)environment
              environmentAliases:(nullable NSArray<NSString *> *)environmentAliases;

- (BOOL)matchesWithRealm:(nullable NSString *)realm
                clientId:(nullable NSString *)clientId
                familyId:(nullable NSString *)familyId
                  target:(nullable NSString *)target
          targetMatching:(MSIDComparisonOptions)matchingOptions
        clientIdMatching:(MSIDComparisonOptions)clientIDMatchingOptions;

- (BOOL)isTombstone;

@end
