//
//  OEXApplicationTests.m
//  edXVideoLocker
//
//  Created by Akiva Leffert on 4/9/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>

#import "OEXApplication.h"
#import <OCMock/OCMock.h>

@interface OEXApplicationTests : XCTestCase

@end

@implementation OEXApplicationTests

- (void)testApplicationSubclassBeingUsed {
    OEXApplication* application = [OEXApplication oex_sharedApplication];
    XCTAssertNotNil(application);
}

- (void)testURLIntercepting {
    NSURL* url = [[NSURL alloc] initWithString:@"http://test/index.html"];
    
    __block BOOL intercepted = NO;
    __block NSURL* interceptedURL = nil;
    [[OEXApplication oex_sharedApplication] interceptURLsWithHandler:^BOOL(NSURL *url) {
        intercepted = YES;
        interceptedURL = url;
        return YES;
    } whileExecuting:^{
        [[UIApplication sharedApplication] openURL:url];
    }];
    
    XCTAssertTrue(intercepted);
    XCTAssertEqualObjects(url, interceptedURL);
}

- (void)testURLInterceptNestingPassthrough {
    NSURL* url = [[NSURL alloc] initWithString:@"http://test/index.html"];
    __block BOOL intercepted = NO;
    [[OEXApplication oex_sharedApplication] interceptURLsWithHandler:^BOOL(NSURL *url) {
        intercepted = YES;
        return YES;
    } whileExecuting:^{
        [[OEXApplication oex_sharedApplication] interceptURLsWithHandler:^BOOL(NSURL *url) {
            return NO;
        } whileExecuting:^{
            
        }];
        [[UIApplication sharedApplication] openURL:url];
    }];
    XCTAssertTrue(intercepted);
}

- (void)testURLInterceptNestingIntercepted {
    NSURL* url = [[NSURL alloc] initWithString:@"http://test/index.html"];
    __block BOOL intercepted = NO;
    [[OEXApplication oex_sharedApplication] interceptURLsWithHandler:^BOOL(NSURL *url) {
        intercepted = YES;
        return YES;
    } whileExecuting:^{
        [[OEXApplication oex_sharedApplication] interceptURLsWithHandler:^BOOL(NSURL *url) {
            return YES;
        } whileExecuting:^{
            [[UIApplication sharedApplication] openURL:url];
        }];
    }];
    XCTAssertFalse(intercepted);
}


@end
