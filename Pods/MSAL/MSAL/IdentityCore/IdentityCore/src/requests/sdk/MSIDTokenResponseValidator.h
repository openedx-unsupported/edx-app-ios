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

@class MSIDTokenResponse;
@class MSIDRequestParameters;
@class MSIDOauth2Factory;
@class MSIDTokenResult;
@class MSIDAccountMetadataCacheAccessor;
@class MSIDAuthenticationScheme;

@interface MSIDTokenResponseValidator : NSObject

- (nullable MSIDTokenResult *)validateAndSaveTokenResponse:(nonnull MSIDTokenResponse *)tokenResponse
                                              oauthFactory:(nonnull MSIDOauth2Factory *)factory
                                                tokenCache:(nonnull id<MSIDCacheAccessor>)tokenCache
                                      accountMetadataCache:(nullable MSIDAccountMetadataCacheAccessor *)metadataCache
                                         requestParameters:(nonnull MSIDRequestParameters *)parameters
                                          saveSSOStateOnly:(BOOL)saveSSOStateOnly
                                                     error:(NSError * _Nullable * _Nullable)error;

- (nullable MSIDTokenResult *)validateAndSaveBrokerResponse:(nonnull MSIDBrokerResponse *)brokerResponse
                                                  oidcScope:(nullable NSString *)oidcScope
                                           requestAuthority:(nullable NSURL *)requestAuthority
                                              instanceAware:(BOOL)instanceAware
                                               oauthFactory:(nonnull MSIDOauth2Factory *)factory
                                                 tokenCache:(nonnull id<MSIDCacheAccessor>)tokenCache
                                       accountMetadataCache:(nullable MSIDAccountMetadataCacheAccessor *)accountMetadataCache
                                              correlationID:(nullable NSUUID *)correlationID
                                           saveSSOStateOnly:(BOOL)saveSSOStateOnly
                                                 authScheme:(nonnull MSIDAuthenticationScheme *)authScheme
                                                      error:(NSError * _Nullable * _Nullable)error;

- (nullable MSIDTokenResult *)validateTokenResponse:(nonnull MSIDTokenResponse *)tokenResponse
                                       oauthFactory:(nonnull MSIDOauth2Factory *)factory
                                      configuration:(nonnull MSIDConfiguration *)configuration
                                     requestAccount:(nullable MSIDAccountIdentifier *)accountIdentifier
                                      correlationID:(nonnull NSUUID *)correlationID
                                              error:(NSError * _Nullable * _Nullable)error;

- (BOOL)validateAccount:(nonnull MSIDAccountIdentifier *)accountIdentifier
            tokenResult:(nonnull MSIDTokenResult *)tokenResult
          correlationID:(nonnull NSUUID *)correlationID
                  error:(NSError * _Nullable * _Nullable)error;

- (BOOL)validateTokenResult:(nonnull MSIDTokenResult *)tokenResult
              configuration:(nonnull MSIDConfiguration *)configuration
                  oidcScope:(nullable NSString *)oidcScope
              correlationID:(nonnull NSUUID *)correlationID
                      error:(NSError * _Nullable * _Nullable)error;

@end
