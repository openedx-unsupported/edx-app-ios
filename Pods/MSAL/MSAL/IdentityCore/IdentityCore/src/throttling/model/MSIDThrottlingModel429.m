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
#import "MSIDThrottlingModel429.h"
#import "NSError+MSIDThrottlingExtension.h"

@implementation MSIDThrottlingModel429
NSInteger const MSID_THROTTLING_DEFAULT_429 = 60;
NSInteger const MSID_THROTTLING_MAX_RETRY_AFTER = 3600;

- (instancetype)initWithRequest:(id<MSIDThumbprintCalculatable>)request
                    cacheRecord:(MSIDThrottlingCacheRecord *)cacheRecord
                  errorResponse:(NSError *)errorResponse
                    datasource:(id<MSIDExtendedTokenCacheDataSource> _Nonnull)datasource
{
    self = [super initWithRequest:request cacheRecord:cacheRecord errorResponse:errorResponse datasource:datasource];
    if (self)
    {
        self.thumbprintType = MSIDThrottlingThumbprintTypeStrict;
        self.thumbprintValue = [request strictRequestThumbprint];
        self.throttleDuration = MSID_THROTTLING_DEFAULT_429;
        
        NSString *logMessage = [NSString stringWithFormat:@"Throttling: [MSIDThrottlingModel429] strict request thumbprint generated from request with value: %@",self.thumbprintValue];
        MSID_LOG_WITH_CTX(MSIDLogLevelVerbose, nil, @"%@", logMessage);
        
    }
    return self;
}


/**
 429 throttle conditions:
 - HTTP Response code is 429 or in 5xx range
 - OR Retry-After in response header
 */
+ (BOOL)isApplicableForTheThrottleModel:(NSError *)errorResponse
{
    /**
     In SSO-Ext flow, it can be both MSAL or MSID Error. If it's MSALErrorDomain, we need to extract information we need (error code and user info)
     */
    MSID_LOG_WITH_CTX(MSIDLogLevelInfo, nil, @"Throttling: error response domain: %@", errorResponse.domain);

    BOOL res = NO;
    
    NSString *httpResponseCode = [errorResponse msidGetUserInfoValueWithMSIDKey:MSIDHTTPResponseCodeKey orMSALKey:@"MSALHTTPResponseCodeKey"];
    NSInteger responseCode = [httpResponseCode intValue];
    if (responseCode == 429) res = YES;
    if (responseCode >= 500 && responseCode <= 599) res = YES;
    NSDate *retryHeaderDate = [errorResponse msidGetRetryDateFromError];
    if (retryHeaderDate)
    {
        MSID_LOG_WITH_CTX(MSIDLogLevelInfo, nil, @"Throttling: retryHeaderDate value %@", retryHeaderDate);
        res = YES;
    }
    return res;
}

- (BOOL)shouldThrottleRequest
{
    MSID_LOG_WITH_CTX(MSIDLogLevelInfo, self.context, @"[Throttle shouldThrottleRequest], cached expiration time: %@", self.cacheRecord.expirationTime);

    BOOL res = YES;
    NSDate *currentTime = [NSDate new];
    if ([currentTime compare:self.cacheRecord.expirationTime] != NSOrderedAscending)
    {
        res = NO;
    }
    return res;
}

- (MSIDThrottlingCacheRecord *)createDBCacheRecord
{
    NSDate *retryHeaderDate = [self.errorResponse msidGetRetryDateFromError];
    MSID_LOG_WITH_CTX(MSIDLogLevelInfo, self.context, @"[Throttle prepareCacheRecord], retryHeaderDate: %@", retryHeaderDate);

    NSInteger throttleDuration = 0;
    if (!retryHeaderDate)
    {
        throttleDuration = MSID_THROTTLING_DEFAULT_429;
    }
    else
    {
        NSTimeInterval maxThrottlingTime = MSID_THROTTLING_MAX_RETRY_AFTER;
        NSDate *max429ThrottlingDate = [[NSDate date] dateByAddingTimeInterval:maxThrottlingTime];
        NSTimeInterval timeDiff = [retryHeaderDate timeIntervalSinceDate:max429ThrottlingDate];
        throttleDuration = (timeDiff > maxThrottlingTime) ? (NSInteger) maxThrottlingTime : (NSInteger) [retryHeaderDate timeIntervalSinceDate:[NSDate new]];

    }
    MSID_LOG_WITH_CTX(MSIDLogLevelInfo, self.context, @"[Throttle prepareCacheRecord], create 429 cache record with throttleDuration %ld", (long)throttleDuration);

    MSIDThrottlingCacheRecord *record = [[MSIDThrottlingCacheRecord alloc] initWithErrorResponse:self.errorResponse
                                                                                    throttleType:MSIDThrottlingType429
                                                                                throttleDuration:throttleDuration];
    return record;
}

- (void) updateServerTelemetry
{
    // TODO implement telemetry update here
    return ;
}

@end
