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
#import "MSIDThrottlingService.h"
#import "NSDate+MSIDExtensions.h"
#import "NSError+MSIDExtensions.h"
#import "MSIDKeychainTokenCache.h"
#import "MSIDKeychainUtil.h"
#import "MSIDConstants.h"
#import "MSIDLRUCache.h"
#import "MSIDExtendedTokenCacheDataSource.h"
#import "MSIDCacheKey.h"
#import "MSIDThrottlingMetaData.h"
#import "MSIDThrottlingMetaDataCache.h"
#import "NSError+MSIDThrottlingExtension.h"
#import "MSIDThrottlingModelBase.h"
#import "MSIDThrottlingModelFactory.h"

@implementation MSIDThrottlingService

#pragma mark - Initializer

- (instancetype)initWithDataSource:(id<MSIDExtendedTokenCacheDataSource>)datasource
                           context:(id<MSIDRequestContext>)context
{
    self = [self init];
    if (self)
    {
        _context = context;
        _datasource = datasource;
    }
    return self;
}

#pragma mark - Public API

/**
  Base on the thumbprint value of the request, throttling service will query database to see if any existing record and return throttling decision to calling module.
 - NOT throttle case: return result
 - Shoud throttle case: return cached result + update server telemetry + update cache record
 */
- (void)shouldThrottleRequest:(id<MSIDThumbprintCalculatable>)request
                  resultBlock:(nonnull MSIDThrottleResultBlock)resultBlock
{
    MSIDThrottlingModelBase *throttleModel = [MSIDThrottlingModelFactory throttlingModelForIncomingRequest:request datasource:self.datasource context:self.context];
    
    if (!throttleModel)
    {
        MSID_LOG_WITH_CTX(MSIDLogLevelInfo, self.context, @"No record found in throttling database, return decision");
        resultBlock(NO,nil);
        return;
    }
    
    if ([throttleModel shouldThrottleRequest])
    {
        [throttleModel updateServerTelemetry];
        resultBlock(YES, throttleModel.cacheRecord.cachedErrorResponse);
    }
    else
    {
        // The record is expired, remove it from the db
        [throttleModel cleanCacheRecordFromDB];
        resultBlock(NO, nil);
    }
}

/**
 Whenever we receives a response from server, we want to check if any throttling error to update database. This is an public API of throttling service for that task.
 */
- (void)updateThrottlingService:(NSError *)error tokenRequest:(id<MSIDThumbprintCalculatable>)tokenRequest
{
    MSIDThrottlingModelBase *model = [MSIDThrottlingModelFactory throttlingModelForResponseWithRequest:tokenRequest
                                                                                           datasource:self.datasource
                                                                                         errorResponse:error
                                                                                               context:self.context];
    if (!model)
    {
        MSID_LOG_WITH_CTX(MSIDLogLevelInfo, self.context, @"Complete update flow with no update to throttling database");
        return;
    }
    MSIDThrottlingCacheRecord *cacheRecord = [model createDBCacheRecord];
    [model insertOrUpdateCacheRecordToDB:cacheRecord];
}

/**
 Update last refresh time when interactive flow is complete and success.
 */
+ (BOOL)updateLastRefreshTimeDatasource:(id<MSIDExtendedTokenCacheDataSource>)datasource
                                 context:(id<MSIDRequestContext>)context
                                   error:(NSError **)error
{
    if(![MSIDThrottlingService isThrottlingEnabled])
    {
        return YES;
    }
    return [MSIDThrottlingMetaDataCache updateLastRefreshTimeWithDatasource:datasource context:context error:error];
}

+ (BOOL)isThrottlingEnabled
{
#ifdef AD_THROTTLING_DISABLED
    #if AD_THROTTLING_DISABLED
        return NO;
    #else
        return YES;
    #endif
#endif
    return YES;
}

@end
