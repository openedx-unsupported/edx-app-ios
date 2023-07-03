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
#import "MSIDExtendedTokenCacheDataSource.h"

@interface MSIDKeychainTokenCache : NSObject<MSIDExtendedTokenCacheDataSource>

/*!
 The name of the group to be used by default when creating an instance of MSIDKeychainTokenCache,
 the default value is com.microsoft.adalcache.
 
 If set to 'nil' the main bundle's identifier will be used instead. Any keychain sharing group other 
 then the main bundle's identifier will require a keychain sharing group entitlement.
 
 See apple's documentation for keychain groups: such groups require certain
 entitlements to be set by the applications. Additionally, access to the items in this group
 is only given to the applications from the same vendor. If this property is not set, the behavior
 will depend on the values in the entitlements file (if such exists) and may not result in token
 sharing. The property has no effect if other cache mechanisms are used (non-keychain).
 
 NOTE: Once an authentication context has been created with the default keychain
 group, or +[ADKeychainTokenCache defaultKeychainCache] has been called then
 this value cannot be changed. Doing so will throw an exception.
 */
@property (class, nullable) NSString *defaultKeychainGroup;

/*!
 Default cache. Will be initialized with defaultKeychainGroup.
 */
@property (class, readonly, nonnull) MSIDKeychainTokenCache *defaultKeychainCache;

/*!
 Actual keychain sharing group used for queries.
 Contains team id (<team id>.<keychain group>)
 */
@property (readonly, nonnull) NSString *keychainGroup;

/*!
 Initialize with keychainGroup.
 @param keychainGroup Optional. If the application needs to share the cached tokens
 with other applications from the same vendor, the app will need to specify the
 shared group here and add the necessary entitlements to the application.
 
 If set to 'nil' the main bundle's identifier will be used instead.
 
 NOTE: init: initializes with defaultKeychainGroup.

 See Apple's keychain services documentation for details.
 */
- (nullable instancetype)initWithGroup:(nullable NSString *)keychainGroup error:(NSError * _Nullable __autoreleasing * _Nullable)error;

@end
