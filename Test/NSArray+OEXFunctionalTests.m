//
//  NSArray+OEXFunctionalTests.m
//  edXVideoLocker
//
//  Created by Akiva Leffert on 1/20/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>

#import "NSArray+OEXFunctional.h"

@interface NSArray_OEXFunctionalTests : XCTestCase

@end

@implementation NSArray_OEXFunctionalTests

- (void)testMap {
    NSArray* array = @[@1, @2, @3];
    NSArray* result = [array oex_map:^(NSNumber* object) {
        NSUInteger i = object.integerValue;
        return i > 1 ? @(i + 5) : nil;
    }];
    
    NSArray* expected = @[@7, @8];
    XCTAssertEqualObjects(result, expected);
}

- (void)testGenerate {
    NSArray* generated = [NSArray oex_arrayWithCount:4 generator:^id(NSUInteger index) {
        return @(index);
    }];
    NSArray* expected = @[@0, @1, @2, @3];
    XCTAssertEqualObjects(generated, expected);
}

@end
