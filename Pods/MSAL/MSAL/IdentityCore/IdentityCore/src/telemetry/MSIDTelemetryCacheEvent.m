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

#if !EXCLUDE_FROM_MSALCPP

#import "MSIDTelemetry.h"
#import "MSIDTelemetryCacheEvent.h"
#import "MSIDTelemetryEventStrings.h"
#import "MSIDRefreshToken.h"
#import "NSDate+MSIDExtensions.h"
#import "MSIDCacheKey.h"

@implementation MSIDTelemetryCacheEvent

- (id)initWithName:(NSString *)eventName
         requestId:(NSString *)requestId
     correlationId:(NSUUID *)correlationId
{
    if (!(self = [super initWithName:eventName requestId:requestId correlationId:correlationId]))
    {
        return nil;
    }
    
    [self setProperty:MSID_TELEMETRY_KEY_IS_FRT value:@""];
    [self setProperty:MSID_TELEMETRY_KEY_IS_MRRT value:@""];
    [self setProperty:MSID_TELEMETRY_KEY_IS_RT value:@""];
    
    return self;
}

- (void)setTokenType:(MSIDCredentialType)tokenType
{
    switch (tokenType)
    {
        case MSIDAccessTokenType:
            [self setProperty:MSID_TELEMETRY_KEY_TOKEN_TYPE value:MSID_TELEMETRY_VALUE_ACCESS_TOKEN];
            break;
            
        case MSIDRefreshTokenType:
            [self setProperty:MSID_TELEMETRY_KEY_TOKEN_TYPE value:MSID_TELEMETRY_VALUE_REFRESH_TOKEN];
            break;
            
        case MSIDLegacySingleResourceTokenType:
            [self setProperty:MSID_TELEMETRY_KEY_TOKEN_TYPE value:MSID_TELEMETRY_VALUE_ADFS_TOKEN];
            break;
            
        default:
            break;
    }
}

- (void)setStatus:(NSString *)status
{
    [self setProperty:MSID_TELEMETRY_KEY_RESULT_STATUS value:status];
}

- (void)setIsRT:(NSString *)isRT
{
    [self setProperty:MSID_TELEMETRY_KEY_IS_RT value:isRT];
}

- (void)setIsMRRT:(NSString *)isMRRT
{
    [self setProperty:MSID_TELEMETRY_KEY_IS_MRRT value:isMRRT];
}

- (void)setIsFRT:(NSString *)isFRT
{
    [self setProperty:MSID_TELEMETRY_KEY_IS_FRT value:isFRT];
}

- (void)setRTStatus:(NSString *)status
{
    [self setProperty:MSID_TELEMETRY_KEY_RT_STATUS value:status];
}

- (void)setMRRTStatus:(NSString *)status
{
    [self setProperty:MSID_TELEMETRY_KEY_MRRT_STATUS value:status];
}

- (void)setFRTStatus:(NSString *)status
{
    [self setProperty:MSID_TELEMETRY_KEY_FRT_STATUS value:status];
}

- (void)setSpeInfo:(NSString *)speInfo
{
    [self setProperty:MSID_TELEMETRY_KEY_SPE_INFO value:speInfo];
}

- (void)setToken:(MSIDBaseToken *)token
{
    if (!token)
    {
        return;
    }
    
    [self setTokenType:token.credentialType];
    [self setSpeInfo:token.additionalServerInfo[MSID_TELEMETRY_KEY_SPE_INFO]];
    
    if (token.credentialType == MSIDLegacySingleResourceTokenType)
    {
        [self setIsRT:MSID_TELEMETRY_VALUE_YES];
        [self setRTStatus:MSID_TELEMETRY_VALUE_TRIED];
    }
    
    if (token.credentialType == MSIDRefreshTokenType)
    {
        MSIDRefreshToken *refreshToken = (MSIDRefreshToken *)token;
        
        BOOL isFRT = [token.clientId isEqualToString:[MSIDCacheKey familyClientId:refreshToken.familyId]];
        
        if (isFRT)
        {
            [self setIsFRT:MSID_TELEMETRY_VALUE_YES];
            [self setFRTStatus:MSID_TELEMETRY_VALUE_TRIED];
        }
        else
        {
            [self setIsMRRT:MSID_TELEMETRY_VALUE_YES];
            [self setMRRTStatus:MSID_TELEMETRY_VALUE_TRIED];
        }
    }
}

- (void)setCacheWipeApp:(NSString *)wipeApp
{
    [self setProperty:MSID_TELEMETRY_KEY_WIPE_APP value:wipeApp];
}

- (void)setCacheWipeTime:(NSString *)wipeTime
{
    [self setProperty:MSID_TELEMETRY_KEY_WIPE_TIME value:wipeTime];
}

- (void)setWipeData:(NSDictionary *)wipeData
{
    if (wipeData)
    {
        [self setCacheWipeApp:wipeData[@"bundleId"]];
        [self setCacheWipeTime:[(NSDate *)wipeData[@"wipeTime"] msidToString]];
    }
}

- (void)setExternalCacheSeedingStatus:(NSString *)status
{
    [self setProperty:MSID_TELEMETRY_KEY_EXTERNAL_CACHE_SEEDING_STATUS value:status];
}

#pragma mark - MSIDTelemetryBaseEvent

+ (NSArray<NSString *> *)propertiesToAggregate
{
    static dispatch_once_t once;
    static NSMutableArray *names = nil;
    
    dispatch_once(&once, ^{
        names = [[super propertiesToAggregate] mutableCopy];
        
        [names addObjectsFromArray:@[
                                     MSID_TELEMETRY_KEY_RT_STATUS,
                                     MSID_TELEMETRY_KEY_FRT_STATUS,
                                     MSID_TELEMETRY_KEY_MRRT_STATUS,
                                     MSID_TELEMETRY_KEY_CACHE_EVENT_COUNT,
                                     MSID_TELEMETRY_KEY_SPE_INFO,
                                     MSID_TELEMETRY_KEY_WIPE_APP,
                                     MSID_TELEMETRY_KEY_WIPE_TIME,
                                     MSID_TELEMETRY_KEY_EXTERNAL_CACHE_SEEDING_STATUS
                                     ]];
    });
    
    return names;
}

@end

#endif
