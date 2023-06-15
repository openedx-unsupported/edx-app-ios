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

#define CONDITIONAL_SET_REFRESH_TYPE(x, y) CONDITIONAL_COMPILE_MSAL_CPP((x) = (y))

#import <Foundation/Foundation.h>
#import "MSIDTelemetryConditionalCompile.h"
#import "MSIDTelemetryStringSerializable.h"

NS_ASSUME_NONNULL_BEGIN

/*
 •    TokenCacheRefreshTypeNoCacheLookupInvolved = 0, request goes to ESTS for interactive call for which there is no cache look-up involved (N/A for S2S).
 •    TokenCacheRefreshTypeForceRefresh = 1, request goes to ESTS because caller requested to forcefully refresh the cache.
 •    TokenCacheRefreshTypeNoCachedAT = 2, request goes to ESTS because cache entry for the requested token does NOT exist.
 •    TokenCacheRefreshTypeExpiredAT = 3, request goes to ESTS because cache entry for the requested token does exist but token has expired.
 •    TokenCacheRefreshTypeProactiveTokenRefresh = 4, request goes to ESTS because refresh_in was used and existing non-expired token needs to be refreshed proactively.
 •    TokenCacheRefreshTypeCachingMechanismNotImplemented = 5, request goes to ESTS because client (for Non-MSAL client specifically for now) has not implemented any caching mechanism.
 •    BLANK, if client is not aware of the LLT policy and its telemetry update and doesn’t update their code to send us this telemetry signal yet.
 */

typedef NS_ENUM(NSInteger, TokenCacheRefreshType)
{
    TokenCacheRefreshTypeNoCacheLookupInvolved,
    TokenCacheRefreshTypeForceRefresh,
    TokenCacheRefreshTypeNoCachedAT,
    TokenCacheRefreshTypeExpiredAT,
    TokenCacheRefreshTypeProactiveTokenRefresh,
    TokenCacheRefreshTypeCachingMechanismNotImplemented,
};

#if !EXCLUDE_FROM_MSALCPP

@interface MSIDCurrentRequestTelemetry : NSObject <MSIDTelemetryStringSerializable>

- (nullable instancetype)initWithAppId:(NSInteger)appId
                 tokenCacheRefreshType:(TokenCacheRefreshType)tokenCacheRefreshType
                        platformFields:(nullable NSMutableArray *)platformFields;

@property (nonatomic) NSInteger schemaVersion;
@property (nonatomic) NSInteger apiId;
@property (nonatomic) TokenCacheRefreshType tokenCacheRefreshType;
@property (nonatomic, nullable) NSMutableArray<NSString *> *platformFields;

@end

#endif

NS_ASSUME_NONNULL_END
