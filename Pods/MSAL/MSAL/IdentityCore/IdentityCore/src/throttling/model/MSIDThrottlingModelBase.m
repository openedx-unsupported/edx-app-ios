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
#import "MSIDThrottlingModelBase.h"
#import "MSIDLRUCache.h"

@implementation MSIDThrottlingModelBase

+ (MSIDLRUCache *)cacheService
{
    return [MSIDLRUCache sharedInstance];
}

- (instancetype)initWithRequest:(id<MSIDThumbprintCalculatable>)request
                    cacheRecord:(MSIDThrottlingCacheRecord *)cacheRecord
                  errorResponse:(NSError *)errorResponse
                     datasource:(id<MSIDExtendedTokenCacheDataSource>_Nonnull)datasource
{
    self = [super init];
    if (self)
    {
        _request = request;
        _cacheRecord = cacheRecord;
        _errorResponse = errorResponse;
        _datasource = datasource;
    }
    return self;
}

- (void)cleanCacheRecordFromDB
{
    NSError *error = nil;
    [[MSIDThrottlingModelBase cacheService] removeObjectForKey:self.thumbprintValue error:&error];
    if (error)
    {
        MSID_LOG_WITH_CTX(MSIDLogLevelError, self.context, @"Error remove the record from throttling database %@", error);
    }
}

- (void)insertOrUpdateCacheRecordToDB:(MSIDThrottlingCacheRecord *)cacheRecord
{
    NSError *error = nil;
    MSID_LOG_WITH_CTX(MSIDLogLevelInfo, self.context, @"Adding the record to throttling database with thumbprint value: %@, type: %ld", self.thumbprintValue, (long)self.thumbprintType);

    [[MSIDThrottlingModelBase cacheService] setObject:cacheRecord forKey:self.thumbprintValue error:&error];
    if (error)
    {
        MSID_LOG_WITH_CTX(MSIDLogLevelError, self.context, @"Error adding the record to throttling database %@", error);
    }
}

- (MSIDThrottlingCacheRecord *)createDBCacheRecord
{
    NSAssert(NO, @"Abstract method.");
    return nil;
}

+ (BOOL)isApplicableForTheThrottleModel:(NSError *)errorResponse
{
    NSAssert(NO, @"Abstract method.");
    return NO;
}

- (BOOL)shouldThrottleRequest
{
    NSAssert(NO, @"Abstract method.");
    return NO;
}

- (void)updateServerTelemetry
{
    NSAssert(NO, @"Abstract method.");
    return ;
}

@end
