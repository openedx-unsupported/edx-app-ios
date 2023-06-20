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
#import "MSIDThrottlingModelNonRecoverableServerError.h"
#import "MSIDThrottlingMetaData.h"
#import "MSIDThrottlingMetaDataCache.h"
#import "NSDate+MSIDExtensions.h"
#import "NSError+MSIDExtensions.h"
static NSInteger const MSID_THROTTLING_DEFAULT_UI_REQUIRED = 120;

@implementation MSIDThrottlingModelNonRecoverableServerError

- (instancetype)initWithRequest:(id<MSIDThumbprintCalculatable>)request
                    cacheRecord:(MSIDThrottlingCacheRecord *)cacheRecord
                  errorResponse:(NSError *)errorResponse
                    datasource:(id<MSIDExtendedTokenCacheDataSource> _Nonnull)datasource
{
    self = [super initWithRequest:request cacheRecord:cacheRecord errorResponse:errorResponse datasource:datasource];
    if (self)
    {
        self.thumbprintType = MSIDThrottlingThumbprintTypeFull;
        self.thumbprintValue = [request fullRequestThumbprint];
        self.throttleDuration = MSID_THROTTLING_DEFAULT_UI_REQUIRED;
        
        NSString *logMessage = [NSString stringWithFormat:@"Throttling: [MSIDThrottlingModel429] strict request thumbprint generated from request with value: %@",self.thumbprintValue];
        MSID_LOG_WITH_CTX(MSIDLogLevelVerbose, nil, @"%@", logMessage);
    }
    return self;
}


/**
 * if is appliable for UIRequired:
 * Throttle conditions:
 * MSAL <-> server flow: OAuth error: error.msidOauthError is not nil
 * MSAL <-> SSO-Ext <-> Server flow: error.code MSALErrorInteractionRequired
 */
+ (BOOL)isApplicableForTheThrottleModel:(NSError *)errorResponse
{
    BOOL isMSIDError = [errorResponse msidIsMSIDError];
    
    if (isMSIDError)
    {
        NSString *errorString = errorResponse.msidOauthError;
        NSInteger errorCode = errorResponse.code;
        if (![NSString msidIsStringNilOrBlank:errorString]
            || errorCode == MSIDErrorInteractionRequired
            || errorCode == MSIDErrorServerDeclinedScopes
            || errorCode == MSIDErrorServerProtectionPoliciesRequired)
        {
            return YES;
        }
    }
    else
    {
        // MSALErrorInteractionRequired                 = -50002
        // MSALErrorServerDeclinedScopes                = -50003
        // MSALErrorServerProtectionPoliciesRequired    = -50004
        
        NSSet *uirequiredErrors = [[NSSet alloc] initWithArray:@[@(-50002),@(-50003),@(-50004)]];
        
        if ([uirequiredErrors containsObject:[NSNumber numberWithLong:errorResponse.code]])
        {
            return YES;
        }
    }
    return NO;
}

- (BOOL)shouldThrottleRequest
{
    NSError *error;
    NSDate *currentTime = [NSDate date];
    NSDate *lastRefreshTime = [MSIDThrottlingMetaDataCache getLastRefreshTimeWithDatasource:self.datasource context:self.context error:&error];
    // If currentTime is later than the expiration Time or the lastRefreshTime is later then the expiration Time, we don't throttle the request
    if ([currentTime compare:self.cacheRecord.expirationTime] != NSOrderedAscending
        || (lastRefreshTime && [lastRefreshTime compare:self.cacheRecord.creationTime] != NSOrderedAscending))
    {
        [[MSIDThrottlingModelBase cacheService] removeObjectForKey:self.thumbprintValue error:&error];
        if (error)
        {
            MSID_LOG_WITH_CTX(MSIDLogLevelError, self.context, @"Throttling: error when remove record from database %@ ", error);
        }
        return NO;
    }
    return YES;
}

- (MSIDThrottlingCacheRecord *)createDBCacheRecord
{
    MSIDThrottlingCacheRecord *record = [[MSIDThrottlingCacheRecord alloc] initWithErrorResponse:self.errorResponse
                                                                                    throttleType:MSIDThrottlingTypeInteractiveRequired
                                                                                throttleDuration:self.throttleDuration];
    return record;
}

- (void)updateServerTelemetry
{
    // TODO implement telemetry update here
    return ;
    
}

@end
