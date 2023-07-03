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
#import "MSIDThrottlingModelFactory.h"
#import "MSIDThrottlingCacheRecord.h"
#import "MSIDLRUCache.h"
#import "MSIDThrottlingModelBase.h"
#import "MSIDThrottlingModelNonRecoverableServerError.h"
#import "MSIDThrottlingModel429.h"
#import "NSString+MSIDExtensions.h"

@implementation MSIDThrottlingModelFactory

+ (MSIDThrottlingModelBase *)throttlingModelForIncomingRequest:(id<MSIDThumbprintCalculatable>)request
                                                   datasource:(id<MSIDExtendedTokenCacheDataSource>)datasource
                                                       context:(id<MSIDRequestContext>)context
{
    if (![MSIDThrottlingModelFactory validateInput:request])
    {
        MSID_LOG_WITH_CTX(MSIDLogLevelError, context, @"Throttling: both strict and fullthumbprint of the request are null");
        return nil;
    }
        
    NSError *error;
    MSIDThrottlingCacheRecord *cacheRecord = [MSIDThrottlingModelFactory getDBRecordWithStrictThumbprint:request.strictRequestThumbprint
                                                                                          fullThumbprint:request.fullRequestThumbprint
                                                                                                   error:&error];
    if (error)
    {
        if (error.code == MSIDErrorThrottleCacheNoRecord || error.code == MSIDErrorThrottleCacheInvalidSignature)
        {
            MSID_LOG_WITH_CTX(MSIDLogLevelVerbose, context, @"Throttling: No record in throttle cache");
            error = nil;
        }
        else
        {
            MSID_LOG_WITH_CTX(MSIDLogLevelInfo, context, @"Throttling: getting record from cache has returned error %@", error);
        }
    }
    
    if(!cacheRecord) return nil;
    return [self generateModelFromErrorResponse:nil
                                        request:request
                                   throttleType:cacheRecord.throttleType
                                    cacheRecord:cacheRecord
                                    datasource:datasource];
}

+ (MSIDThrottlingModelBase *)throttlingModelForResponseWithRequest:(id<MSIDThumbprintCalculatable>)request
                                                       datasource:(id<MSIDExtendedTokenCacheDataSource>)datasource
                                                     errorResponse:(NSError *)errorResponse
                                                           context:(id<MSIDRequestContext>)context
{
    MSIDThrottlingType throttleType = [MSIDThrottlingModelFactory processErrorResponseToGetThrottleType:errorResponse];
    
    if (throttleType == MSIDThrottlingTypeNone)
    {
        MSID_LOG_WITH_CTX(MSIDLogLevelInfo, nil, @"Throttling: [throttlingModelForResponseWithRequest] throttle type is neither 429 nor interaction required.");
        return nil;
    }
    return [self generateModelFromErrorResponse:errorResponse
                                        request:request
                                   throttleType:throttleType
                                    cacheRecord:nil
                                    datasource:datasource];
}

+ (MSIDThrottlingModelBase *)generateModelFromErrorResponse:(NSError *)errorResponse
                                                    request:(id<MSIDThumbprintCalculatable>)request
                                               throttleType:(MSIDThrottlingType)throttleType
                                                cacheRecord:(MSIDThrottlingCacheRecord *)cacheRecord
                                                 datasource:(id<MSIDExtendedTokenCacheDataSource>)datasource
{
    if(throttleType == MSIDThrottlingType429)
    {
        return [[MSIDThrottlingModel429 alloc] initWithRequest:request cacheRecord:cacheRecord errorResponse:errorResponse datasource:datasource];
    }
    else
    {
        return [[MSIDThrottlingModelNonRecoverableServerError alloc] initWithRequest:request cacheRecord:cacheRecord errorResponse:errorResponse datasource:datasource];
    }
}

+ (MSIDThrottlingType)processErrorResponseToGetThrottleType:(NSError *)errorResponse
{
    
    MSIDThrottlingType throttleType = MSIDThrottlingTypeNone;
    if ([MSIDThrottlingModel429 isApplicableForTheThrottleModel:errorResponse])
    {
        MSID_LOG_WITH_CTX(MSIDLogLevelInfo, nil, @"Throttling: [processErrorResponseToGetThrottleType] error response is of type 429.");
        throttleType = MSIDThrottlingType429;
    }
    else if ([MSIDThrottlingModelNonRecoverableServerError isApplicableForTheThrottleModel:errorResponse])
    {
        MSID_LOG_WITH_CTX(MSIDLogLevelInfo, nil, @"Throttling: [processErrorResponseToGetThrottleType] error response is of type interaction required.");
        throttleType = MSIDThrottlingTypeInteractiveRequired;
    }
    
    return throttleType;
}


+ (BOOL)validateInput:(id<MSIDThumbprintCalculatable>)request
{
    return (request.fullRequestThumbprint || request.strictRequestThumbprint);
}


+ (MSIDThrottlingCacheRecord *)getDBRecordWithStrictThumbprint:(NSString *)strictThumbprint
                                                fullThumbprint:(NSString *)fullThumbprint
                                                         error:(NSError **)error
{
    MSID_LOG_WITH_CTX(MSIDLogLevelVerbose, nil, @"Query throttling database with thumbprint strict value: %@, full value: %@", strictThumbprint, fullThumbprint);
    MSIDThrottlingCacheRecord *cacheRecord;
    if (![NSString msidIsStringNilOrBlank:strictThumbprint])
    {
        cacheRecord = [[MSIDLRUCache sharedInstance] objectForKey:strictThumbprint
                                                            error:error];
    }
     
    if (!cacheRecord && ![NSString msidIsStringNilOrBlank:fullThumbprint])
    {
        cacheRecord = [[MSIDLRUCache sharedInstance] objectForKey:fullThumbprint error:error];
    }
    return cacheRecord;
}

@end
