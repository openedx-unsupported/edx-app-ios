//
//  OEXSafeCastTests.m
//  edXVideoLocker
//
//  Created by Akiva Leffert on 3/27/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>

@interface OEXSafeCastTests : XCTestCase

@end

@implementation OEXSafeCastTests

- (void)testValidClassCast {
    NSObject* object = [[NSObject alloc] init];
    NSObject* cast = OEXSafeCastAsClass(object, NSObject);
    XCTAssertNotNil(cast);
}

- (void)testInvalidClassCast {
    NSArray* obj = [[NSMutableArray alloc] init];
    NSString* cast = OEXSafeCastAsClass(obj, NSString);
    XCTAssertNil(cast);
}

- (void)testDowncastClassCast {
    NSMutableArray* array = [[NSMutableArray alloc] init];
    NSArray* up = array;
    NSMutableArray* cast = OEXSafeCastAsClass(up, NSMutableArray);
    XCTAssertNotNil(cast);
}

- (void)testValidProtocolCast {
    NSArray* obj = [[NSArray alloc] init];
    id <NSCopying> cast = OEXSafeCastAsProtocol(obj, NSCopying);
    XCTAssertNotNil(cast);
}

- (void)testInvalidProtocolCast {
    NSObject* obj = [[NSObject alloc] init];
    id <NSCopying> cast = OEXSafeCastAsProtocol(obj, NSCopying);
    XCTAssertNil(cast);
}

@end
