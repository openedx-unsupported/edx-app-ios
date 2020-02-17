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

#import "MSIDTelemetry.h"
#import "MSIDTelemetryUIEvent.h"
#import "MSIDTelemetryEventStrings.h"

@implementation MSIDTelemetryUIEvent

- (id)initWithName:(NSString *)eventName
         requestId:(NSString *)requestId
     correlationId:(NSUUID *)correlationId
{
    if (!(self = [super initWithName:eventName requestId:requestId correlationId:correlationId]))
    {
        return nil;
    }
    
    [self setProperty:MSID_TELEMETRY_KEY_USER_CANCEL value:@""];
    [self setProperty:MSID_TELEMETRY_KEY_NTLM_HANDLED value:@""];
    
    return self;
}

- (void)setLoginHint:(NSString *)hint
{
    [self setProperty:MSID_TELEMETRY_KEY_LOGIN_HINT value:hint];
}

- (void)setNtlm:(NSString *)ntlmHandled
{
    [self setProperty:MSID_TELEMETRY_KEY_NTLM_HANDLED value:ntlmHandled];
}

- (void)setIsCancelled:(BOOL)cancelled
{
    [self setProperty:MSID_TELEMETRY_KEY_UI_CANCELLED value:cancelled ? MSID_TELEMETRY_VALUE_YES : MSID_TELEMETRY_VALUE_NO];
}

#pragma mark - MSIDTelemetryBaseEvent

+ (NSArray<NSString *> *)propertiesToAggregate
{
    static dispatch_once_t once;
    static NSMutableArray *names = nil;
    
    dispatch_once(&once, ^{
        names = [[super propertiesToAggregate] mutableCopy];
        
        [names addObjectsFromArray:@[
                                     MSID_TELEMETRY_KEY_USER_CANCEL,
                                     MSID_TELEMETRY_KEY_LOGIN_HINT,
                                     MSID_TELEMETRY_KEY_NTLM_HANDLED,
                                     MSID_TELEMETRY_KEY_UI_EVENT_COUNT
                                     ]];
    });
    
    return names;
}

@end
