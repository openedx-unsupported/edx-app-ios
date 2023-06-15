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
#import "MSIDAuthorityResolving.h"
#import "MSIDCache.h"
#import "MSIDJsonSerializable.h"

extern NSString * _Nonnull const MSID_AUTHORITY_URL_JSON_KEY;
extern NSString * _Nonnull const MSID_AUTHORITY_TYPE_JSON_KEY;

@class MSIDOpenIdProviderMetadata;

typedef void(^MSIDOpenIdConfigurationInfoBlock)(MSIDOpenIdProviderMetadata * _Nullable metadata, NSError * _Nullable error);

@interface MSIDAuthority : NSObject <NSCopying, MSIDJsonSerializable>
{
@protected
    NSURL *_url;
    NSString *_realm;
    NSURL *_openIdConfigurationEndpoint;
}

@property (class, readonly, nonnull) MSIDCache *openIdConfigurationCache;

@property (atomic, readonly, nonnull) NSURL *url;

@property (atomic, readonly, nonnull) NSString *environment;

@property (atomic, readonly, nonnull) NSString *realm;

@property (atomic, readonly, nullable) NSURL *openIdConfigurationEndpoint;

@property (atomic, readonly, nullable) MSIDOpenIdProviderMetadata *metadata;

@property (nonatomic) BOOL isDeveloperKnown;

- (instancetype _Nullable )init NS_UNAVAILABLE;
+ (instancetype _Nullable )new NS_UNAVAILABLE;

- (void)resolveAndValidate:(BOOL)validate
         userPrincipalName:(nullable NSString *)upn
                   context:(nullable id<MSIDRequestContext>)context
           completionBlock:(nonnull MSIDAuthorityInfoBlock)completionBlock;

- (nonnull NSURL *)networkUrlWithContext:(nullable id<MSIDRequestContext>)context;

- (nonnull NSURL *)cacheUrlWithContext:(nullable id<MSIDRequestContext>)context;

- (nonnull NSString *)cacheEnvironmentWithContext:(nullable id<MSIDRequestContext>)context;

- (nonnull NSArray<NSURL *> *)legacyAccessTokenLookupAuthorities;

- (nonnull NSURL *)universalAuthorityURL;

- (nonnull NSArray<NSURL *> *)legacyRefreshTokenLookupAliases;

- (nonnull NSArray<NSString *> *)defaultCacheEnvironmentAliases;

- (nullable NSString *)enrollmentIdForHomeAccountId:(nullable NSString *)homeAccountId
                                       legacyUserId:(nullable NSString *)legacyUserId
                                            context:(nullable id<MSIDRequestContext>)context
                                              error:(NSError * _Nullable __autoreleasing * _Nullable)error;

- (BOOL)isKnown;

- (BOOL)supportsBrokeredAuthentication;

// Only certain authorities support passing clientID as an allowed scope
- (BOOL)supportsClientIDAsScope;

// Only certain authorities support MAM CA scenarios
- (BOOL)supportsMAMScenarios;

// Check if token endpoint is consistent with the authoirty
// E.g., currently AAD Authority checks if the host is the same, which requires resolving authority beforehand
- (BOOL)checkTokenEndpointForRTRefresh:(nullable NSURL *)tokenEndpoint;

/* It is used in telemetry */
- (nonnull NSString *)telemetryAuthorityType;

- (void)loadOpenIdMetadataWithContext:(nullable id<MSIDRequestContext>)context
                      completionBlock:(nonnull MSIDOpenIdConfigurationInfoBlock)completionBlock;

- (BOOL)isSameEnvironmentAsAuthority:(nonnull MSIDAuthority *)authority;

+ (BOOL)isAuthorityFormatValid:(nonnull NSURL *)url
                       context:(nullable id<MSIDRequestContext>)context
                         error:(NSError * _Nullable __autoreleasing * _Nullable)error;

@end
