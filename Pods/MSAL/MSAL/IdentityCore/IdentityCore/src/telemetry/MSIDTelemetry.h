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

#define CONDITIONAL_SHARED_INSTANCE CONDITIONAL_COMPILE_MSAL_CPP([MSIDTelemetry sharedInstance])

#import "MSIDTelemetryConditionalCompile.h"

#if !EXCLUDE_FROM_MSALCPP

#import "MSIDTelemetryDispatcher.h"

/*!
    @class ADTelemetry
 
    The central class for ADAL telemetry.
 
    Usage: Get a singleton instance of ADTelemetry; register a dispatcher for receiving telemetry events.
 */
@interface MSIDTelemetry : NSObject

/*!
    Get a singleton instance of ADTelemetry.
 */
+ (nonnull MSIDTelemetry*)sharedInstance;

/*!
 Set to YES to allow events possibly containing Personally Identifiable Information (PII) to be
 sent to dispatcher. By default it is NO.
 */
@property (atomic) BOOL piiEnabled;

/*!
 If set YES, telemetry events are only dispatched when errors occurred;
 If set NO, will dispatch all events.
 */
@property (atomic) BOOL notifyOnFailureOnly;

/*!
    Register a telemetry dispatcher for receiving telemetry events.
    @param dispatcher            An instance of MSIDTelemetryDispatcher implementation.
 */
- (void)addDispatcher:(nonnull id<MSIDTelemetryDispatcher>)dispatcher;

/*!
 Remove a telemetry dispatcher added for receiving telemetry events.
 @param dispatcher            An instance of MSIDTelemetryDispatcher implementation added to the dispatches before.
 */
- (void)removeDispatcher:(nonnull id<MSIDTelemetryDispatcher>)dispatcher;

/*!
 Remove all telemetry dispatchers added to the dispatchers collection.
 */
- (void)removeAllDispatchers;

@end

#endif
