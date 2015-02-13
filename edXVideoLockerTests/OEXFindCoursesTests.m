//
//  OEXFindCoursesTest.m
//  edXVideoLocker
//
//  Created by Abhradeep on 13/02/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import "OEXEnvironment.h"
#import "OEXConfig.h"
#import "OEXEnrollmentConfig.h"
#import "OEXNetworkManager.h"

@interface OEXFindCoursesTests : XCTestCase

@end

@implementation OEXFindCoursesTests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

-(void)testEnrollmentConfig{
    OEXEnvironment *environment = [[OEXEnvironment alloc] init];
    [environment setupEnvironment];
    OEXConfig *config = [OEXConfig sharedConfig];
    OEXEnrollmentConfig *enrollmentConfig = [config courseEnrollmentConfig];
    XCTAssertNotNil(enrollmentConfig,"OEXEnrollmentConfig object is nil");
    XCTAssertNotNil(enrollmentConfig.searchURL,"searchURL object is nil");
    XCTAssertNotNil(enrollmentConfig.courseInfoURLTemplate,"courseInfoURLTemplate object is nil");
    
    OEXConfig *testConfig = [[OEXConfig alloc] initWithAppBundleData];
    NSDictionary *courseEnrollmentDictionary = [testConfig objectForKey:@"COURSE_ENROLLMENT"];
    OEXEnrollmentConfig *testEnrollmentConfig = [[OEXEnrollmentConfig alloc] initWithDictionary:courseEnrollmentDictionary];
    
    XCTAssertEqual(enrollmentConfig.enabled, testEnrollmentConfig.enabled, @"enabled is not equal");
    XCTAssertEqualObjects(enrollmentConfig.searchURL, testEnrollmentConfig.searchURL, @"searchURL object is not equal");
    XCTAssertEqualObjects(enrollmentConfig.courseInfoURLTemplate, testEnrollmentConfig.courseInfoURLTemplate, @"courseInfoURLTemplate object is not equal");
}

//This test case will only after application has been logged in
-(void)testCallAuthorizedWebService{

    XCTestExpectation *webServiceExpectation = [self expectationWithDescription:@"webServiceExpectation"];
    
    OEXNetworkManager *sharedManager = [OEXNetworkManager sharedManager];

    NSDictionary *enrollmentDictionary = @{@"course_details":@{@"course_id": @"course-v1:BerkeleyX+GG101x-2+1T2015", @"email_opt_in":@"false"}};
    NSData *enrollmentJSONData = [NSJSONSerialization dataWithJSONObject:enrollmentDictionary options:0 error:nil];
    [sharedManager callAuthorizedWebServiceWithURLPath:@"/api/enrollment/v1/enrollment" method:@"POST" body:enrollmentJSONData completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        XCTAssert(!error, @"some error occurred");
        XCTAssertNotNil(data, @"data is nil");
        XCTAssertNotNil(response, @"response object is nil");
        NSLog(@"response: %@",[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
        if (httpResponse.statusCode==200) {
            [webServiceExpectation fulfill];
        }
        else{
            XCTFail(@"Not enrolled");
        }
    }];
    
    [self waitForExpectationsWithTimeout:10 handler:^(NSError *error) {

    }];
}

@end
