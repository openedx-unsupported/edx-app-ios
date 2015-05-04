//
//  UIBarButtonItem+OEXBlockActionsTests.m
//  edX
//
//  Created by Akiva Leffert on 5/4/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>

#import "OEXRemovable.h"
#import "UIBarButtonItem+OEXBlockActions.h"

@interface UIBarButtonItem_OEXBlockActionsTests : XCTestCase

@end

@implementation UIBarButtonItem_OEXBlockActionsTests

- (void)testAddAction {
    UIBarButtonItem* item = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:nil action:nil];
    __block BOOL fired = NO;
    [item oex_setAction:^ {
        fired = YES;
    }];
    
    // performSelector confuses ARC since it needs the method name to figure out the memory management behavior.
    // This case is super simple and in a test so we just ignore the warning
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    [item.target performSelector:item.action withObject:item];
#pragma clang diagnostic pop
    
    XCTAssertNotNil(item.target);
    XCTAssertTrue(fired);
}

- (void)testRemoveAction {
    UIBarButtonItem* item = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:nil action:nil];
    __block BOOL fired = NO;
    id <OEXRemovable> action = [item oex_setAction: ^{
        fired = YES;
    }];
    [action remove];
    
    XCTAssertNil(item.target);
    XCTAssertEqual(item.action, NULL);
    XCTAssertFalse(fired);
}

@end
