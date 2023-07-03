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

#import "MSIDTelemetryAuthorityValidationEvent.h"
#import "MSIDAuthority.h"
#import "MSIDTelemetryEventStrings.h"

@implementation MSIDTelemetryAuthorityValidationEvent

- (void)setAuthorityValidationStatus:(NSString *)status
{
    [self setProperty:MSID_TELEMETRY_KEY_AUTHORITY_VALIDATION_STATUS value:status];
}

- (void)setAuthority:(MSIDAuthority *)authority
{
    NSString *authorityType = [authority telemetryAuthorityType];

    [self setProperty:MSID_TELEMETRY_KEY_AUTHORITY_TYPE value:authorityType];
    [self setProperty:MSID_TELEMETRY_KEY_AUTHORITY value:authority.url.absoluteString];
}

#pragma mark - MSIDTelemetryBaseEvent

+ (NSArray<NSString *> *)propertiesToAggregate
{
    static dispatch_once_t once;
    static NSMutableArray *names = nil;
    
    dispatch_once(&once, ^{
        names = [[super propertiesToAggregate] mutableCopy];
        
        [names addObjectsFromArray:@[
                                     MSID_TELEMETRY_KEY_AUTHORITY_VALIDATION_STATUS,
                                     MSID_TELEMETRY_KEY_AUTHORITY_TYPE,
                                     MSID_TELEMETRY_KEY_AUTHORITY
                                     ]];
    });
    
    return names;
}

@end

#endif
