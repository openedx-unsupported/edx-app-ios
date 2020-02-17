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

#import "MSIDIntuneMAMResourcesCache.h"
#import "MSIDAuthority.h"
#import "MSIDIntuneInMemoryCacheDataSource.h"

#define MSID_INTUNE_RESOURCE_ID @"intune_mam_resource_V"
#define MSID_INTUNE_RESOURCE_ID_VERSION @"1"
#define MSID_INTUNE_RESOURCE_ID_KEY (MSID_INTUNE_RESOURCE_ID MSID_INTUNE_RESOURCE_ID_VERSION)

static MSIDIntuneMAMResourcesCache *s_sharedCache;

@interface MSIDIntuneMAMResourcesCache()

@property (nonatomic) id<MSIDIntuneCacheDataSource> dataSource;

@end

@implementation MSIDIntuneMAMResourcesCache

- (instancetype)initWithDataSource:(id<MSIDIntuneCacheDataSource>)dataSource
{
    self = [super init];
    if (self)
    {
        _dataSource = dataSource;
    }
    return self;
}

+ (void)setSharedCache:(MSIDIntuneMAMResourcesCache *)cache
{
    @synchronized(self)
    {
        if (cache == nil) return;
        
        s_sharedCache = cache;
    }
}

+ (MSIDIntuneMAMResourcesCache *)sharedCache
{
    @synchronized(self)
    {
        if (!s_sharedCache)
        {
            s_sharedCache = [[MSIDIntuneMAMResourcesCache alloc] initWithDataSource:[MSIDIntuneInMemoryCacheDataSource new]];
        }
        
        return s_sharedCache;
    }
}

- (NSString *)resourceForAuthority:(MSIDAuthority *)authority
                           context:(id<MSIDRequestContext>)context
                             error:(NSError **)error
{
    NSDictionary *jsonDictionary = [self.dataSource jsonDictionaryForKey:MSID_INTUNE_RESOURCE_ID_KEY];
    if (!jsonDictionary)
    {
        MSID_LOG_WITH_CTX(MSIDLogLevelVerbose,context, @"No Intune Resource JSON found.");
        return nil;
    }
    
    if (![self isValid:jsonDictionary context:context error:error]) return nil;
    
    __auto_type aliases = [authority defaultCacheEnvironmentAliases];
    for (NSString *environment in aliases)
    {
         NSString *resource = [jsonDictionary objectForKey:environment];
        
        if (resource) return resource;
    }
    
    return nil;
}

- (BOOL)setResourcesJsonDictionary:(NSDictionary *)jsonDictionary
                           context:(id<MSIDRequestContext>)context
                             error:(NSError **)error
{
    if (![self isValid:jsonDictionary context:context error:error]) return NO;
    
    [self.dataSource setJsonDictionary:jsonDictionary forKey:MSID_INTUNE_RESOURCE_ID_KEY];
    return YES;
}

- (NSDictionary *)resourcesJsonDictionaryWithContext:(id<MSIDRequestContext>)context
                                               error:(NSError **)error
{
    __auto_type jsonDictionary = [self.dataSource jsonDictionaryForKey:MSID_INTUNE_RESOURCE_ID_KEY];
    if (![self isValid:jsonDictionary context:context error:error]) return nil;
    
    return jsonDictionary;
}

- (void)clear
{
    [self.dataSource removeObjectForKey:MSID_INTUNE_RESOURCE_ID_KEY];
}

#pragma mark - Private

- (BOOL)isValid:(NSDictionary *)json
        context:(id<MSIDRequestContext>)context
          error:(NSError **)error
{
    NSString *errorDescription = @"Intune Resource JSON structure is incorrect.";
    __auto_type validationError = MSIDCreateError(MSIDErrorDomain, MSIDErrorInternal, errorDescription, nil, nil, nil, context.correlationId, nil, NO);
    
    if (!json)
    {
        MSID_LOG_WITH_CTX(MSIDLogLevelVerbose,context, @"Intune Resource JSON is nil.");
        return YES;
    }
    
    if (![json isKindOfClass:NSDictionary.class])
    {
        if (error) *error = validationError;
        MSID_LOG_WITH_CTX(MSIDLogLevelError, context, @"Intune Resource JSON structure is incorrect (json not a dictionary).");
        
        return NO;
    }
    
    for (id key in [json allKeys])
    {
        if (![key isKindOfClass:NSString.class])
        {
            if (error) *error = validationError;
            MSID_LOG_WITH_CTX(MSIDLogLevelError, context, @"Intune Resource JSON structure is incorrect (json keys are not strings).");
            
            return NO;
        }
    }
    
    for (id value in [json allValues])
    {
        if (![value isKindOfClass:NSString.class])
        {
            if (error) *error = validationError;
            MSID_LOG_WITH_CTX(MSIDLogLevelError, context, @"Intune Resource JSON structure is incorrect (json values are not strings).");
            
            return NO;
        }
    }
    
    return YES;
}

@end
