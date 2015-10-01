//
//  OEXRouterTests.m
//  edX
//
//  Created by Akiva Leffert on 4/23/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <OCMock/OCMock.h>
#import <XCTest/XCTest.h>

#import "OEXAccessToken.h"
#import "OEXCourse+OEXTestDataFactory.h"
#import "OEXInterface.h"
#import "OEXMockCredentialStorage.h"
#import "OEXRouter.h"
#import "OEXSession.h"
#import "OEXUserDetails+OEXTestDataFactory.h"

@interface OEXRouterTests : XCTestCase

@property (strong, nonatomic) OEXSession* loggedInSession;

@end

@implementation OEXRouterTests

- (void)setUp {
    id <OEXCredentialStorage> credentialStore = [[OEXMockCredentialStorage alloc] init];
    [credentialStore saveAccessToken:[[OEXAccessToken alloc] init] userDetails:[OEXUserDetails freshUser]];
    self.loggedInSession = [[OEXSession alloc] initWithCredentialStore:credentialStore];
    [self.loggedInSession loadTokenFromStore];
}

- (void)testShowSplashWhenLoggedOut {
    OEXRouterEnvironment* environment = [[OEXRouterEnvironment alloc] initWithAnalytics:nil config:nil dataManager:nil interface:nil session:nil styles:nil networkManager:nil];
    OEXRouter* router = [[OEXRouter alloc] initWithEnvironment:environment];
    [router openInWindow:nil];
    XCTAssertTrue(router.t_showingLogin);
    XCTAssertNil(router.t_navigationHierarchy);
}

- (void)testShowContentWhenLoggedIn {
    OEXRouterEnvironment* environment = [[OEXRouterEnvironment alloc] initWithAnalytics:nil config:nil dataManager:nil interface:nil session:self.loggedInSession styles:nil networkManager:nil];
    OEXRouter* router = [[OEXRouter alloc] initWithEnvironment:environment];
    [router openInWindow:nil];
    XCTAssertFalse(router.t_showingLogin);
    XCTAssertNotNil(router.t_navigationHierarchy);
}

- (void)testRearViewExists {
    OEXRouterEnvironment* environment = [[OEXRouterEnvironment alloc] initWithAnalytics:nil config:nil dataManager:nil interface:nil session:self.loggedInSession styles:nil networkManager:nil];
    OEXRouter* router = [[OEXRouter alloc] initWithEnvironment:environment];
    [router openInWindow:nil];
    XCTAssertTrue(router.t_hasRearController);
}

- (id)mockInterfaceWithCourses:(NSArray*)courses {
    OCMockObject* interface = OCMStrictClassMock([OEXInterface class]);
    for(OEXCourse* course in courses) {
        id stub = [interface stub];
        [stub courseWithID:course.course_id];
        [stub andReturn:course];
    }
    return interface;
}

- (void)testShowNewAnnouncement {
    OEXCourse* course = [OEXCourse freshCourse];
    id interface = [self mockInterfaceWithCourses:@[course]];
    OEXRouterEnvironment* environment = [[OEXRouterEnvironment alloc] initWithAnalytics:nil config:nil dataManager:nil interface:interface session:self.loggedInSession styles:nil networkManager:nil];
    OEXRouter* router = [[OEXRouter alloc] initWithEnvironment:environment];
    [router openInWindow:nil];
    
    NSUInteger stackLength = [router t_navigationHierarchy].count;
    [router showAnnouncementsForCourseWithID:course.course_id];
    
    XCTAssertGreaterThan(router.t_navigationHierarchy.count, stackLength);
    
    [interface stopMocking];
}


- (void)testShowSameNewAnnouncement {
    OEXCourse* course = [OEXCourse freshCourse];
    id interface = [self mockInterfaceWithCourses:@[course]];
    OEXRouterEnvironment* environment = [[OEXRouterEnvironment alloc] initWithAnalytics:nil config:nil dataManager:nil interface:interface session:self.loggedInSession styles:nil networkManager:nil];
    OEXRouter* router = [[OEXRouter alloc] initWithEnvironment:environment];
    [router openInWindow:nil];
    
    NSUInteger stackLength = [router t_navigationHierarchy].count;
    [router showAnnouncementsForCourseWithID:course.course_id];
    
    XCTAssertGreaterThan(router.t_navigationHierarchy.count, stackLength);
    stackLength = router.t_navigationHierarchy.count;
    
    [router showAnnouncementsForCourseWithID:course.course_id];
    XCTAssertEqual(router.t_navigationHierarchy.count, stackLength);
    
    [interface stopMocking];
}


- (void)testShowDifferentNewAnnouncement {
    OEXCourse* course = [OEXCourse freshCourse];
    OEXCourse* otherCourse = [OEXCourse freshCourse];
    id interface = [self mockInterfaceWithCourses:@[course, otherCourse]];
    OEXRouterEnvironment* environment = [[OEXRouterEnvironment alloc] initWithAnalytics:nil config:nil dataManager:nil interface:interface session:self.loggedInSession styles:nil networkManager:nil];
    OEXRouter* router = [[OEXRouter alloc] initWithEnvironment:environment];
    [router openInWindow:nil];
    
    NSUInteger stackLength = [router t_navigationHierarchy].count;
    [router showAnnouncementsForCourseWithID:course.course_id];
    
    XCTAssertGreaterThan(router.t_navigationHierarchy.count, stackLength);
    
    stackLength = router.t_navigationHierarchy.count;
    [router showAnnouncementsForCourseWithID:otherCourse.course_id];
    XCTAssertGreaterThan(router.t_navigationHierarchy.count, stackLength);
    
    [interface stopMocking];
}


@end
