//
//  NSDate+OEXComparisonsTests.m
//  edXVideoLocker
//
//  Created by Akiva Leffert on 1/27/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>

#import "NSDate+OEXComparisons.h"

@interface NSDate_OEXComparisonsTests : XCTestCase

@end

@implementation NSDate_OEXComparisonsTests

- (void)testPastDate {
    NSDate* pastDate = [[NSDate date] dateByAddingTimeInterval:-1000];
    XCTAssertTrue([pastDate oex_isInThePast]);
}

- (void)testFutureDate {
    NSDate* futureDate = [[NSDate date] dateByAddingTimeInterval:3000];
    XCTAssertFalse([futureDate oex_isInThePast]);
}

@end
