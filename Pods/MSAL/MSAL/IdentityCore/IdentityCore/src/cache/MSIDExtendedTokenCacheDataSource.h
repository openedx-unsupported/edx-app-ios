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
#import "MSIDTokenCacheDataSource.h"
#import "MSIDMetadataCacheDataSource.h"

@class MSIDAccountCacheItem;
@protocol MSIDRequestContext;
@class MSIDCacheKey;
@class MSIDJsonObject;
@protocol MSIDExtendedCacheItemSerializing;
@protocol MSIDJsonSerializing;

// Token cache data source supporting additional advanced types like accounts, app metadata and generic items
@protocol MSIDExtendedTokenCacheDataSource <MSIDTokenCacheDataSource, MSIDMetadataCacheDataSource>

// Accounts
- (BOOL)saveAccount:(MSIDAccountCacheItem *)item
                key:(MSIDCacheKey *)key
         serializer:(id<MSIDExtendedCacheItemSerializing>)serializer
            context:(id<MSIDRequestContext>)context
              error:(NSError **)error;

- (MSIDAccountCacheItem *)accountWithKey:(MSIDCacheKey *)key
                              serializer:(id<MSIDExtendedCacheItemSerializing>)serializer
                                 context:(id<MSIDRequestContext>)context
                                   error:(NSError **)error;

- (NSArray<MSIDAccountCacheItem *> *)accountsWithKey:(MSIDCacheKey *)key
                                          serializer:(id<MSIDExtendedCacheItemSerializing>)serializer
                                             context:(id<MSIDRequestContext>)context
                                               error:(NSError **)error;

- (BOOL)removeAccountsWithKey:(MSIDCacheKey *)key
                      context:(id<MSIDRequestContext>)context
                        error:(NSError **)error;

// JSON Object
- (NSArray<MSIDJsonObject *> *)jsonObjectsWithKey:(MSIDCacheKey *)key
                                       serializer:(id<MSIDExtendedCacheItemSerializing>)serializer
                                          context:(id<MSIDRequestContext>)context
                                            error:(NSError **)error;

- (BOOL)saveJsonObject:(MSIDJsonObject *)jsonObject
            serializer:(id<MSIDExtendedCacheItemSerializing>)serializer
                   key:(MSIDCacheKey *)key
               context:(id<MSIDRequestContext>)context
                 error:(NSError **)error;

@end
