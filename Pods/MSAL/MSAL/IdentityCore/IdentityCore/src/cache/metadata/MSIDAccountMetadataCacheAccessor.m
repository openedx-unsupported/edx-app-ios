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

#import "MSIDAccountMetadataCacheAccessor.h"
#import "MSIDConfiguration.h"
#import "MSIDRequestParameters.h"
#import "MSIDMetadataCache.h"
#import "MSIDAccountMetadataCacheKey.h"
#import "MSIDAccountMetadata.h"
#import "MSIDAccountMetadataCacheItem.h"

@implementation MSIDAccountMetadataCacheAccessor
{
    MSIDMetadataCache *_metadataCache;
}

- (instancetype)initWithDataSource:(id<MSIDMetadataCacheDataSource>)dataSource
{
    if (!dataSource) return nil;
    
    self = [super init];
    
    if (self)
    {
        _metadataCache = [[MSIDMetadataCache alloc] initWithPersistentDataSource:dataSource];
    }
    
    return self;
}

- (NSURL *)getAuthorityURL:(NSURL *)requestAuthorityURL
             homeAccountId:(NSString *)homeAccountId
                  clientId:(NSString *)clientId
             instanceAware:(BOOL)instanceAware
                   context:(id<MSIDRequestContext>)context
                     error:(NSError **)error
{
    if (!requestAuthorityURL
        || [NSString msidIsStringNilOrBlank:homeAccountId]
        || [NSString msidIsStringNilOrBlank:clientId])
    {
        if (error) *error = MSIDCreateError(MSIDErrorDomain, MSIDErrorInvalidInternalParameter, @"One or more of input field is nil - request requestAuthorityURL, homeAccountId, or clientID", nil, nil, nil, nil, nil, YES);
        return nil;
    }
    
    MSIDAccountMetadataCacheKey *key = [[MSIDAccountMetadataCacheKey alloc] initWithClientId:clientId];
    MSIDAccountMetadataCacheItem *cacheItem = [_metadataCache accountMetadataCacheItemWithKey:key context:context error:error];
    MSIDAccountMetadata *accountMetadata =  [cacheItem accountMetadataForHomeAccountId:homeAccountId];
    
    if (!accountMetadata) return nil;
    
    return [accountMetadata cachedURL:requestAuthorityURL instanceAware:instanceAware];
}

- (BOOL)updateAuthorityURL:(NSURL *)cacheAuthorityURL
             forRequestURL:(NSURL *)requestAuthorityURL
             homeAccountId:(NSString *)homeAccountId
                  clientId:(NSString *)clientId
             instanceAware:(BOOL)instanceAware
                   context:(id<MSIDRequestContext>)context
                     error:(NSError **)error
{
    if (!cacheAuthorityURL || !requestAuthorityURL || !homeAccountId || !clientId)
    {
        if (error) *error = MSIDCreateError(MSIDErrorDomain, MSIDErrorInvalidInternalParameter, @"Parameters cannot be nil for updating account metadata authority map!", nil, nil, nil, nil, nil, YES);
        return NO;
    }
        
    //No need to update if the request authority is the same as the authority used internally
    if (!cacheAuthorityURL
        || [cacheAuthorityURL isEqual:requestAuthorityURL]) return YES;
    
    NSError *localError;
    MSIDAccountMetadataCacheKey *key = [[MSIDAccountMetadataCacheKey alloc] initWithClientId:clientId];
    MSIDAccountMetadataCacheItem *cacheItem = [_metadataCache accountMetadataCacheItemWithKey:key context:context error:&localError];
    if (localError)
    {
        if (error) *error = localError;
        return NO;
    }
    
    if (!cacheItem)
    {
        cacheItem = [[MSIDAccountMetadataCacheItem alloc] initWithClientId:clientId];
    }
    
    MSIDAccountMetadata *accountMetadata = [cacheItem accountMetadataForHomeAccountId:homeAccountId];
    if (accountMetadata)
    {
        // No need to update if same record exists
        if ([[accountMetadata cachedURL:requestAuthorityURL instanceAware:instanceAware] isEqual:cacheAuthorityURL] &&
            accountMetadata.signInState == MSIDAccountMetadataStateSignedIn)
        {
            return YES;
        }
    }
    else
    {
        accountMetadata = [[MSIDAccountMetadata alloc] initWithHomeAccountId:homeAccountId clientId:clientId];
    }
    
    if (![accountMetadata setCachedURL:cacheAuthorityURL forRequestURL:requestAuthorityURL instanceAware:instanceAware error:error])
    {
        return NO;
    }
    
    if (![cacheItem addAccountMetadata:accountMetadata forHomeAccountId:homeAccountId error:error])
    {
        return NO;
    }
    
    return [_metadataCache saveAccountMetadataCacheItem:cacheItem
                                                    key:key
                                                context:context error:error];
}

