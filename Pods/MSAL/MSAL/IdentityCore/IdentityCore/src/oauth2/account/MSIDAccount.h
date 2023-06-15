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
#import "MSIDAccountType.h"
#import "MSIDJsonSerializable.h"

@class MSIDAccountCacheItem;
@class MSIDConfiguration;
@class MSIDTokenResponse;
@class MSIDClientInfo;
@class MSIDAccountIdentifier;
@class MSIDAuthority;
@class MSIDIdTokenClaims;

@interface MSIDAccount : NSObject <NSCopying, MSIDJsonSerializable>

@property (atomic, readwrite) MSIDAccountType accountType;
@property (atomic, readwrite) NSString *localAccountId;

/*
 'storageEnvironment' is used only for latter token deletion.
 We can not use 'environment' because cache item could be saved with
 'preferred authority' and it might not be equal to provided 'authority'.
 */
@property (atomic, readwrite) NSString *storageEnvironment;
@property (atomic, readwrite) NSString *environment;
@property (atomic, readwrite) NSString *realm;
/*
 'idTokenClaims' is used to convey corresponding the id token claims for the account.
 */
@property (atomic, readwrite) MSIDIdTokenClaims *idTokenClaims;

@property (atomic, readwrite) NSString *username;
@property (atomic, readwrite) NSString *givenName;
@property (atomic, readwrite) NSString *middleName;
@property (atomic, readwrite) NSString *familyName;
@property (atomic, readwrite) NSString *name;
@property (atomic, readwrite) MSIDAccountIdentifier *accountIdentifier;
@property (atomic, readwrite) MSIDClientInfo *clientInfo;
@property (atomic, readwrite) NSString *alternativeAccountId;
@property (atomic, readwrite) BOOL isSSOAccount;

- (instancetype)initWithAccountCacheItem:(MSIDAccountCacheItem *)cacheItem;
- (MSIDAccountCacheItem *)accountCacheItem;
- (BOOL)isHomeTenantAccount;

@end
