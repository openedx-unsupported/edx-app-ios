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

@interface MSIDCacheKey : NSObject <NSCopying>
{
    NSString *_account;
    NSString *_service;
    NSNumber *_type;
    NSData *_generic;
}

NS_ASSUME_NONNULL_BEGIN

/* Corresponds to kSecAttrAccount */
@property (atomic, nullable, readonly) NSString *account;

/* Corresponds to kSecAttrService */
@property (atomic, nullable, readonly) NSString *service;

/* Corresponds to kSecAttrType */
@property (atomic, nullable, readonly) NSNumber *type;

/* Corresponds to kSecAttrGeneric */
@property (atomic, nullable, readonly) NSData *generic;

/* Application key for keychain isolation */
@property (atomic, nullable, readwrite) NSString *appKey;

/* OSX specific property. Determines if an item is shared across apps.  */
@property (atomic, readonly) BOOL isShared;

- (nullable id)initWithAccount:(nullable NSString *)account
                       service:(nullable NSString *)service
                       generic:(nullable NSData *)generic
                          type:(nullable NSNumber *)type;

/*!
 Helper method to get the clientId from the provided familyId
 */
+ (NSString *)familyClientId:(NSString *)familyId;

- (NSString *)logDescription;
- (NSString *)piiLogDescription;
- (nullable NSNumber *)appKeyHash;

NS_ASSUME_NONNULL_END

@end
