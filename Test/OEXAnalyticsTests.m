//
//  OEXAnalyticsTests.m
//  edXVideoLocker
//
//  Created by Akiva Leffert on 3/27/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import "OEXAnalytics.h"
#import "NSBundle+OEXConveniences.h"
#import "OEXEnvironment.h"
#import "OEXMockAnalyticsTracker.h"
#import "edX-Swift.h"

@interface OEXAnalyticsTests : XCTestCase

@property (strong, nonatomic) OEXMockAnalyticsTracker* analyticsTracker;
@property (strong, nonatomic) OEXAnalytics* analytics;

@end

@implementation OEXAnalyticsTests

- (void)setUp {
    [super setUp];
    self.analytics = [[OEXAnalytics alloc] init];
    self.analyticsTracker = [[OEXMockAnalyticsTracker alloc] init];
    [self.analytics addTracker:self.analyticsTracker];
}

- (void)testRegistrationEvent {
    NSString* provider = @"SomeProvider";
    
    NSMutableDictionary *dictionary = [[NSMutableDictionary alloc] init];
    [dictionary setObject:provider forKey:OEXAnalyticsKeyProvider];
    [self.analytics trackEvent:[OEXAnalytics registerEventWithName:@"edx.bi.app.user.register.clicked" displayName:@"displayName"] forComponent:nil withInfo:dictionary];
    NSArray* events = self.analyticsTracker.observedEvents;
    XCTAssertEqual(events.count, 1);
    OEXMockAnalyticsEventRecord* record = events[0];
    XCTAssertEqualObjects(record.properties, @{@"provider" : provider});
    XCTAssertEqualObjects(record.event.name, @"edx.bi.app.user.register.clicked");
    XCTAssertEqualObjects(record.event.category, @"conversion");
    
    NSString* label = [NSString stringWithFormat:@"iOS v%@", [[NSBundle mainBundle] oex_shortVersionString]];
    XCTAssertEqualObjects(record.event.label, label);
}

- (void)testRegistrationNullProvider {
    
    [self.analytics trackEvent:[OEXAnalytics registerEventWithName:@"" displayName:@""] forComponent:nil withInfo:@{}];
    NSArray* events = self.analyticsTracker.observedEvents;
    XCTAssertEqual(events.count, 1);
    OEXMockAnalyticsEventRecord* record = events[0];
    XCTAssertEqualObjects(record.properties, @{});
}

@end
