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
#import "MSIDTelemetry+Internal.h"
#import "MSIDTelemetryEventInterface.h"
#import "MSIDTelemetryDispatcher.h"
#import "MSIDTelemetryEventStrings.h"
#import "MSIDTelemetryPiiOiiRules.h"

static NSString* const s_delimiter = @"|";

@interface MSIDTelemetry ()
{
    NSMutableArray<id<MSIDTelemetryDispatcher>> *_dispatchers;
    NSMutableDictionary *_eventTracking;
}

@end

@implementation MSIDTelemetry

- (id)init
{
    //Ensure that the appropriate init function is called. This will cause the runtime to throw.
    [super doesNotRecognizeSelector:_cmd];
    return nil;
}

- (id)initInternal
{
    self = [super init];
    if (self)
    {
        _eventTracking = [NSMutableDictionary new];
        _dispatchers = [NSMutableArray new];
    }
    return self;
}

+ (MSIDTelemetry *)sharedInstance
{
    static dispatch_once_t once;
    static MSIDTelemetry *singleton = nil;
    
    dispatch_once(&once, ^{
        singleton = [[MSIDTelemetry alloc] initInternal];
    });
    
    return singleton;
}

- (void)addDispatcher:(nonnull id<MSIDTelemetryDispatcher>)dispatcher
{
    @synchronized (self)
    {
        if (![_dispatchers containsObject:dispatcher])
        {
            [_dispatchers addObject:dispatcher];
        }
    }
}

- (void)removeDispatcher:(nonnull id<MSIDTelemetryDispatcher>)dispatcher
{
    @synchronized (self)
    {
        [_dispatchers removeObject:dispatcher];
    }
}

- (void)removeAllDispatchers
{
    @synchronized (self)
    {
        [_dispatchers removeAllObjects];
    }
}

@end

@implementation MSIDTelemetry (Internal)

- (NSString *)generateRequestId
{
    return [[NSUUID UUID] UUIDString];
}

- (void)startEvent:(NSString *)requestId
         eventName:(NSString *)eventName
{
    if ([NSString msidIsStringNilOrBlank:requestId] || [NSString msidIsStringNilOrBlank:eventName])
    {
        return;
    }
    
    NSDate *currentTime = [NSDate date];
    
    @synchronized (self)
    {
        NSString *key = [self getEventTrackingKey:requestId eventName:eventName];

        if (!_eventTracking[key])
        {
            [_eventTracking setObject:currentTime
                               forKey:key];
        }
    }
}

- (void)removeDispatcherByObserver:(id)observer
{
    @synchronized (self)
    {
        for (id<MSIDTelemetryDispatcher> msidDispatcher in _dispatchers)
        {
            if ([msidDispatcher containsObserver:observer])
            {
                [_dispatchers removeObject:msidDispatcher];
            }
        }
    }
}

- (void)stopEvent:(NSString *)requestId
            event:(id<MSIDTelemetryEventInterface>)event
{
    NSDate *stopTime = [NSDate date];
    NSString *eventName = [event propertyWithName:MSID_TELEMETRY_KEY_EVENT_NAME];
    
    if ([NSString msidIsStringNilOrBlank:requestId] || [NSString msidIsStringNilOrBlank:eventName] || !event)
    {
        return;
    }
    
    NSString *key = [self getEventTrackingKey:requestId eventName:eventName];
    
    NSDate *startTime = nil;
    
    @synchronized (self)
    {
        startTime = [_eventTracking objectForKey:key];
        if (!startTime)
        {
            return;
        }
    }
    
    [event setStartTime:startTime];
    [event setStopTime:stopTime];
    [event setResponseTime:[stopTime timeIntervalSinceDate:startTime]];
    
    @synchronized (self)
    {
        [_eventTracking removeObjectForKey:key];
        
        [self dispatchEventNow:requestId event:event];
    }
}

- (void)dispatchEventNow:(NSString *)requestId
                   event:(id<MSIDTelemetryEventInterface>)event
{
    @synchronized (self)
    {
        for (id<MSIDTelemetryDispatcher> dispatcher in _dispatchers)
        {
            for (NSString *propertyName in [event.propertyMap allKeys])
            {
                BOOL isPiiOrOii = [MSIDTelemetryPiiOiiRules isPiiOrOii:propertyName];
                
                if (isPiiOrOii && !self.piiEnabled)
                {
                    [event deleteProperty:propertyName];
                }
            }
            
            [dispatcher receive:requestId event:event];
        }
    }
}

- (NSString *)getEventTrackingKey:(NSString*)requestId
                       eventName:(NSString*)eventName
{
    return [NSString stringWithFormat:@"%@%@%@", requestId, s_delimiter, eventName];
}

- (void)flush:(NSString *)requestId
{
    @synchronized (self)
    {
        for (id<MSIDTelemetryDispatcher> dispatcher in _dispatchers)
        {
            [dispatcher flush:requestId];
        }
    }
}

@end
