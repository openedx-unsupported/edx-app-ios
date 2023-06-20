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

#if !EXCLUDE_FROM_MSALCPP_FOR_MACOS

#import "MSIDMacTokenCache.h"
#import "MSIDLegacyTokenCacheItem.h"
#import "MSIDLegacyTokenCacheKey.h"
#import "MSIDCacheItemSerializing.h"
#import "MSIDAccountCacheItem.h"
#import "MSIDUserInformation.h"
#import "NSKeyedArchiver+MSIDExtensions.h"
#import "NSKeyedUnarchiver+MSIDExtensions.h"

#define CURRENT_WRAPPER_CACHE_VERSION 1.0

#define RETURN_ERROR_IF_CONDITION_FALSE(_cond, _code, _details) { \
if (!(_cond)) { \
NSError* _MSID_ERROR = MSIDCreateError(MSIDErrorDomain, _code, _details, nil, nil, nil, nil, nil, NO); \
if (error) { *error = _MSID_ERROR; } \
return NO; \
} \
}

@interface MSIDMacTokenCache ()

@property (nonatomic) NSMutableDictionary *cache;
@property (nonatomic) dispatch_queue_t synchronizationQueue;

@end

@implementation MSIDMacTokenCache

- (instancetype)init
{
    if (!(self = [super init]))
    {
        return nil;
    }
    
    NSString *queueName = [NSString stringWithFormat:@"com.microsoft.msidmactokencache-%@", [NSUUID UUID].UUIDString];
    _synchronizationQueue = dispatch_queue_create([queueName cStringUsingEncoding:NSASCIIStringEncoding], DISPATCH_QUEUE_CONCURRENT);
    [self initializeCacheIfNecessary];

    return self;
}

+ (MSIDMacTokenCache *)defaultCache
{
    static dispatch_once_t once;
    static MSIDMacTokenCache *cache = nil;
    
    dispatch_once(&once, ^{
        cache = [MSIDMacTokenCache new];
    });
    
    return cache;
}

- (nullable NSData *)serialize
{
    if (!self.cache)
    {
        return nil;
    }

    __block NSData *result = nil;
    dispatch_barrier_sync(self.synchronizationQueue, ^{
        // Using the dictionary @{ key : value } syntax here causes _cache to leak. Yay legacy runtime!
        NSDictionary *wrapper = [NSDictionary dictionaryWithObjectsAndKeys:self.cache, @"tokenCache",@CURRENT_WRAPPER_CACHE_VERSION, @"version", nil];

        @try
        {
            result = [NSKeyedArchiver msidEncodeObject:wrapper usingBlock:^(NSKeyedArchiver *archiver)
            {
                // Maintain backward compatibility with ADAL.
                [archiver setClassName:@"ADTokenCacheKey" forClass:MSIDLegacyTokenCacheKey.class];
                [archiver setClassName:@"ADTokenCacheStoreItem" forClass:MSIDLegacyTokenCacheItem.class];
                [archiver setClassName:@"ADUserInformation" forClass:MSIDUserInformation.class];
            }];
        }
        @catch (id exception)
        {
            // This should be exceedingly rare as all of the objects in the cache we placed there.
            MSID_LOG_WITH_CTX(MSIDLogLevelError, nil, @"Failed to serialize the cache!");
        }
    });
    
    return result;
}

- (BOOL)deserialize:(nullable NSData*)data
              error:(NSError **)error
{
    NSDictionary *cache = nil;
    
    @try
    {
        NSKeyedUnarchiver *unarchiver = [NSKeyedUnarchiver msidCreateForReadingFromData:data error:error];
        
        // Maintain backward compatibility with ADAL.
        [unarchiver setClass:MSIDLegacyTokenCacheKey.class forClassName:@"ADTokenCacheKey"];
        [unarchiver setClass:MSIDLegacyTokenCacheItem.class forClassName:@"ADTokenCacheStoreItem"];
        [unarchiver setClass:MSIDUserInformation.class forClassName:@"ADUserInformation"];
        __auto_type allowedClasses = [NSSet setWithObjects:NSDictionary.class, NSNumber.class, NSString.class, MSIDLegacyTokenCacheKey.class, MSIDLegacyTokenCacheItem.class, MSIDUserInformation.class, nil];
        cache = [unarchiver decodeObjectOfClasses:allowedClasses forKey:NSKeyedArchiveRootObjectKey];
        [unarchiver finishDecoding];
    }
    @catch (id exception)
    {
        if (error)
        {
            *error = MSIDCreateError(MSIDErrorDomain, MSIDErrorCacheBadFormat, @"Failed to unarchive data blob from -deserialize!", nil, nil, nil, nil, nil, YES);
        }
    }
    
    if (!cache)
    {
        return NO;
    }
    
    if (![self validateCache:cache error:error])
    {
        return NO;
    }
    
    __block BOOL result = NO;
    dispatch_barrier_sync(self.synchronizationQueue, ^{
        self.cache = [cache objectForKey:@"tokenCache"];
        result = YES;
    });
    
    return result;
}

