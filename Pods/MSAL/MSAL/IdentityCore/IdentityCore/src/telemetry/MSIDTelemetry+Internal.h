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

#define CONDITIONAL_START_EVENT(x, y, z) CONDITIONAL_COMPILE_MSAL_CPP([x startEvent:(y) eventName:(z)])
#define CONDITIONAL_STOP_EVENT(x, y, z) CONDITIONAL_COMPILE_MSAL_CPP([x stopEvent:(y) event:(z)])

#import "MSIDTelemetryConditionalCompile.h"

#if !EXCLUDE_FROM_MSALCPP

#import "MSIDTelemetry.h"
#import "MSIDTelemetryEventInterface.h"
#import "MSIDTelemetryDispatcher.h"

@interface MSIDTelemetry (Internal)

- (NSString *)generateRequestId;

- (void)startEvent:(NSString *)requestId
         eventName:(NSString *)eventName;

- (void)stopEvent:(NSString *)requestId
            event:(id<MSIDTelemetryEventInterface>)event;

- (void)dispatchEventNow:(NSString*)requestId
                   event:(id<MSIDTelemetryEventInterface>)event;

- (void)flush:(NSString *)requestId;

- (void)removeDispatcherByObserver:(id)observer;

@end

#endif
