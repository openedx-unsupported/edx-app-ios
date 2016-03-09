//
//  NSString+OEXFormatting.m
//  edXVideoLocker
//
//  Created by Akiva Leffert on 3/17/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>

@import edXCore;

@interface NSString_OEXFormattingTests : XCTestCase

@end

@implementation NSString_OEXFormattingTests

- (void)testFormatNoParams {
    NSString* format = @"some string with { stuff in it";
    NSString* result = [NSString oex_stringWithFormat:format parameters:@{}];
    XCTAssertEqualObjects(result, format);
}

- (void)testFormatSingleReplacement {
    NSString* format = @"{param} string with {param} stuff in it";
    NSString* result = [NSString oex_stringWithFormat:format parameters:@{@"param" : @"some"}];
    XCTAssertEqualObjects(result, @"some string with some stuff in it");
}

- (void)testNumericReplacement {
    NSString* format = @"{count} strings";
    NSString* result = [NSString oex_stringWithFormat:format parameters:@{@"count" : @5}];
    XCTAssertEqualObjects(result, @"5 strings");
}

- (void)testFormatMultipleReplacement {
    NSString* format = @"{param} {arg} with {param} {arg} in it";
    NSString* result = [NSString oex_stringWithFormat:format parameters:@{@"param" : @"some", @"arg" : @"string"}];
    XCTAssertEqualObjects(result, @"some string with some string in it");
}

- (void)testSubstituteInSubstition {
    NSString* format = @"{param} stuff";
    NSString* result = [format oex_formatWithParameters:@{@"param" : @"{local_name}"}];
    XCTAssertEqualObjects(result, @"{local_name} stuff");
}

// These tests will only assert on DEBUG builds
// As validation will fail silently on RELEASE builds
#if DEBUG

- (void)testMissingArgument {
    NSString* format = @"{param} {arg} with {param} {arg} in it";
    XCTAssertThrows([NSString oex_stringWithFormat:format parameters:@{@"param" : @"some"}]);
}

- (void)testExtraParameter {
    NSString* format = @"{arg} some text";
    XCTAssertThrows([NSString oex_stringWithFormat:format parameters:@{}]);
}

#endif

@end
