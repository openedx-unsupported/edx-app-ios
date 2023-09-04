//
//  OEXMockAnalyticsTracker.m
//  edXVideoLocker
//
//  Created by Akiva Leffert on 3/27/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

#import "OEXMockAnalyticsTracker.h"

@implementation OEXMockAnalyticsEventRecord
@end

@implementation OEXMockAnalyticsScreenRecord
@end

@interface OEXMockAnalyticsTracker ()

@property (strong, nonatomic) NSMutableArray* events;

@end

@implementation OEXMockAnalyticsTracker

- (id)init {
    self = [super init];
    if(self != nil) {
        self.events = [[NSMutableArray alloc] init];
    }
    return self;
}

- (void)identifyUser:(OEXUserDetails *)user {
    self.currentUser = user;
}

- (void)clearIdentifiedUser {
    self.currentUser = nil;
}

- (void)trackEvent:(OEXAnalyticsEvent *)event forComponent:(NSString *)component withProperties:(NSDictionary *)properties {
    OEXMockAnalyticsEventRecord* record = [[OEXMockAnalyticsEventRecord alloc] init];
    record.event = event;
    record.component = component;
    record.properties = properties;
    [self.events addObject:record];
}

- (void)trackScreenWithName:(NSString *)screenName courseID:(nullable NSString *)courseID value:(nullable NSString *)value additionalInfo:(nullable NSDictionary *)info {
    OEXMockAnalyticsScreenRecord* record = [[OEXMockAnalyticsScreenRecord alloc] init];
    record.screenName = screenName;
    record.value = value;
    record.courseID = courseID;
    record.additionalInfo = info;
    [self.events addObject:record];
}

- (NSArray*)observedEvents {
    return self.events.copy;
}

@end