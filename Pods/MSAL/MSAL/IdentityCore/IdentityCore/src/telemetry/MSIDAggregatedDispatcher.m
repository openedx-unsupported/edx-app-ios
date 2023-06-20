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

#import "MSIDAggregatedDispatcher.h"
#import "MSIDDefaultDispatcher+Internal.h"
#import "MSIDTelemetryBaseEvent.h"
#import "MSIDTelemetryEventStrings.h"

typedef NS_ENUM(NSInteger, MSIDTelemetryCollectionBehavior)
{
    MSIDTelemetryCollectionBehaviorCollectOnly,
    MSIDTelemetryCollectionBehaviorCollectAndCount
};

static NSDictionary *s_telemetryCollectionRules;

@interface MSIDAggregatedDispatcher ()

@end

@implementation MSIDAggregatedDispatcher

+ (void)initialize
{
    if (self == [MSIDAggregatedDispatcher self])
    {
        s_telemetryCollectionRules = @{
                                       // Collect and count
                                       MSID_TELEMETRY_KEY_UI_EVENT_COUNT: @(MSIDTelemetryCollectionBehaviorCollectAndCount),
                                       MSID_TELEMETRY_KEY_HTTP_EVENT_COUNT: @(MSIDTelemetryCollectionBehaviorCollectAndCount),
                                       MSID_TELEMETRY_KEY_CACHE_EVENT_COUNT: @(MSIDTelemetryCollectionBehaviorCollectAndCount),
                                       MSID_TELEMETRY_KEY_GET_V1_IDTOKEN_HTTP_EVENT_COUNT: @(MSIDTelemetryCollectionBehaviorCollectAndCount),
                                       MSID_TELEMETRY_KEY_GET_V1_IDTOKEN_CACHE_EVENT_COUNT: @(MSIDTelemetryCollectionBehaviorCollectAndCount),
                                       };
    }
}

#pragma mark - MSIDTelemetryDispatcher

- (void)flush:(NSString *)requestId
{
    NSArray<id<MSIDTelemetryEventInterface>> *events = [self popEventsForRequestId:requestId];
    
    if (events.count == 0) return;
    
    NSMutableDictionary *aggregatedEvent = [[MSIDTelemetryBaseEvent defaultParameters] mutableCopy];
    for (id<MSIDTelemetryEventInterface> event in events)
    {
        [self addProperties:aggregatedEvent fromEvent:event];
    }
    
    [self dispatchEvents:@[aggregatedEvent]];
}

#pragma mark - Private

- (void)addProperties:(NSMutableDictionary *)aggregatedEvent fromEvent:(id<MSIDTelemetryEventInterface>)event
{
    __auto_type propertyNames = [event.class propertiesToAggregate];
    for (NSString *propertyName in propertyNames)
    {
        MSIDTelemetryCollectionBehavior collectionBehavior = [s_telemetryCollectionRules[propertyName] integerValue];
        
        if (collectionBehavior == MSIDTelemetryCollectionBehaviorCollectAndCount)
        {
            int eventsCount = [aggregatedEvent[propertyName] intValue] + 1;
            aggregatedEvent[propertyName] = [[NSNumber alloc] initWithInt:eventsCount];
        }
        else
        {
            aggregatedEvent[propertyName] = [event propertyWithName:propertyName];
        }
    }
}

@end

#endif
