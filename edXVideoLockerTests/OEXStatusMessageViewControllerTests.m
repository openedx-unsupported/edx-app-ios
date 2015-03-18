//
//  OEXStatusMessageViewControllerTests.m
//  edXVideoLocker
//
//  Created by Akiva Leffert on 3/18/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>

#import "OEXStatusMessageViewController.h"

@interface OEXStatusMessageTestController : UIViewController <OEXStatusMessageControlling>

@property (copy, nonatomic) NSArray* overlayViews;

@end

@implementation OEXStatusMessageTestController

- (CGFloat)verticalOffsetForStatusController:(OEXStatusMessageViewController *)controller {
    return 0;
}

- (NSArray*)overlayViewsForStatusController:(OEXStatusMessageViewController *)controller {
    return self.overlayViews;
}

@end

@interface OEXStatusMessageViewControllerTests : XCTestCase

@end

@implementation OEXStatusMessageViewControllerTests

- (void)testRegularMessage {
    OEXStatusMessageViewController* statusController = [[OEXStatusMessageViewController alloc] initWithNibName:nil bundle:nil];
    OEXStatusMessageTestController* testController = [[OEXStatusMessageTestController alloc] initWithNibName:nil bundle:nil];
    testController.view.frame = CGRectMake(0, 0, 300, 500);
    [statusController showMessage:@"test" onViewController:testController];
    XCTAssertTrue([statusController t_doesMessageTextFit]);
}


- (void)testLongMessage {
    OEXStatusMessageViewController* statusController = [[OEXStatusMessageViewController alloc] initWithNibName:nil bundle:nil];
    OEXStatusMessageTestController* testController = [[OEXStatusMessageTestController alloc] initWithNibName:nil bundle:nil];
    testController.view.frame = CGRectMake(0, 0, 300, 500);
    [statusController showMessage:@"Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur" onViewController:testController];
    XCTAssertTrue([statusController t_doesMessageTextFit]);
}

- (void)testOverlay {
    OEXStatusMessageViewController* statusController = [[OEXStatusMessageViewController alloc] initWithNibName:nil bundle:nil];
    OEXStatusMessageTestController* testController = [[OEXStatusMessageTestController alloc] initWithNibName:nil bundle:nil];
    testController.view.frame = CGRectMake(0, 0, 300, 500);
    
    UIView* subview = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 20, 20)];
    [testController.view addSubview:subview];
    
    UIView* overlayView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 30, 30)];
    [testController.view addSubview:overlayView];
    testController.overlayViews = @[overlayView];
    
    [statusController showMessage:@"test" onViewController:testController];
    XCTAssertFalse([statusController t_isStatusViewBelowView:subview]);
    XCTAssertTrue([statusController t_isStatusViewBelowView:overlayView]);
}

@end
