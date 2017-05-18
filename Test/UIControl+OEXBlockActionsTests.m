//
//  UIControl+OEXBlockActionsTests.m
//  edX
//
//  Created by Akiva Leffert on 4/28/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>

#import "UIControl+OEXBlockActions.h"
#import "OEXRemovable.h"

@interface UIControl_OEXBlockActionsTests : XCTestCase

@end

@implementation UIControl_OEXBlockActionsTests

- (void)testAddAction {
    UIButton* button = [UIButton buttonWithType:UIButtonTypeCustom];
    __block BOOL fired = NO;
    [button oex_addAction:^(NSObject* control) {
        fired = YES;
    } forEvents:UIControlEventTouchUpInside];
    
    [button sendActionsForControlEvents:UIControlEventTouchUpInside];
    XCTAssertTrue(fired);
}

- (void)testRemoveAction {
    UIButton* button = [UIButton buttonWithType:UIButtonTypeCustom];
    __block BOOL fired = NO;
    id <OEXRemovable> action = [button oex_addAction:^(NSObject* control) {
        fired = YES;
    } forEvents:UIControlEventTouchUpInside];
    
    [action remove];
    
    [button sendActionsForControlEvents:UIControlEventTouchUpInside];
    XCTAssertFalse(fired);
}

@end
