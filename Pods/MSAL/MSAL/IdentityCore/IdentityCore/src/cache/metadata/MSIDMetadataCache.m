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

#import "MSIDMetadataCache.h"
#import "MSIDCache.h"
#import "MSIDCacheItemJsonSerializer.h"
#import "MSIDJsonSerializer.h"
#import "MSIDJsonSerializing.h"
#import "MSIDCacheKey.h"
#import "MSIDAccountMetadataCacheItem.h"

@implementation MSIDMetadataCache
{
    NSMutableDictionary *_memoryCache;
    id<MSIDMetadataCacheDataSource> _dataSource;
    dispatch_queue_t _synchronizationQueue;
    MSIDCacheItemJsonSerializer *_jsonSerializer;
}

- (instancetype)initWithPersistentDataSource:(id<MSIDMetadataCacheDataSource>)dataSource
{
    if (!dataSource) return nil;
    
    self = [super init];
    
    if (self)
    {
        _memoryCache = [NSMutableDictionary new];
        _dataSource = dataSource;
        NSString *queueName = [NSString stringWithFormat:@"com.microsoft.msidmetadatacache-%@", [NSUUID UUID].UUIDString];
        _synchronizationQueue = dispatch_queue_create([queueName cStringUsingEncoding:NSASCIIStringEncoding], DISPATCH_QUEUE_CONCURRENT);
        _jsonSerializer = [MSIDCacheItemJsonSerializer new];
    }
    
    return self;
}

- (BOOL)saveAccountMetadata:(MSIDAccountMetadataCacheItem *)item
                        key:(MSIDCacheKey *)key
                    context:(id<MSIDRequestContext>)context
                      error:(NSError **)error
{
    if (!item || !key)
    {
        if (error)
        {
            *error = MSIDCreateError(MSIDErrorDomain,
                                     MSIDErrorInvalidInternalParameter,
                                     @"cacheItem and key could not be nil.",
                                     nil, nil, nil, nil, nil, YES);
        }
        return NO;
    }
    
    __block NSError *localError;
    __block BOOL saveSuccess = NO;
    __block BOOL hasChanges = YES;
    
    dispatch_sync(_synchronizationQueue, ^{
        hasChanges = ![item isEqual:_memoryCache[key]];
    });
    
    if (!hasChanges)
    {
        return YES;
    }
    
    dispatch_barrier_sync(_synchronizationQueue, ^{
        saveSuccess = [_dataSource saveAccountMetadata:item key:key serializer:_jsonSerializer context:context error:&localError];
        if (saveSuccess)
        {
            _memoryCache[key] = item;
        }
    });
    
    if (error && localError) *error = localError;
    return saveSuccess;
}

- (MSIDAccountMetadataCacheItem *)accountMetadataWithKey:(MSIDCacheKey *)key
                                                 context:(id<MSIDRequestContext>)context
                                                   error:(NSError **)error
{
    if (!key)
    {
        if (error)
        {
            *error = MSIDCreateError(MSIDErrorDomain, MSIDErrorInternal, @"Key is not valid.", nil, nil, nil, context.correlationId, nil, NO);
        }
        MSID_LOG_WITH_CTX(MSIDLogLevelError, context, @"Set keychain item with invalid key.");
        return nil;
    }

    __block MSIDAccountMetadataCacheItem *item;
    __block NSError *localError;
    __block BOOL updatedItem = NO;

    dispatch_sync(_synchronizationQueue, ^{
        item = _memoryCache[key];
        if (!item)
        {
            item = [_dataSource accountMetadataWithKey:key serializer:_jsonSerializer context:context error:&localError];
            updatedItem = item != nil;
        }
    });
    
    if (error && localError) *error = localError;
    
    if (!updatedItem)
    {
        // return a copy because we don't want external change on the cache status
        return [item copy];
    }
    
    dispatch_barrier_async(_synchronizationQueue, ^{
        _memoryCache[key] = item;
    });
    
    // return a copy because we don't want external change on the cache status
    return [item copy];
}

- (BOOL)removeAccountMetadataForKey:(MSIDCacheKey *)key
                            context:(id<MSIDRequestContext>)context
                              error:(NSError **)error
{
    if (!key)
    {
        if (error)
        {
            *error = MSIDCreateError(MSIDErrorDomain,
                                     MSIDErrorInvalidInternalParameter,
                                     @"cacheItem and key could not be nil.",
                                     nil, nil, nil, nil, nil, YES);
        }
        return NO;
    }
    
    __block BOOL success = NO;
    __block NSError *localError;
    
    dispatch_barrier_sync(_synchronizationQueue, ^{
        [_memoryCache removeObjectForKey:key];
        success = [_dataSource removeAccountMetadataForKey:key context:context error:&localError];
    });
    
    if (error && localError) *error = localError;
    return success;
}

@end
