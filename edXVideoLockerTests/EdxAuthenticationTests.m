//
//  EdxAuthenticationTests.m
//  edXVideoLocker
//
//  Created by Abhishek Bhagat on 24/11/14.
//  Copyright (c) 2014 edX. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import "FBSocial.h"
#import "EdxAuthentication.h"
@interface EdxAuthenticationTests : XCTestCase{
    BOOL done;
}@end

@implementation EdxAuthenticationTests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
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

-(void)saveAccessToken:(NSString *)token{
    if([[NSUserDefaults standardUserDefaults] objectForKey:@"authTokenResponse"]){
        [[NSUserDefaults standardUserDefaults]removeObjectForKey:@"authTokenResponse"];
    }
    [[NSUserDefaults standardUserDefaults] setObject:token forKey:@"oauth_token"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
}

- (BOOL)waitForCompletion:(NSTimeInterval)timeoutSecs {
    NSDate *timeoutDate = [NSDate dateWithTimeIntervalSinceNow:timeoutSecs];
    
    do {
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:timeoutDate];
        if([timeoutDate timeIntervalSinceNow] < 0.0)
            break;
    } while (!done);
    
    return done;
}

@end