- (MSIDAccountMetadataState)signInStateForHomeAccountId:(NSString *)homeAccountId
                                               clientId:(NSString *)clientId
                                                context:(id<MSIDRequestContext>)context
                                                  error:(NSError **)error
{
    if ([NSString msidIsStringNilOrBlank:homeAccountId]
        || [NSString msidIsStringNilOrBlank:clientId])
    {
        if (error) *error = MSIDCreateError(MSIDErrorDomain, MSIDErrorInvalidInternalParameter, @"Both homeAccountId and clientId are needed to query signed out state!", nil, nil, nil, nil, nil, YES);
        return MSIDAccountMetadataStateUnknown;
    }
    
    NSError *localError;
    MSIDAccountMetadataCacheItem *cacheItem = [self retrieveAccountMetadataCacheItemForClientId:clientId skipCache:YES context:context error:&localError];
    if (localError)
    {
        if (error) *error = localError;
        return MSIDAccountMetadataStateUnknown;
    }
                                               
    MSIDAccountMetadata *accountMetadata = [cacheItem accountMetadataForHomeAccountId:homeAccountId];
    if (!accountMetadata) return MSIDAccountMetadataStateUnknown;
    
    return accountMetadata.signInState;
}

- (BOOL)updateSignInStateForHomeAccountId:(NSString *)homeAccountId
                                 clientId:(NSString *)clientId
                                    state:(MSIDAccountMetadataState)state
                                  context:(id<MSIDRequestContext>)context
                                    error:(NSError **)error
{
    if ([NSString msidIsStringNilOrBlank:homeAccountId])
    {
        if (error) *error = MSIDCreateError(MSIDErrorDomain, MSIDErrorInvalidInternalParameter, @"HomeAccountId is needed to mark signed out state!", nil, nil, nil, nil, nil, YES);
        return NO;
    }
    
    NSError *localError;
    MSIDAccountMetadataCacheItem *cacheItem = [self retrieveAccountMetadataCacheItemForClientId:clientId skipCache:YES context:context error:&localError];
    if (localError)
    {
        if (error) *error = localError;
        return NO;
    }
    
    if (!cacheItem)
    {
        cacheItem = [[MSIDAccountMetadataCacheItem alloc] initWithClientId:clientId];
    }
    
    // Need to read existing account metetada if not setting as signed out
    MSIDAccountMetadata *accountMetadata;
    if (state != MSIDAccountMetadataStateSignedOut)
    {
        accountMetadata = [cacheItem accountMetadataForHomeAccountId:homeAccountId];
    }
    
    if (!accountMetadata)
    {
        accountMetadata = [[MSIDAccountMetadata alloc] initWithHomeAccountId:homeAccountId clientId:clientId];
    }
    
    [accountMetadata updateSignInState:state];
    
    if (![cacheItem addAccountMetadata:accountMetadata forHomeAccountId:homeAccountId error:error])
    {
        return NO;
    }
    
    MSIDAccountMetadataCacheKey *key = [[MSIDAccountMetadataCacheKey alloc] initWithClientId:clientId];
    
    return [_metadataCache saveAccountMetadataCacheItem:cacheItem
                                                    key:key
                                                context:context error:error];
}

- (MSIDAccountIdentifier *)principalAccountIdForClientId:(NSString *)clientId
                                                 context:(id<MSIDRequestContext>)context
                                                   error:(NSError **)error
{
    MSIDAccountMetadataCacheItem *cacheItem = [self retrieveAccountMetadataCacheItemForClientId:clientId skipCache:self.skipMemoryCacheForAccountMetadata context:context error:error];
    
    if (!cacheItem)
    {
        return nil;
    }
    
    return cacheItem.principalAccountId;
}

