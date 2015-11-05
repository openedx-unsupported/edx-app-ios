//
//  OEXPushNotificationProcessorTests.m
//  edX
//
//  Created by Akiva Leffert on 4/17/15.
//  Copyright (c) 2015 edX. All rights reserved.
//
#import "edX-Swift.h"
#import <OCMock/OCMock.h>
#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>

#import "OEXAnalytics.h"
#import "OEXAnalyticsData.h"
#import "OEXMockAnalyticsTracker.h"
#import "OEXPushNotificationProcessor.h"
#import "OEXRouter.h"

@interface OEXMockApplicationPushProcessing : NSObject

@property (strong, nonatomic) NSMutableArray* presentedNotifications;

@property (assign, nonatomic) UIApplicationState applicationState;

@end

@implementation OEXMockApplicationPushProcessing

- (void)presentLocalNotificationNow:(UILocalNotification*)notification {
    if(self.presentedNotifications == nil) {
        self.presentedNotifications = [[NSMutableArray alloc] init];
    }
    [self.presentedNotifications addObject:notification];
}

@end

@interface OEXPushNotificationProcessorTests : XCTestCase

@property (strong, nonatomic) OCMockObject* applicationClassMock;
@property (strong, nonatomic) OEXMockApplicationPushProcessing* mockApplication;
@property (strong, nonatomic) OEXAnalytics* analytics;
@property (strong, nonatomic) OEXMockAnalyticsTracker* tracker;

@end

@implementation OEXPushNotificationProcessorTests

- (void)setUp {
    self.applicationClassMock = OCMStrictClassMock([UIApplication class]);
    self.mockApplication = [[OEXMockApplicationPushProcessing alloc] init];
    
    id applicationStub = [self.applicationClassMock stub];
    [applicationStub sharedApplication];
    [applicationStub andReturn:self.mockApplication];
    
    self.analytics = [[OEXAnalytics alloc] init];
    self.tracker = [[OEXMockAnalyticsTracker alloc] init];
    [self.analytics addTracker:self.tracker];
}

- (void)tearDown {
    [self.applicationClassMock stopMocking];
    self.applicationClassMock = nil;
    self.mockApplication = nil;
}

- (void)testIgnoreUnknownAction {
    self.mockApplication.applicationState = UIApplicationStateBackground;
    
    OEXPushNotificationProcessorEnvironment* environment = [[OEXPushNotificationProcessorEnvironment alloc] initWithAnalytics:self.analytics router:nil];
    OEXPushNotificationProcessor* processor = [[OEXPushNotificationProcessor alloc] initWithEnvironment:environment];
    
    NSDictionary* userInfo = [processor t_exampleUnknownActionUserInfo];
    [processor didReceiveRemoteNotificationWithUserInfo:userInfo];
    
    XCTAssertEqual(self.mockApplication.presentedNotifications.count, 0);
}

- (void)testReroutingBackground {
    self.mockApplication.applicationState = UIApplicationStateBackground;
    
    OEXPushNotificationProcessorEnvironment* environment = [[OEXPushNotificationProcessorEnvironment alloc] initWithAnalytics:self.analytics router:nil];
    OEXPushNotificationProcessor* processor = [[OEXPushNotificationProcessor alloc] initWithEnvironment:environment];
    
    NSDictionary* userInfo = [processor t_exampleKnownActionUserInfo];
    [processor didReceiveRemoteNotificationWithUserInfo:userInfo];
    
    XCTAssertEqual(self.mockApplication.presentedNotifications.count, 1);
    
    UILocalNotification* notification = [[self.mockApplication presentedNotifications] firstObject];
    XCTAssertNotNil(notification.alertBody);
    XCTAssertEqualObjects(notification.userInfo, userInfo);
}

- (void)testReroutingForeground {
    self.mockApplication.applicationState = UIApplicationStateActive;
    
    OEXPushNotificationProcessorEnvironment* environment = [[OEXPushNotificationProcessorEnvironment alloc] initWithAnalytics:nil router:nil];
    OEXPushNotificationProcessor* processor = [[OEXPushNotificationProcessor alloc] initWithEnvironment:environment];
    
    NSDictionary* userInfo = [processor t_exampleKnownActionUserInfo];
    [processor didReceiveRemoteNotificationWithUserInfo:userInfo];
    
    XCTAssertEqual(self.mockApplication.presentedNotifications.count, 0);
}

- (void)testAnnouncementsAnalyticsBackground {
    self.mockApplication.applicationState = UIApplicationStateBackground;
    OEXCourse* course = [OEXCourse accessibleTestCourse];
    
    OEXPushNotificationProcessorEnvironment* environment = [[OEXPushNotificationProcessorEnvironment alloc] initWithAnalytics:self.analytics router:nil];
    OEXPushNotificationProcessor* processor = [[OEXPushNotificationProcessor alloc] initWithEnvironment:environment];
    NSDictionary* userInfo = [processor t_announcementUserInfoWithCourseName:course.name courseID:course.course_id];
    [processor didReceiveRemoteNotificationWithUserInfo:userInfo];
    
    XCTAssertEqual(self.tracker.observedEvents.count, 1);
    OEXMockAnalyticsEventRecord* event = [self.tracker.observedEvents firstObject];
    XCTAssertNotNil(event);
    XCTAssertEqualObjects(event.event.name, OEXAnalyticsEventAnnouncementNotificationReceived);
    XCTAssertEqualObjects(event.event.displayName, OEXAnalyticsEventAnnouncementNotificationReceived);
    XCTAssertEqualObjects(event.event.category, OEXAnalyticsCategoryNotifications);
}

- (void)testRoutingAnnouncementsForeground {
    OEXCourse* course = [OEXCourse accessibleTestCourse];
    
    id routerMock = OCMStrictClassMock([OEXRouter class]);
    [[routerMock expect] showAnnouncementsForCourseWithID:course.course_id];
    
    OEXPushNotificationProcessorEnvironment* environment = [[OEXPushNotificationProcessorEnvironment alloc] initWithAnalytics:self.analytics router:routerMock];
    OEXPushNotificationProcessor* processor = [[OEXPushNotificationProcessor alloc] initWithEnvironment:environment];
    NSDictionary* userInfo = [processor t_announcementUserInfoWithCourseName:course.name courseID:course.course_id];
    [processor didReceiveLocalNotificationWithUserInfo:userInfo];
    
    OCMVerifyAll(routerMock);
    [routerMock stopMocking];
    
    XCTAssertEqual(self.tracker.observedEvents.count, 1);
    OEXMockAnalyticsEventRecord* event = [self.tracker.observedEvents firstObject];
    XCTAssertNotNil(event);
    XCTAssertEqualObjects(event.event.name, OEXAnalyticsEventAnnouncementNotificationTapped);
    XCTAssertEqualObjects(event.event.displayName, OEXAnalyticsEventAnnouncementNotificationTapped);
    XCTAssertEqualObjects(event.event.category, OEXAnalyticsCategoryNotifications);
}

@end
