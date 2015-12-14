//
//  OEXStatusMessageViewControllerTests.m
//  edXVideoLocker
//
//  Created by Akiva Leffert on 3/18/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>

#import "NSString+TestExamples.h"

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
    [statusController showMessage:[NSString oex_longTestString] onViewController:testController];
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

- (void)testStableOrdering {
    OEXStatusMessageViewController* statusController = [[OEXStatusMessageViewController alloc] initWithNibName:nil bundle:nil];
    OEXStatusMessageTestController* testController = [[OEXStatusMessageTestController alloc] initWithNibName:nil bundle:nil];
    testController.view.frame = CGRectMake(0, 0, 300, 500);
    
    UIView* subview = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 20, 20)];
    [testController.view addSubview:subview];
    
    UIView* overlayView1 = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 30, 30)];
    [testController.view addSubview:overlayView1];
    
    UIView* overlayView2 = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 30, 30)];
    [testController.view addSubview:overlayView2];
    testController.overlayViews = @[overlayView2, overlayView1];
    
    [statusController showMessage:@"test" onViewController:testController];
    XCTAssertFalse([statusController t_isStatusViewBelowView:subview]);
    XCTAssertTrue([statusController t_isStatusViewBelowView:overlayView1]);
    XCTAssertTrue([statusController t_isStatusViewBelowView:overlayView2]);
    XCTAssertLessThan([testController.view.subviews indexOfObject:overlayView1], [testController.view.subviews indexOfObject:overlayView2]);
}

@end