- (BOOL)updatePrincipalAccountIdForClientId:(NSString *)clientId
                         principalAccountId:(MSIDAccountIdentifier *)principalAccountId
                principalAccountEnvironment:(NSString *)principalAccountEnvironment
                                    context:(id<MSIDRequestContext>)context
                                      error:(NSError **)error
{
    NSError *accountMetadataError;
    MSIDAccountMetadataCacheItem *cacheItem = [self retrieveAccountMetadataCacheItemForClientId:clientId skipCache:self.skipMemoryCacheForAccountMetadata context:context error:&accountMetadataError];
    
    if (accountMetadataError)
    {
        if (error) *error = accountMetadataError;
        return NO;
    }
    
    if (!cacheItem)
    {
        cacheItem = [[MSIDAccountMetadataCacheItem alloc] initWithClientId:clientId];
    }
    
    cacheItem.principalAccountId = principalAccountId;
    cacheItem.principalAccountEnvironment = principalAccountEnvironment;
    
    MSIDAccountMetadataCacheKey *key = [[MSIDAccountMetadataCacheKey alloc] initWithClientId:clientId];
    
    return [_metadataCache saveAccountMetadataCacheItem:cacheItem
                                                    key:key
                                                context:context error:error];
}

- (MSIDAccountMetadataCacheItem *)retrieveAccountMetadataCacheItemForClientId:(NSString *)clientId
                                                                      context:(id<MSIDRequestContext>)context
                                                                        error:(NSError **)error
{
    return [self retrieveAccountMetadataCacheItemForClientId:clientId
                                                   skipCache:NO
                                                     context:context
                                                       error:error];
}

#pragma mark - Internal

- (MSIDAccountMetadataCacheItem *)retrieveAccountMetadataCacheItemForClientId:(NSString *)clientId
                                                                    skipCache:(BOOL)skipCache
                                                                      context:(id<MSIDRequestContext>)context
                                                                        error:(NSError **)error
{
    if ([NSString msidIsStringNilOrBlank:clientId])
    {
        if (error) *error = MSIDCreateError(MSIDErrorDomain, MSIDErrorInvalidInternalParameter, @"ClientId is required to query account metadata cache!", nil, nil, nil, nil, nil, YES);
        return nil;
    }
    
    NSError *localError;
    MSIDAccountMetadataCacheKey *key = [[MSIDAccountMetadataCacheKey alloc] initWithClientId:clientId];
    MSIDAccountMetadataCacheItem *cacheItem = [_metadataCache accountMetadataCacheItemWithKey:key skipCache:skipCache context:context error:&localError];
    if (localError && error) *error = localError;
    
    return cacheItem;
}

#pragma mark - Broker Utility

// Remove account metadata for all clients based on home account id
- (BOOL)removeAccountMetadataForHomeAccountId:(NSString *)homeAccountId
                                      context:(id<MSIDRequestContext>)context
                                        error:(NSError **)error
{
    if ([NSString msidIsStringNilOrBlank:homeAccountId])
    {
        if (error) *error = MSIDCreateError(MSIDErrorDomain, MSIDErrorInvalidInternalParameter, @"HomeAccountId is needed to remove account metadata!", nil, nil, nil, context.correlationId, nil, YES);
        return NO;
    }
    
    MSID_LOG_WITH_CTX_PII(MSIDLogLevelVerbose, context, @"Remove account metadata for home account id: %@.", MSID_PII_LOG_TRACKABLE(homeAccountId));
    
    NSError *localError;
    NSArray<MSIDAccountMetadataCacheItem *> *cacheItems = [self allAccountMetadataCacheItemsWithContext:context error:&localError];
    if (localError)
    {
        if (error) *error = localError;
        return NO;
    }
    
    BOOL success = YES;
    
    for (MSIDAccountMetadataCacheItem *cacheItem in cacheItems)
    {
        localError = nil;
        [cacheItem removeAccountMetadataForHomeAccountId:homeAccountId error:&localError];
        if (localError)
        {
            success = NO;
            if (error) *error = localError;
            MSID_LOG_WITH_CTX(MSIDLogLevelError, context, @"Failed to remove account metadata from cache item!");
            
            continue;
        }
        
        localError = nil;
        MSIDAccountMetadataCacheKey *key = [[MSIDAccountMetadataCacheKey alloc] initWithClientId:cacheItem.clientId];
        [_metadataCache saveAccountMetadataCacheItem:cacheItem
                                                 key:key
                                             context:context error:&localError];
        
        if (localError)
        {
            success = NO;
            if (error) *error = localError;
            MSID_LOG_WITH_CTX(MSIDLogLevelError, context, @"Failed to save cache item after removing account metadata!");
            
            continue;
        }
    }
    
    return success;
}

- (NSArray<MSIDAccountMetadataCacheItem *> *)allAccountMetadataCacheItemsWithContext:(id<MSIDRequestContext>)context
                                                                               error:(NSError **)error
{
    return [_metadataCache allAccountMetadataCacheItemsWithContext:context error:error];
}

@end
