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

#define CONDITIONAL_UI_EVENT_SET_IS_CANCELLED(x, y) CONDITIONAL_COMPILE_MSAL_CPP([x setIsCancelled:(y)])

#import "MSIDTelemetryConditionalCompile.h"

#if !EXCLUDE_FROM_MSALCPP

#import "MSIDTelemetryBaseEvent.h"

@interface MSIDTelemetryUIEvent : MSIDTelemetryBaseEvent

- (void)setLoginHint:(NSString *)hint;
- (void)setNtlm:(NSString *)ntlmHandled;

- (void)setIsCancelled:(BOOL)cancelled;

@end

#endif
