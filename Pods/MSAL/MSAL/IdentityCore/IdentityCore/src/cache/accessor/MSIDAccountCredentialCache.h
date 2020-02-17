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
#import "MSIDCredentialType.h"
#import "MSIDAccountType.h"

@class MSIDAccountCacheItem;
@class MSIDAppMetadataCacheItem;
@class MSIDAppMetadataCacheQuery;
@class MSIDCredentialCacheItem;
@class MSIDDefaultAccountCacheKey;
@class MSIDDefaultAccountCacheQuery;
@class MSIDDefaultCredentialCacheKey;
@class MSIDDefaultCredentialCacheQuery;
@protocol MSIDRequestContext;
@protocol MSIDExtendedTokenCacheDataSource;

@interface MSIDAccountCredentialCache : NSObject

- (nonnull instancetype)initWithDataSource:(nonnull id<MSIDExtendedTokenCacheDataSource>)dataSource;

/*
 Gets all credentials matching the parameters specified in the query
 */
- (nullable NSArray<MSIDCredentialCacheItem *> *)getCredentialsWithQuery:(nonnull MSIDDefaultCredentialCacheQuery *)cacheQuery
                                                                 context:(nullable id<MSIDRequestContext>)context
                                                                   error:(NSError * _Nullable * _Nullable)error;

/*
 Gets a credential for a particular key
*/
- (nullable MSIDCredentialCacheItem *)getCredential:(nonnull MSIDDefaultCredentialCacheKey *)key
                                            context:(nullable id<MSIDRequestContext>)context
                                              error:(NSError * _Nullable * _Nullable)error;

/*
 Gets all credentials which a matching type
*/
- (nullable NSArray<MSIDCredentialCacheItem *> *)getAllCredentialsWithType:(MSIDCredentialType)type
                                                                   context:(nullable id<MSIDRequestContext>)context
                                                                     error:(NSError * _Nullable * _Nullable)error;

/*
 Gets all accounts matching the parameters specified in the query
 */
- (nullable NSArray<MSIDAccountCacheItem *> *)getAccountsWithQuery:(nonnull MSIDDefaultAccountCacheQuery *)cacheQuery
                                                           context:(nullable id<MSIDRequestContext>)context
                                                             error:(NSError * _Nullable * _Nullable)error;

/*
 Gets an account for a particular key
*/
- (nullable MSIDAccountCacheItem *)getAccount:(nonnull MSIDDefaultAccountCacheKey *)key
                                      context:(nullable id<MSIDRequestContext>)context
                                        error:(NSError * _Nullable * _Nullable)error;

/*
 Gets all accounts which a matching type
 */
- (nullable NSArray<MSIDAccountCacheItem *> *)getAllAccountsWithType:(MSIDAccountType)type
                                                             context:(nullable id<MSIDRequestContext>)context
                                                               error:(NSError * _Nullable * _Nullable)error;

/*
 Gets all items
 */
- (nullable NSArray<MSIDCredentialCacheItem *> *)getAllItemsWithContext:(nullable id<MSIDRequestContext>)context
                                                                  error:(NSError * _Nullable * _Nullable)error;

/*
 Saves a credential
*/
- (BOOL)saveCredential:(nonnull MSIDCredentialCacheItem *)credential
               context:(nullable id<MSIDRequestContext>)context
                 error:(NSError * _Nullable * _Nullable)error;

/*
 Saves an account
*/
- (BOOL)saveAccount:(nonnull MSIDAccountCacheItem *)account
            context:(nullable id<MSIDRequestContext>)context
              error:(NSError * _Nullable * _Nullable)error;

/*
 Removes credentials matching parameters specified in the query
 */
- (BOOL)removeCredetialsWithQuery:(nonnull MSIDDefaultCredentialCacheQuery *)cacheQuery
                          context:(nullable id<MSIDRequestContext>)context
                            error:(NSError * _Nullable * _Nullable)error;

/*
 Removes a credential
*/
- (BOOL)removeCredential:(nonnull MSIDCredentialCacheItem *)credential
                 context:(nullable id<MSIDRequestContext>)context
                   error:(NSError * _Nullable * _Nullable)error;

/*
 Removes multiple accounts matching parameters
*/
- (BOOL)removeAccountsWithQuery:(nonnull MSIDDefaultAccountCacheQuery *)cacheQuery
                        context:(nullable id<MSIDRequestContext>)context
                          error:(NSError * _Nullable * _Nullable)error;

/*
 Removes an account
*/
- (BOOL)removeAccount:(nonnull MSIDAccountCacheItem *)account
              context:(nullable id<MSIDRequestContext>)context
                error:(NSError * _Nullable * _Nullable)error;

/*
 Clears the whole cache, should only be used for testing!
 */
- (BOOL)clearWithContext:(nullable id<MSIDRequestContext>)context
                   error:(NSError * _Nullable * _Nullable)error;

/*
 Removes all credentials in the array
 */
- (BOOL)removeAllCredentials:(nonnull NSArray<MSIDCredentialCacheItem *> *)credentials
                     context:(nullable id<MSIDRequestContext>)context
                       error:(NSError * _Nullable * _Nullable)error;

/*
 Removes all accounts in the array
 */
- (BOOL)removeAllAccounts:(nonnull NSArray<MSIDAccountCacheItem *> *)accounts
                  context:(nullable id<MSIDRequestContext>)context
                    error:(NSError * _Nullable * _Nullable)error;

/*
 Returns latest wipe info
 */
- (nullable NSDictionary *)wipeInfoWithContext:(nullable id<MSIDRequestContext>)context
                                         error:(NSError * _Nullable * _Nullable)error;


/*
  Saves the latest wipe info
 */
- (BOOL)saveWipeInfoWithContext:(nullable id<MSIDRequestContext>)context
                          error:(NSError * _Nullable * _Nullable)error;

/*
 Saves app metadata
 */
- (BOOL)saveAppMetadata:(nonnull MSIDAppMetadataCacheItem *)metadata
                context:(nullable id<MSIDRequestContext>)context
                  error:(NSError * _Nullable * _Nullable)error;

/*
 Remove app metadata
 */
- (BOOL)removeAppMetadata:(nonnull MSIDAppMetadataCacheItem *)appMetadata
                  context:(nullable id<MSIDRequestContext>)context
                    error:(NSError * _Nullable * _Nullable)error;


//Get app metadata entries for a query
- (nullable NSArray<MSIDAppMetadataCacheItem *> *)getAppMetadataEntriesWithQuery:(nonnull MSIDAppMetadataCacheQuery *)query
                                                                         context:(nullable id<MSIDRequestContext>)context
                                                                           error:(NSError * _Nullable * _Nullable)error;

@end
