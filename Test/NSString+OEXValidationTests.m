//
//  NSString+OEXValidationTests.m
//  edXVideoLocker
//
//  Created by Akiva Leffert on 1/26/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "NSString+OEXValidation.h"

@interface NSString_OEXValidationTests : XCTestCase

@end

@implementation NSString_OEXValidationTests

- (void)testBasic {
    XCTAssertTrue([@"staff@example.com" oex_isValidEmailAddress]);
}

- (void)testSubdomains {
    XCTAssertTrue([@"staff@foo.example.com" oex_isValidEmailAddress]);
}

- (void)testPlus {
    XCTAssertTrue([@"staff+test@foo.example.com" oex_isValidEmailAddress]);
}

- (void)testIncompleteDomain {
    XCTAssertFalse([@"staff@foo" oex_isValidEmailAddress]);
}

- (void)testNoDomain {
    XCTAssertFalse([@"staff@" oex_isValidEmailAddress]);
}

- (void)testJustUser {
    XCTAssertFalse([@"staff@" oex_isValidEmailAddress]);
}

- (void)testUnicode {
    XCTAssertTrue([@"staff@😁.😭" oex_isValidEmailAddress]);
}

- (void)testEmpty {
    XCTAssertFalse([@"" oex_isValidEmailAddress]);
}

@end
