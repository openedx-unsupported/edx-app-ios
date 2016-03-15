//
//  NSObject+OEXDeallocActionTests.m
//  edXVideoLocker
//
//  Created by Akiva Leffert on 3/30/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

#import <XCTest/XCTest.h>

@import edXCore;

@interface NSObject_OEXDeallocActionTests : XCTestCase

@end

@implementation NSObject_OEXDeallocActionTests
- (void)testDealloc {
    __block BOOL observed = NO;
    void (^make)(void) = ^{
        @autoreleasepool {
            NSObject* object = [[NSObject alloc] init];
            [object oex_performActionOnDealloc:^{
                observed = YES;
            }];
        }
    };
    
    make();
    XCTAssertTrue(observed);
}

- (void)testStillAlive {
    __block BOOL observed = NO;
    
    NSObject* object = [[NSObject alloc] init];
    [object oex_performActionOnDealloc: ^{
        observed = YES;
    }];
    
    XCTAssertFalse(observed);
}

- (void)testManualRemove {
    __block BOOL observed = NO;
    void (^make)(void) = ^{
        @autoreleasepool {
            NSObject* object = [[NSObject alloc] init];
            id <OEXRemovable> removable = [object oex_performActionOnDealloc:^{
                observed = YES;
            }];
            [removable remove];
        }
    };
    make();
    XCTAssertFalse(observed);
}

@end
