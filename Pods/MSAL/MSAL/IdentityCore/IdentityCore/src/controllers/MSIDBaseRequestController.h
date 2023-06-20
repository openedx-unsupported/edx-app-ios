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

#define CONDITIONAL_STOP_TELEMETRY_EVENT(x, y) CONDITIONAL_COMPILE_MSAL_CPP([self stopTelemetryEvent:(x) error:(y)])

#import <Foundation/Foundation.h>
#import "MSIDRequestParameters.h"
#import "MSIDTelemetryConditionalCompile.h"
#import "MSIDTokenRequestProviding.h"

@class MSIDTelemetryAPIEvent;
@protocol MSIDRequestControlling;

typedef void(^MSIDAuthorityCompletion)(BOOL resolved, NSError * _Nullable error);

@interface MSIDBaseRequestController : NSObject
{
    id<MSIDRequestControlling> _fallbackController;
}

@property (nonatomic, readonly, nullable) MSIDRequestParameters *requestParameters;
@property (nonatomic, readonly, nullable) id<MSIDTokenRequestProviding> tokenRequestProvider;
@property (nonatomic, readonly, nullable) id<MSIDRequestControlling> fallbackController;

- (nullable instancetype)initWithRequestParameters:(nonnull MSIDRequestParameters *)parameters
                              tokenRequestProvider:(nonnull id<MSIDTokenRequestProviding>)tokenRequestProvider
                                fallbackController:(nullable id<MSIDRequestControlling>)fallbackController
                                             error:(NSError * _Nullable * _Nullable)error;

#if !EXCLUDE_FROM_MSALCPP
- (nullable MSIDTelemetryAPIEvent *)telemetryAPIEvent;
- (void)stopTelemetryEvent:(nonnull MSIDTelemetryAPIEvent *)event error:(nullable NSError *)error;
#endif

- (nullable instancetype)init NS_UNAVAILABLE;
- (nullable instancetype)new NS_UNAVAILABLE;

@end
