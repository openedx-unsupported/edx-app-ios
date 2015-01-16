//
//  EdxInterFaceTests.m
//  edXVideoLocker
//
//  Created by Abhishek Bhagat on 19/11/14.
//  Copyright (c) 2014 edX. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>

#import "OEXInterface.h"
@interface EdxInterFaceTests : XCTestCase
{
    OEXInterface *inteface;
    
}
@end

@implementation EdxInterFaceTests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
    inteface=[OEXInterface sharedInterface];
    
    
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testExample {
    // This is an example of a functional test case.
    XCTAssert(YES, @"Pass");
}

- (void)testPerformanceExample {
    // This is an example of a performance test case.
    [self measureBlock:^{
        // Put the code you want to measure the time of here.
    }];
}

@end
