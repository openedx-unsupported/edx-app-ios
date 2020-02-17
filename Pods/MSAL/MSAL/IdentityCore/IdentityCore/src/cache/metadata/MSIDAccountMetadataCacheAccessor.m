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
    
    MSIDAccountMetadataCacheKey *key = [[MSIDAccountMetadataCacheKey alloc] initWitHomeAccountId:homeAccountId clientId:clientId];
    MSIDAccountMetadataCacheItem *authorityMap = [_metadataCache accountMetadataWithKey:key context:context error:error];
    if (!authorityMap) { return nil; }
    
    return [authorityMap cachedURL:requestAuthorityURL instanceAware:instanceAware];
}

- (BOOL)updateAuthorityURL:(NSURL *)cacheAuthorityURL
             forRequestURL:(NSURL *)requestAuthorityURL
             homeAccountId:(NSString *)homeAccountId
                  clientId:(NSString *)clientId
             instanceAware:(BOOL)instanceAware
                   context:(id<MSIDRequestContext>)context
                     error:(NSError **)error
{
    //No need to update if the request authority is the same as the authority used internally
    if (!cacheAuthorityURL
        || [cacheAuthorityURL isEqual:requestAuthorityURL]) return YES;
    
    MSIDAccountMetadataCacheKey *key = [[MSIDAccountMetadataCacheKey alloc] initWitHomeAccountId:homeAccountId clientId:clientId];
    MSIDAccountMetadataCacheItem *accountMetadataItem = [_metadataCache accountMetadataWithKey:key context:context error:error];
    if (!accountMetadataItem)
    {
        accountMetadataItem = [[MSIDAccountMetadataCacheItem alloc] initWithHomeAccountId:homeAccountId clientId:clientId];
    }
    
    if (![accountMetadataItem setCachedURL:cacheAuthorityURL forRequestURL:requestAuthorityURL instanceAware:instanceAware error:error])
    {
        return NO;
    }
    
    return [_metadataCache saveAccountMetadata:accountMetadataItem
                                           key:key
                                       context:context error:error];
}

- (BOOL)clearForHomeAccountId:(NSString *)homeAccountId
                     clientId:(NSString *)clientId
                      context:(id<MSIDRequestContext>)context
                        error:(NSError **)error
{
    MSIDAccountMetadataCacheKey *key = [[MSIDAccountMetadataCacheKey alloc] initWitHomeAccountId:homeAccountId clientId:clientId];
    return [_metadataCache removeAccountMetadataForKey:key context:context error:error];
}

@end