- (void)initializeCacheIfNecessary
{
    if (!_cache)
    {
        _cache = [NSMutableDictionary new];
    }

    if (!_cache[@"tokens"])
    {
        NSMutableDictionary *tokens = [NSMutableDictionary new];
        _cache[@"tokens"] = tokens;
    }
}

- (void)clear
{
    dispatch_barrier_sync(self.synchronizationQueue, ^{
        self.cache = nil;
        [self initializeCacheIfNecessary];
    });
}

#pragma mark - Tokens

- (BOOL)saveToken:(MSIDCredentialCacheItem *)item
              key:(MSIDCacheKey *)key
       serializer:(id<MSIDCacheItemSerializing>)serializer
          context:(id<MSIDRequestContext>)context
            error:(NSError * __autoreleasing *)error
{
    __typeof__(self.delegate) strongDelegate = self.delegate;
    
    [strongDelegate willWriteCache:self];
    BOOL result = NO;
    result = [self setItemImpl:item key:key serializer:serializer context:context error:error];
    [strongDelegate didWriteCache:self];
    
    return result;
}

- (MSIDCredentialCacheItem *)tokenWithKey:(MSIDCacheKey *)key
                               serializer:(id<MSIDCacheItemSerializing>)serializer
                                  context:(id<MSIDRequestContext>)context
                                    error:(NSError *__autoreleasing *)error
{
    MSID_LOG_WITH_CTX(MSIDLogLevelInfo, context, @"itemWithKey:serializer:context:error:");
    NSArray<MSIDCredentialCacheItem *> *items = [self tokensWithKey:key serializer:serializer context:context error:error];
    
    if (items.count > 1)
    {
        if (error)
        {
            *error = MSIDCreateError(MSIDErrorDomain, MSIDErrorCacheMultipleUsers, @"The token cache store for this resource contains more than one user.", nil, nil, nil, context.correlationId, nil, YES);
        }
        
        return nil;
    }
    
    return items.firstObject;
}

- (NSArray<MSIDCredentialCacheItem *> *)tokensWithKey:(MSIDCacheKey *)key
                                           serializer:(id<MSIDCacheItemSerializing>)serializer
                                              context:(__unused id<MSIDRequestContext>)context
                                                error:(NSError * __autoreleasing *)error
{
    __typeof__(self.delegate) strongDelegate = self.delegate;
    
    [strongDelegate willAccessCache:self];
    NSArray *result = nil;
    result = [self itemsWithKeyImpl:key serializer:serializer context:nil error:error];
    [strongDelegate didAccessCache:self];
    
    return result;
}

#pragma mark - Removal

- (BOOL)removeTokensWithKey:(MSIDCacheKey *)key
                    context:(id<MSIDRequestContext>)context
                      error:(NSError **)error
{
    return [self removeItemsWithKey:key context:context error:error];
}


- (BOOL)removeAccountMetadataForKey:(MSIDCacheKey *)key
                            context:(id<MSIDRequestContext>)context
                              error:(NSError *__autoreleasing *)error
{
    return [self removeItemsWithKey:key context:context error:error];
}

- (BOOL)removeItemsWithKey:(MSIDCacheKey *)key
                   context:(id<MSIDRequestContext>)context
                     error:(NSError * __autoreleasing *)error
{
    __typeof__(self.delegate) strongDelegate = self.delegate;
    
    [strongDelegate willWriteCache:self];
    __block BOOL result = NO;
    dispatch_barrier_sync(self.synchronizationQueue, ^{
        result = [self removeItemsWithKeyImpl:key context:context error:error];
    });
    [strongDelegate didWriteCache:self];
    
    return result;
}

#pragma mark - Wipe

- (BOOL)saveWipeInfoWithContext:(__unused id<MSIDRequestContext>)context
                          error:(__unused NSError **)error
{
    return NO;
}

- (NSDictionary *)wipeInfo:(__unused id<MSIDRequestContext>)context
                     error:(__unused NSError **)error
{
    return nil;
}

#pragma mark - Private

