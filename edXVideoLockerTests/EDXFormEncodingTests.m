//
//  EDXFormEncodingTests.m
//  edXVideoLocker
//
//  Created by Akiva Leffert on 11/4/14.
//  Copyright (c) 2014 edX. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>

#import "NSString+EDXEncoding.h"
#import "NSDictionary+EDXEncoding.h"

@interface EDXFormEncodingTests : XCTestCase

@end

@implementation EDXFormEncodingTests

- (void)testStringEncoding {
    NSString* string = @"akiva=something+someone and whatever@#@$%%";
    NSString* encoded = [string edx_stringByUsingFormEncoding];
    NSString* expected = @"akiva%3Dsomething%2Bsomeone+and+whatever%40%23%40%24%25%25";
    XCTAssertTrue([expected isEqual: encoded]);
}

- (void)testAlphanumericDictionary {
    NSDictionary* args = @{@"foo" : @"bar"};
    NSString* encoded = [args edx_stringByUsingFormEncoding];
    NSString* expected = @"foo=bar";
    XCTAssertTrue([expected isEqual: encoded]);
}

- (void)testJoiningDictionary {
    NSDictionary* args = @{@"foo" : @"some&text", @"baz" : @"some other=text"};
    NSString* encoded = [args edx_stringByUsingFormEncoding];
    /// Try both options to account for the unordered nature of dictionaries
    NSArray* expected = @[@"foo=some%26text&baz=some+other%3Dtext", @"baz=some+other%3Dtext&foo=some%26text"];
    XCTAssertTrue([expected containsObject: encoded]);
}





@end
