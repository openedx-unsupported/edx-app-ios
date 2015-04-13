//
//  NSObject+OEXReplaceNulls.m
//  edXVideoLocker
//
//  Created by Akiva Leffert on 1/21/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "NSObject+OEXReplaceNull.h"

@interface NSObject_OEXReplaceNullTests : XCTestCase
@end

@implementation NSObject_OEXReplaceNullTests

- (void)testString {
    NSString* sample = @"foo";
    XCTAssertEqualObjects(sample, [sample oex_replaceNullsWithEmptyStrings]);
}

- (void)testNumber {
    NSNumber* sample = @23;
    XCTAssertEqualObjects(sample, [sample oex_replaceNullsWithEmptyStrings]);
}

- (void)testArrayNoNulls {
    NSArray* sample = @[@1, @"foo", @23];
    XCTAssertEqualObjects(sample, [sample oex_replaceNullsWithEmptyStrings]);
}

- (void)testArrayNulls {
    NSArray* sample = @[@1, [NSNull null], @"foo"];
    NSArray* expectation = @[@1, @"", @"foo"];
    XCTAssertEqualObjects(expectation, [sample oex_replaceNullsWithEmptyStrings]);
}

- (void)testArrayRecursion {
    NSArray* sample = @[@1, @{@"foo" : [NSNull null]}, @"foo"];
    NSArray* expectation = @[@1, @{@"foo" : @""}, @"foo"];
    XCTAssertEqualObjects(expectation, [sample oex_replaceNullsWithEmptyStrings]);
}

- (void)testDictionaryNoNulls {
    NSDictionary* sample = @{
                             @"foo" : @"bar",
                             @"bar" : @1
                             };
    XCTAssertEqualObjects(sample, [sample oex_replaceNullsWithEmptyStrings]);
}

- (void)testDictionaryNulls {
    NSDictionary* sample = @{
                             @"foo" : @"bar",
                             @"bar" : [NSNull null]
                             };
    NSDictionary* expectation = @{
                                  @"foo" : @"bar",
                                  @"bar" : @""
                                  };
    XCTAssertEqualObjects(expectation, [sample oex_replaceNullsWithEmptyStrings]);
}

- (void)testDictionaryRecursion {
    NSDictionary* sample = @{@"foo" : @1, @"bar" : @[@"foo", [NSNull null]]};
    NSDictionary* expectation = @{@"foo" : @1, @"bar" : @[@"foo", @""]};
    XCTAssertEqualObjects(expectation, [sample oex_replaceNullsWithEmptyStrings]);
}

@end