- (void)addToItems:(nonnull NSMutableArray *)items
    fromDictionary:(nonnull NSDictionary *)dictionary
               key:(nonnull MSIDCacheKey *)key
{
    MSIDCredentialCacheItem *item = [dictionary objectForKey:[self legacyKeyWithoutAccount:key]];
    if (item)
    {
        item = [item copy];

        // Skip tombstones generated from previous versions of ADAL.
        if ([item isTombstone])
        {
            return;
        }

        [items addObject:item];
    }
}

- (void)addToItems:(nonnull NSMutableArray *)items
         forUserId:(nonnull NSString *)userId
            tokens:(nonnull NSDictionary *)tokens
               key:(MSIDCacheKey *)key
{
    NSDictionary *userTokens = [tokens objectForKey:userId];
    if (!userTokens)
    {
        return;
    }
    
    // Add items matching the key for this user
    if (key.service)
    {
        [self addToItems:items fromDictionary:userTokens key:key];
    }
    else
    {
        for (id adkey in userTokens)
        {
            [self addToItems:items fromDictionary:userTokens key:adkey];
        }
    }
}

- (BOOL)validateCache:(NSDictionary *)dict
                error:(NSError **)error
{
    RETURN_ERROR_IF_CONDITION_FALSE([dict isKindOfClass:[NSDictionary class]], MSIDErrorCacheBadFormat, @"Root level object of cache is not a NSDictionary.");
    RETURN_ERROR_IF_CONDITION_FALSE(dict[@"version"], MSIDErrorCacheBadFormat, @"Missing version number from cache.");
    RETURN_ERROR_IF_CONDITION_FALSE([dict[@"version"] floatValue] <= CURRENT_WRAPPER_CACHE_VERSION, MSIDErrorCacheBadFormat, @"Cache is a future unsupported version.");
    
    NSDictionary *cache = dict[@"tokenCache"];
    RETURN_ERROR_IF_CONDITION_FALSE(cache, MSIDErrorCacheBadFormat, @"Missing token cache from data.");
    RETURN_ERROR_IF_CONDITION_FALSE([cache isKindOfClass:[NSMutableDictionary class]], MSIDErrorCacheBadFormat, @"Cache is not a mutable dictionary.");
    
    NSDictionary *tokens = cache[@"tokens"];
    
    if (tokens)
    {
        RETURN_ERROR_IF_CONDITION_FALSE([tokens isKindOfClass:[NSMutableDictionary class]], MSIDErrorCacheBadFormat, @"Tokens must be a mutable dictionary.");
        for (id userId in tokens)
        {
            // On the second level we're expecting NSDictionaries keyed off of the user ids (an NSString*)
            RETURN_ERROR_IF_CONDITION_FALSE([userId isKindOfClass:[NSString class]], MSIDErrorCacheBadFormat, @"User ID key is not of the expected class type.");
            id userDict = [tokens objectForKey:userId];
            RETURN_ERROR_IF_CONDITION_FALSE([userDict isKindOfClass:[NSMutableDictionary class]], MSIDErrorCacheBadFormat, @"User ID should have mutable dictionaries in the cache.");
            
            for (id key in userDict)
            {
                // On the first level we're expecting NSDictionaries keyed off of ADTokenCacheStoreKey
                RETURN_ERROR_IF_CONDITION_FALSE([key isKindOfClass:[MSIDCacheKey class]], MSIDErrorCacheBadFormat, @"Key is not of the expected class type.");
                id token = [userDict objectForKey:key];
                RETURN_ERROR_IF_CONDITION_FALSE([token isKindOfClass:[MSIDCredentialCacheItem class]], MSIDErrorCacheBadFormat, @"Token is not of the expected class type.");
            }
        }
    }
    
    return YES;
}

- (BOOL)removeItemsWithKeyImpl:(MSIDCacheKey *)key
                       context:(id<MSIDRequestContext>)context
                         error:(NSError **)error
{
    if (!key)
    {
        if (error)
        {
            *error = MSIDCreateError(MSIDErrorDomain, MSIDErrorInvalidDeveloperParameter, @"Key is nil.", nil, nil, nil, context.correlationId, nil, YES);
        }
        
        return NO;
    }
    
    NSString *userId = key.account;
    if (!userId)
    {
        userId = @"";
    }
    
    NSMutableDictionary *userTokens = [self.cache[@"tokens"] objectForKey:userId];
    if (!userTokens)
    {
        return YES;
    }

    if (!key.service)
    {
        [self.cache[@"tokens"] removeObjectForKey:userId];
        return YES;
    }
    
    if (![userTokens objectForKey:[self legacyKeyWithoutAccount:key]])
    {
        return YES;
    }
    
    [userTokens removeObjectForKey:[self legacyKeyWithoutAccount:key]];
    
    // Check to see if we need to remove the overall dict
    if (!userTokens.count)
    {
        [self.cache[@"tokens"] removeObjectForKey:userId];
    }
    
    return YES;
}

