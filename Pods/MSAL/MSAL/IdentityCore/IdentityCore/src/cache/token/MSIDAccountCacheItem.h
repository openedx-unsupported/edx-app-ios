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

#import "MSIDAccountType.h"
#import "MSIDJsonSerializable.h"
#import "MSIDKeyGenerator.h"
#import "MSIDDefaultAccountCacheKey.h"

@class MSIDClientInfo;

@interface MSIDAccountCacheItem : NSObject <NSCopying, MSIDJsonSerializable, MSIDKeyGenerator>

@property (atomic, readwrite) MSIDAccountType accountType;
@property (atomic, readwrite, nonnull) NSString *homeAccountId;
@property (atomic, readwrite, nonnull) NSString *environment;
@property (atomic, readwrite, nullable) NSString *localAccountId;
@property (atomic, readwrite, nullable) NSString *username;
@property (atomic, readwrite, nullable) NSString *givenName;
@property (atomic, readwrite, nullable) NSString *middleName;
@property (atomic, readwrite, nullable) NSString *familyName;
@property (atomic, readwrite, nullable) NSString *name;
@property (atomic, readwrite, nullable) NSString *realm;
@property (atomic, readwrite, nullable) MSIDClientInfo *clientInfo;
@property (atomic, readwrite, nullable) NSString *alternativeAccountId;

// Last Modification info (currently used on macOS only)
@property (atomic, readwrite, nullable) NSDate *lastModificationTime;
@property (atomic, readwrite, nullable) NSString *lastModificationApp;

@end
