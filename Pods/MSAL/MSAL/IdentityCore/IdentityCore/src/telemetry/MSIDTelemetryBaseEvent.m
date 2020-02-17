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

#import "MSIDTelemetryBaseEvent.h"
#import "NSDate+MSIDExtensions.h"
#import "NSMutableDictionary+MSIDExtensions.h"
#import "MSIDTelemetryPiiOiiRules.h"
#import "MSIDTelemetryEventStrings.h"
#import "MSIDDeviceId.h"
#import "MSIDVersion.h"
#import "MSIDTelemetry.h"
#import "NSData+MSIDExtensions.h"

@implementation MSIDTelemetryBaseEvent

@synthesize propertyMap = _propertyMap;
@synthesize errorInEvent = _errorInEvent;

- (instancetype)initWithName:(NSString *)eventName
                   requestId:(NSString *)requestId
               correlationId:(NSUUID *)correlationId
{
    if (!(self = [super init]))
    {
        return nil;
    }
    
    _errorInEvent = NO;
    
    _propertyMap = [NSMutableDictionary dictionary];
    
    [self setProperty:MSID_TELEMETRY_KEY_REQUEST_ID value:requestId];
    [self setProperty:MSID_TELEMETRY_KEY_CORRELATION_ID value:[correlationId UUIDString]];
    [self setProperty:MSID_TELEMETRY_KEY_EVENT_NAME value:eventName];
    
    return self;
}

- (instancetype)initWithName:(NSString *)eventName
                     context:(id<MSIDRequestContext>)configuration
{
    return [self initWithName:eventName requestId:configuration.telemetryRequestId correlationId:configuration.correlationId];
}

- (void)setProperty:(NSString *)name value:(NSString *)value
{
    // value can be empty but not nil
    if ([NSString msidIsStringNilOrBlank:name] || !value)
    {
        return;
    }
    
    if ([MSIDTelemetryPiiOiiRules isPii:name])
    {
        value = [[value dataUsingEncoding:NSUTF8StringEncoding] msidSHA256].msidHexString;
    }
    
    [_propertyMap setValue:value forKey:name];
}

- (NSString *)propertyWithName:(NSString *)name
{
    if ([NSString msidIsStringNilOrBlank:name])
    {
        return nil;
    }
    
    return _propertyMap[name];
}

- (void)deleteProperty:(NSString  *)name
{
    if ([NSString msidIsStringNilOrBlank:name])
    {
        return;
    }
    
    [_propertyMap removeObjectForKey:name];
}

- (NSDictionary *)getProperties
{
    return _propertyMap;
}

- (void)setStartTime:(NSDate *)time
{
    if (!time)
    {
        return;
    }
    
    [self setProperty:MSID_TELEMETRY_KEY_START_TIME value:[time msidToString]];
}

- (void)setStopTime:(NSDate *)time
{
    if (!time)
    {
        return;
    }
    
    [self setProperty:MSID_TELEMETRY_KEY_END_TIME value:[time msidToString]];
}

- (void)setResponseTime:(NSTimeInterval)responseTime
{
    //the property is set in milliseconds
    [self setProperty:MSID_TELEMETRY_KEY_RESPONSE_TIME value:[NSString stringWithFormat:@"%f", responseTime*1000]];
}

- (void)addDefaultProperties
{
    [_propertyMap addEntriesFromDictionary:[[self class] defaultParameters]];
}

+ (NSArray<NSString *> *)propertiesToAggregate
{
    static dispatch_once_t once;
    static NSArray *names = nil;
    
    dispatch_once(&once, ^{
        names = @[
                  MSID_TELEMETRY_KEY_REQUEST_ID,
                  MSID_TELEMETRY_KEY_CORRELATION_ID
                  ];
    });
    
    return names;
}

+ (NSDictionary *)defaultParameters
{
    NSMutableDictionary *defaultParameters = [NSMutableDictionary new];
    
    NSDictionary *rawParameters = [[self class] rawDefaultParameters];
    for (NSString *key in [rawParameters allKeys])
    {
        // filter Pii and Oii
        if (([MSIDTelemetryPiiOiiRules isPii:key] || [MSIDTelemetryPiiOiiRules isOii:key])
            && ![MSIDTelemetry sharedInstance].piiEnabled)
        {
            continue;
        }
        
        // hash Pii
        NSString *value = rawParameters[key];
        if ([MSIDTelemetryPiiOiiRules isPii:key])
        {
            value = [[value dataUsingEncoding:NSUTF8StringEncoding] msidSHA256].msidHexString;
        }
        
        [defaultParameters setValue:value forKey:key];
    }
    
    return defaultParameters;
}

+ (NSDictionary *)rawDefaultParameters
{
    static NSMutableDictionary *s_defaultParameters;
    static dispatch_once_t s_configurationOnce;
    
    dispatch_once(&s_configurationOnce, ^{
        
        s_defaultParameters = [NSMutableDictionary new];
        
        NSString *deviceId = [MSIDDeviceId deviceTelemetryId];
        NSString *applicationName = [MSIDDeviceId applicationName];
        NSString *applicationVersion = [MSIDDeviceId applicationVersion];
        
        [s_defaultParameters msidSetObjectIfNotNil:deviceId
                                            forKey:MSID_TELEMETRY_KEY_DEVICE_ID];
        [s_defaultParameters msidSetObjectIfNotNil:applicationName
                                            forKey:MSID_TELEMETRY_KEY_APPLICATION_NAME];
        [s_defaultParameters msidSetObjectIfNotNil:applicationVersion
                                            forKey:MSID_TELEMETRY_KEY_APPLICATION_VERSION];
        
        NSDictionary *adalId = [MSIDDeviceId deviceId];
        
        for (NSString *key in adalId)
        {
            NSString *propertyName = [[key lowercaseString] stringByReplacingOccurrencesOfString:@"-" withString:@"_"];
            [s_defaultParameters msidSetObjectIfNotNil:[adalId objectForKey:key] forKey:propertyName];
        }
    });
    
    return s_defaultParameters;
}

@end