- (BOOL)setItemImpl:(MSIDCredentialCacheItem *)item
                key:(MSIDCacheKey *)key
         serializer:(__unused id<MSIDCacheItemSerializing>)serializer
            context:(id<MSIDRequestContext>)context
              error:(NSError **)error
{
    assert(key);
    
    MSID_LOG_WITH_CTX_PII(MSIDLogLevelInfo, context, @"Set item, key info (account: %@ service: %@)", MSID_PII_LOG_MASKABLE(key.account), key.service);
    MSID_LOG_WITH_CTX_PII(MSIDLogLevelInfo, context, @"Item info %@", MSID_PII_LOG_MASKABLE(item));
    
    if (!key)
    {
        return NO;
    }
    
    if (!item)
    {
        if (error)
        {
            *error = MSIDCreateError(MSIDErrorDomain, MSIDErrorInvalidDeveloperParameter, @"Item is nil.", nil, nil, nil, context.correlationId, nil, YES);
        }
        MSID_LOG_WITH_CTX(MSIDLogLevelError, context, @"Set nil item.");
        
        return NO;
    }
    
    // Copy the item to make sure it doesn't change under us.
    item = [item copy];
    
    NSString *account = key.account;
    
    if (!account)
    {
        // If we don't have one (ADFS case) then use an empty string
        account = @"";
    }
    
    if (!key.service)
    {
        if (error)
        {
            *error = MSIDCreateError(MSIDErrorDomain, MSIDErrorInternal, @"Key is not valid. Make sure service is not nil.", nil, nil, nil, context.correlationId, nil, YES);
        }
        MSID_LOG_WITH_CTX(MSIDLogLevelError, context, @"Set keychain item with invalid key.");
        return NO;
    }
    
    dispatch_barrier_sync(self.synchronizationQueue, ^{

        [self initializeCacheIfNecessary];

        // Grab the token dictionary for this user id.
        NSMutableDictionary *userDict = self.cache[@"tokens"][account];
        if (!userDict)
        {
            userDict = [NSMutableDictionary new];
            self.cache[@"tokens"][account] = userDict;
        }
        
        userDict[[self legacyKeyWithoutAccount:key]] = item;
    });
    
    return YES;
}

- (NSArray<MSIDCredentialCacheItem *> *)itemsWithKeyImpl:(MSIDCacheKey *)key
                                         serializer:(__unused id<MSIDCacheItemSerializing>)serializer
                                            context:(id<MSIDRequestContext>)context
                                              error:(__unused NSError **)error
{
    MSID_LOG_WITH_CTX_PII(MSIDLogLevelInfo, context, @"Get items, key info (account: %@ service: %@)", MSID_PII_LOG_MASKABLE(key.account), key.service);

    if (!self.cache)
    {
        return nil;
    }
    
    __block NSDictionary *tokens;
    dispatch_barrier_sync(self.synchronizationQueue, ^{
        tokens = [[self.cache objectForKey:@"tokens"] mutableDeepCopy];
    });
    
    if (!tokens)
    {
        return nil;
    }
    
    NSMutableArray *items = [NSMutableArray new];
    
    if (key.account)
    {
        // If we have a specified userId then we only look for that one
        [self addToItems:items forUserId:key.account tokens:tokens key:key];
    }
    else
    {
        // Otherwise we have to traverse all of the users in the cache
        for (NSString* userId in tokens)
        {
            [self addToItems:items forUserId:userId tokens:tokens key:key];
        }
    }
    
    return items;
}

- (MSIDLegacyTokenCacheKey *)legacyKeyWithoutAccount:(MSIDCacheKey *)key
{
    // In order to be backward compatible with ADAL,
    // we need to store keys into dictionary without 'account'.
    MSIDLegacyTokenCacheKey *newKey = [[MSIDLegacyTokenCacheKey alloc] initWithAccount:nil
                                                                               service:key.service
                                                                               generic:key.generic
                                                                                  type:key.type];
    
    return newKey;
}

- (BOOL)clearWithContext:(id<MSIDRequestContext>)context
                   error:(__unused NSError **)error
{
    MSID_LOG_WITH_CTX(MSIDLogLevelWarning,context, @"Clearing the whole context. This should only be executed in tests");
    [self clear];
    return YES;
}

@end

#endif
