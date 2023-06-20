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
#import "MSIDCacheAccessor.h"
#import "MSIDAccountCredentialCache.h"

@class MSIDAccountIdentifier;
@class MSIDConfiguration;
@protocol MSIDRequestContext;
@class MSIDRefreshToken;
@class MSIDAccessToken;
@class MSIDAccount;
@class MSIDIdToken;
@class MSIDAuthority;
@class MSIDAppMetadataCacheItem;
@class MSIDAccountMetadataCacheAccessor;
@protocol MSIDExtendedTokenCacheDataSource;

@interface MSIDDefaultTokenCacheAccessor : NSObject <MSIDCacheAccessor>

@property (nonatomic, readonly) MSIDAccountCredentialCache *accountCredentialCache;

- (instancetype)initWithDataSource:(id<MSIDExtendedTokenCacheDataSource>)dataSource
               otherCacheAccessors:(NSArray<id<MSIDCacheAccessor>> *)otherAccessors;

- (MSIDAccessToken *)getAccessTokenForAccount:(MSIDAccountIdentifier *)account
                                configuration:(MSIDConfiguration *)configuration
                                      context:(id<MSIDRequestContext>)context
                                        error:(NSError **)error;

- (MSIDIdToken *)getIDTokenForAccount:(MSIDAccountIdentifier *)account
                        configuration:(MSIDConfiguration *)configuration
                          idTokenType:(MSIDCredentialType)idTokenType
                              context:(id<MSIDRequestContext>)context
                                error:(NSError **)error;

- (MSIDAccount *)getAccountForIdentifier:(MSIDAccountIdentifier *)accountIdentifier
                               authority:(MSIDAuthority *)authority
                               realmHint:(NSString *)realmHint
                                 context:(id<MSIDRequestContext>)context
                                   error:(NSError **)error;

- (BOOL)removeToken:(MSIDBaseToken *)token
            context:(id<MSIDRequestContext>)context
              error:(NSError **)error;

- (BOOL)saveToken:(MSIDBaseToken *)token
          context:(id<MSIDRequestContext>)context
            error:(NSError **)error;

- (NSArray<MSIDAppMetadataCacheItem *> *)getAppMetadataEntries:(MSIDConfiguration *)configuration
                                                       context:(id<MSIDRequestContext>)context
                                                         error:(NSError **)error;

- (BOOL)saveAppMetadataWithConfiguration:(MSIDConfiguration *)configuration
                                response:(MSIDTokenResponse *)response
                                 factory:(MSIDOauth2Factory *)factory
                                 context:(id<MSIDRequestContext>)context
                                   error:(NSError **)error;

- (BOOL)updateAppMetadataWithFamilyId:(NSString *)familyId
                             clientId:(NSString *)clientId
                            authority:(MSIDAuthority *)authority
                              context:(id<MSIDRequestContext>)context
                                error:(NSError **)error;

- (BOOL)clearCacheForAccount:(MSIDAccountIdentifier *)accountIdentifier
                   authority:(MSIDAuthority *)authority
                    clientId:(NSString *)clientId
                    familyId:(NSString *)familyId
               clearAccounts:(BOOL)clearAccounts
                     context:(id<MSIDRequestContext>)context
                       error:(NSError **)error;

- (BOOL)clearCacheForAllAccountsWithContext:(id<MSIDRequestContext>)context
                                      error:(NSError **)error;

- (NSArray<MSIDAccount *> *)accountsWithAuthority:(MSIDAuthority *)authority
                                         clientId:(NSString *)clientId
                                         familyId:(NSString *)familyId
                                accountIdentifier:(MSIDAccountIdentifier *)accountIdentifier
                             accountMetadataCache:(MSIDAccountMetadataCacheAccessor *)accountMetadataCache
                             signedInAccountsOnly:(BOOL)signedInAccountsOnly
                                          context:(id<MSIDRequestContext>)context
                                            error:(NSError **)error;

- (NSArray<MSIDPrimaryRefreshToken *> *)getPrimaryRefreshTokensForConfiguration:(MSIDConfiguration *)configuration
                                                                        context:(id<MSIDRequestContext>)context
                                                                          error:(NSError **)error;

@end
