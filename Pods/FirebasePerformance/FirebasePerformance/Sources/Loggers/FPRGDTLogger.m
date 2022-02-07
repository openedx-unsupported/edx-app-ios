// Copyright 2020 Google LLC
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

#import "FirebasePerformance/Sources/Loggers/FPRGDTLogger.h"
#import "FirebasePerformance/Sources/Loggers/FPRGDTLogger_Private.h"

#import "FirebasePerformance/Sources/Configurations/FPRConfigurations.h"

#import "FirebasePerformance/Sources/Loggers/FPRGDTEvent.h"
#import "FirebasePerformance/Sources/Loggers/FPRGDTLogSampler.h"
#import "FirebasePerformance/Sources/Loggers/FPRGDTRateLimiter.h"

#import <GoogleDataTransport/GoogleDataTransport.h>

#import "FirebasePerformance/ProtoSupport/PerfMetric.pbobjc.h"

@implementation FPRGDTLogger

- (instancetype)initWithLogSource:(NSInteger)logSource {
  if (self = [super init]) {
    _logSource = logSource;

    _queue = dispatch_queue_create("com.google.FPRGDTLogger", DISPATCH_QUEUE_SERIAL);
    _configurations = [FPRConfigurations sharedInstance];
    FPRGDTLogSampler *logSampler = [[FPRGDTLogSampler alloc] init];
    FPRGDTRateLimiter *rateLimiter = [[FPRGDTRateLimiter alloc] init];

    _gdtfllTransport = [[GDTCORTransport alloc] initWithMappingID:@(logSource).stringValue
                                                     transformers:@[ logSampler, rateLimiter ]
                                                           target:kGDTCORTargetFLL];
    _isSimulator = NO;
    // If app is running on simulator, environment variable SIMULATOR_UDID exists.
    // Otherwise, SIMULATOR_UDID is not provided when app is running on real device.
    // For development, developers can dispatch performance events immediately if
    // they are running app on simulator, so it can expedite development process.
    if ([[[NSProcessInfo processInfo] environment] objectForKey:@"SIMULATOR_UDID"]) {
      _isSimulator = YES;
    }

    _instanceSeed = -1.0;  // -1.0 means instanceSeed has not been computed.
  }

  return self;
}

- (void)logEvent:(FPRMSGPerfMetric *)event {
  GDTCORTransport *eventTransporter = self.gdtfllTransport;

  dispatch_async(self.queue, ^{
    GDTCOREvent *gdtEvent = [eventTransporter eventForTransport];
    if (self.isSimulator) {
      gdtEvent.qosTier = GDTCOREventQoSFast;
    } else {
      gdtEvent.qosTier = GDTCOREventQosDefault;
    }
    gdtEvent.dataObject = [FPRGDTEvent gdtEventForPerfMetric:event];
    [eventTransporter sendDataEvent:gdtEvent];
  });
}

@end
