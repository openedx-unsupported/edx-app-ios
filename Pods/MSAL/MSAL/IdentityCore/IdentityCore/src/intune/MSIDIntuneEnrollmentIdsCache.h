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
#import "MSIDIntuneCacheDataSource.h"

#define MSID_INTUNE_ENROLLMENT_ID @"intune_app_protection_enrollment_id_V"
#define MSID_INTUNE_ENROLLMENT_ID_VERSION @"1"
#define MSID_INTUNE_ENROLLMENT_ID_KEY (MSID_INTUNE_ENROLLMENT_ID MSID_INTUNE_ENROLLMENT_ID_VERSION)

@protocol MSIDRequestContext;

NS_ASSUME_NONNULL_BEGIN

@interface MSIDIntuneEnrollmentIdsCache : NSObject

@property (class, strong) MSIDIntuneEnrollmentIdsCache *sharedCache;

- (instancetype)initWithDataSource:(id<MSIDIntuneCacheDataSource>)dataSource;
- (instancetype _Nullable)init NS_UNAVAILABLE;
+ (instancetype _Nullable)new NS_UNAVAILABLE;

- (nullable NSString *)enrollmentIdForUserId:(NSString *)userId
                                     context:(nullable id<MSIDRequestContext>)context
                                       error:(NSError *__autoreleasing *)error;

- (nullable NSString *)enrollmentIdForUserObjectId:(NSString *)userObjectId
                                          tenantId:(NSString *)tenantId
                                           context:(nullable id<MSIDRequestContext>)context
                                             error:(NSError *__autoreleasing *)error;

- (nullable NSString *)enrollmentIdForHomeAccountId:(NSString *)homeAccountId
                                            context:(nullable id<MSIDRequestContext>)context
                                              error:(NSError *__autoreleasing *)error;

/*!
 Tries to find an enrollmentID for a homeAccountId first,
 then checks legacyUserId, then returns any enrollmentId available.
 */
- (nullable NSString *)enrollmentIdForHomeAccountId:(nullable NSString *)homeAccountId
                                       legacyUserId:(nullable NSString *)legacyUserId
                                            context:(nullable id<MSIDRequestContext>)context
                                              error:(NSError *__autoreleasing *)error;

/*!
 Returns the first available enrollmentID if one is available.
 */
- (nullable NSString *)enrollmentIdIfAvailableWithContext:(nullable id<MSIDRequestContext>)context
                                                    error:(NSError *__autoreleasing *)error;

- (BOOL)setEnrollmentIdsJsonDictionary:(NSDictionary *)jsonDictionary
                               context:(nullable id<MSIDRequestContext>)context
                                 error:(NSError *__autoreleasing *)error;

- (nullable NSDictionary *)enrollmentIdsJsonDictionaryWithContext:(nullable id<MSIDRequestContext>)context
                                                            error:(NSError *__autoreleasing *)error;

/*!
 Clears the cache, removing all stored enrollment ids from data source.
 */
- (void)clear;

@end

NS_ASSUME_NONNULL_END
