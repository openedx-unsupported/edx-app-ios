//
//  NSNotificationCenter+OEXSafeAccessTests.m
//  edXVideoLocker
//
//  Created by Akiva Leffert on 3/30/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>

#import "NSObject+OEXDeallocAction.h"
#import "NSNotificationCenter+OEXSafeAccess.h"
#import "OEXRemovable.h"


static NSString* OEXSampleNotification = @"OEXSampleNotification";

@interface NSNotificationCenter_OEXSafeAccessTests : XCTestCase

@end

@implementation NSNotificationCenter_OEXSafeAccessTests

- (void)testActionFires {
    NSObject* owner = [[NSObject alloc] init];
    __block BOOL fired = NO;
    [[NSNotificationCenter defaultCenter] oex_addObserver:owner notification:OEXSampleNotification action:^(NSNotification *notification, id observer, id<OEXRemovable> removable) {
        fired = YES;
    }];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:OEXSampleNotification object:nil];
    XCTAssertTrue(fired);
}

- (void)testClearedOnDealloc {
    __block BOOL fired = NO;
    __block BOOL dealloced = NO;
    void(^make)(void) = ^{
        @autoreleasepool {
            NSObject* owner = [[NSObject alloc] init];
            [[NSNotificationCenter defaultCenter] oex_addObserver:owner notification:OEXSampleNotification action:^(NSNotification *notification, id observer, id<OEXRemovable> removable) {
                fired = YES;
            }];
            [owner oex_performActionOnDealloc:^{
                dealloced = YES;
            }];
        };
    };
    make();
    
    [[NSNotificationCenter defaultCenter] postNotificationName:OEXSampleNotification object:nil];
    XCTAssertFalse(fired);
    XCTAssertTrue(dealloced);
}

- (void)testRemove {
    __block BOOL fired = NO;
    
    NSObject* owner = [[NSObject alloc] init];
    id <OEXRemovable> removable = [[NSNotificationCenter defaultCenter] oex_addObserver:owner notification:OEXSampleNotification action:^(NSNotification *notification, id observer, id<OEXRemovable> removable) {
        fired = YES;
    }];
    [removable remove];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:OEXSampleNotification object:nil];
    XCTAssertFalse(fired);
}



@end
