//
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
#import "MSIDThrottlingMetaDataCache.h"
#import "MSIDCacheKey.h"
#import "MSIDRequestContext.h"
#import "MSIDThrottlingMetaData.h"
#import "MSIDConstants.h"
#import "MSIDCacheItemJsonSerializer.h"
#import "MSIDKeychainTokenCache.h"
#import "NSDate+MSIDExtensions.h"

@implementation MSIDThrottlingMetaDataCache

/**
 Get last refresh time from our key chain.
 */
+ (NSDate *)getLastRefreshTimeWithDatasource:(id<MSIDExtendedTokenCacheDataSource>)datasource
                                     context:(id<MSIDRequestContext>)context
                                       error:(NSError **)error
{
    MSIDThrottlingMetaData *metadata = [MSIDThrottlingMetaDataCache getThrottlingMetadataWithDatasource:datasource context:context error:error];
    NSString *stringDate = metadata.lastRefreshTime;
    return [NSDate msidDateFromTimeStamp:stringDate];
}

+ (BOOL)updateLastRefreshTimeWithDatasource:(id<MSIDExtendedTokenCacheDataSource>)datasource
                                    context:(id<MSIDRequestContext>)context
                                      error:(NSError*__nullable*__nullable)error
{
    MSIDThrottlingMetaData *metadata = [[MSIDThrottlingMetaData alloc] init];
    metadata.lastRefreshTime = [[NSDate new] msidDateToTimestamp];
    if (!datasource)
    {
        return NO;
    }
    return [datasource saveJsonObject:metadata
                           serializer:[MSIDCacheItemJsonSerializer new]
                                  key:[MSIDThrottlingMetaDataCache throttlingMetadataCacheKey]
                              context:context
                                error:error];
}

+ (MSIDThrottlingMetaData *)getThrottlingMetadataWithDatasource:(id<MSIDExtendedTokenCacheDataSource>)datasource
                                                        context:(id<MSIDRequestContext>)context
                                                          error:(NSError*__nullable*__nullable)error
{
    MSIDThrottlingMetaData *result = nil;
    if (!datasource) return nil;
    NSArray *jsonObjects = [datasource jsonObjectsWithKey:[MSIDThrottlingMetaDataCache throttlingMetadataCacheKey]
                                               serializer:[MSIDCacheItemJsonSerializer new]
                                                  context:context
                                                    error:error];
    if (![jsonObjects count])
    {
        return nil;
    }
    result = [[MSIDThrottlingMetaData alloc] initWithJSONDictionary:[jsonObjects[0] jsonDictionary] error:error];
    return result;
}

+ (MSIDCacheKey *)throttlingMetadataCacheKey
{
    static MSIDCacheKey *cacheKey = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        cacheKey = [[MSIDCacheKey alloc] initWithAccount:MSID_THROTTLING_METADATA_KEYCHAIN
                                                 service:MSID_THROTTLING_METADATA_KEYCHAIN_VERSION
                                                 generic:nil
                                                    type:nil];
    });
    return cacheKey;
}

@end
