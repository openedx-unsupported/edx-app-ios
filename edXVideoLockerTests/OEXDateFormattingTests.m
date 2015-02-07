//
//  OEXDateFormattingTests.m
//  edXVideoLocker
//
//  Created by Akiva Leffert on 1/27/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>

#import "OEXDateFormatting.h"

@interface OEXDateFormattingTests : XCTestCase

@end

@implementation OEXDateFormattingTests

- (void)testZero {
    XCTAssertEqualObjects(@"00:00", [OEXDateFormatting formatSecondsAsVideoLength:0]);
}

- (void)testUnderHour {
    XCTAssertEqualObjects(@"59:59", [OEXDateFormatting formatSecondsAsVideoLength:61 * 59]);
}

- (void)testOverHour {
    XCTAssertEqualObjects(@"01:00:00", [OEXDateFormatting formatSecondsAsVideoLength:60 * 60]);
}

- (void)testLong {
    XCTAssertEqualObjects(@"35:00:10", [OEXDateFormatting formatSecondsAsVideoLength:60 * 60 * 35 + 10]);
}

- (void)testValidDateString {
    NSDate* date = [OEXDateFormatting dateWithServerString:@"2014-11-06T20:16:45Z"];
    NSDateComponents* components = [[NSCalendar currentCalendar] components:NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay | NSCalendarUnitMinute | NSCalendarUnitHour | NSCalendarUnitSecond fromDate:date];
    XCTAssertEqual(components.year, 2014);
    XCTAssertEqual(components.month, 11);
    XCTAssertEqual(components.day, 6);
    XCTAssertEqual(components.hour, 20);
    XCTAssertEqual(components.minute, 16);
    XCTAssertEqual(components.second, 45);
}

- (void)testNilDateString {
    XCTAssertNil([OEXDateFormatting dateWithServerString:nil]);
}

@end
