//
//  OEXCourseDashboardViewControllerTests.m
//  edX
//
//  Created by Akiva Leffert on 4/28/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>

#import "OEXCourseDashboardViewController.h"

#import "OEXConfig.h"

@interface OEXDashboardStubConfig : OEXConfig

@property (assign, nonatomic) BOOL shouldEnableDiscussions;

@end

@implementation OEXDashboardStubConfig
@end

@interface OEXCourseDashboardViewControllerTests : XCTestCase

@end

@implementation OEXCourseDashboardViewControllerTests

- (BOOL)discussionsVisibleWhenEnabled:(BOOL)enabled {
    OEXDashboardStubConfig* config = [[OEXDashboardStubConfig alloc] initWithDictionary:@{}];
    config.shouldEnableDiscussions = enabled;
    OEXCourseDashboardViewControllerEnvironment* environment = [[OEXCourseDashboardViewControllerEnvironment alloc] initWithConfig:config router:nil];
    OEXCourseDashboardViewController* controller = [[OEXCourseDashboardViewController alloc] initWithEnvironment:environment course:nil];
    
    (void)controller.view; // Force view to load
    
    return [controller t_canVisitDicussions];
}

- (void)testDiscussionsEnabled {
    XCTAssertTrue([self discussionsVisibleWhenEnabled:YES]);
}

- (void)testDiscussionsDisabled {
    XCTAssertFalse([self discussionsVisibleWhenEnabled:NO]);
}

@end
