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
#import "OEXFindCoursesViewController.h"
#import "OEXCourseInfoViewController.h"
#import "OEXFindCoursesWebViewHelper.h"
#import "NSURL+OEXPathExtensions.h"

@interface OEXFindCoursesViewController (TestCategory) <OEXFindCoursesWebViewHelperDelegate>
-(NSString *)getCoursePathIDFromURL:(NSURL *)url;
@end

@interface OEXCourseInfoViewController (TestCategory) <OEXFindCoursesWebViewHelperDelegate>
- (NSString*)courseURLString;
-(void)parseURL:(NSURL *)url getCourseID:(NSString *__autoreleasing *)courseID emailOptIn:(BOOL *)emailOptIn;
@end

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
    NSDictionary *testDictionary = @{@"COURSE_ENROLLMENT":@{
                                                    @"COURSE_INFO_URL_TEMPLATE":@"https://webview.edx.org/course/{path_id}",
                                                    @"ENABLED":@(true),
                                                    @"SEARCH_URL":@"https://webview.edx.org/course?type=mobile"
                                                        }};
    OEXConfig *testConfig = [[OEXConfig alloc] initWithDictionary:testDictionary];
    
    OEXEnrollmentConfig *testEnrollmentConfig = [testConfig courseEnrollmentConfig];
    
    XCTAssertNotNil(testEnrollmentConfig, @"testEnrollmentConfig is nil");
    XCTAssertEqual(testEnrollmentConfig.enabled, true, @"enabled is incorrect");
    XCTAssertEqualObjects(testEnrollmentConfig.searchURL, @"https://webview.edx.org/course?type=mobile", @"searchURL object is incorrect");
    XCTAssertEqualObjects(testEnrollmentConfig.courseInfoURLTemplate, @"https://webview.edx.org/course/{path_id}", @"courseInfoURLTemplate object is incorrect");
}

-(void)testFindCoursesURLRecognition{
    OEXFindCoursesViewController *findCoursesViewController = [[OEXFindCoursesViewController alloc] init];
    NSURLRequest *testURLRequestCorrect = [NSURLRequest requestWithURL:[NSURL URLWithString:@"edxapp://course_info?path_id=course/science-happiness-uc-berkeleyx-gg101x"]];
    BOOL successCorrect = ![findCoursesViewController webViewHelper:nil shouldLoadURLWithRequest:testURLRequestCorrect navigationType:UIWebViewNavigationTypeLinkClicked];
    XCTAssert(successCorrect, @"Correct URL not recognized");
    
    NSURLRequest *testURLRequestWrong = [NSURLRequest requestWithURL:[NSURL URLWithString:@"edxapps://course_infos?path_id=course/science-happiness-uc-berkeleyx-gg101x"]];
    BOOL successWrong = [findCoursesViewController webViewHelper:nil shouldLoadURLWithRequest:testURLRequestWrong navigationType:UIWebViewNavigationTypeLinkClicked];
    XCTAssert(successWrong, @"Wrong URL not recognized");
}

-(void)testCourseInfoURLRecognition{
    OEXCourseInfoViewController *courseInfoViewController = [[OEXCourseInfoViewController alloc] init];
    NSURLRequest *testURLRequestCorrect = [NSURLRequest requestWithURL:[NSURL URLWithString:@"edxapp://enroll?course_id=course-v1:BerkeleyX+GG101x-2+1T2015&email_opt_in=false"]];
    BOOL successCorrect = ![courseInfoViewController webViewHelper:nil shouldLoadURLWithRequest:testURLRequestCorrect navigationType:UIWebViewNavigationTypeLinkClicked];
    XCTAssert(successCorrect, @"Correct URL not recognized");
    
    NSURLRequest *testURLRequestWrong = [NSURLRequest requestWithURL:[NSURL URLWithString:@"edxapps://enrolled?course_id=course-v1:BerkeleyX+GG101x-2+1T2015&email_opt_in=false"]];
    BOOL successWrong = [courseInfoViewController webViewHelper:nil shouldLoadURLWithRequest:testURLRequestWrong navigationType:UIWebViewNavigationTypeLinkClicked];
    XCTAssert(successWrong, @"Wrong URL not recognized");
}

-(void)testPathIDParsing{
    NSURL *testURL = [NSURL URLWithString:@"edxapp://course_info?path_id=course/science-happiness-uc-berkeleyx-gg101x"];
    OEXFindCoursesViewController *findCoursesViewController = [[OEXFindCoursesViewController alloc] init];
    
    NSString *pathID = [findCoursesViewController getCoursePathIDFromURL:testURL];
    XCTAssertEqualObjects(pathID, @"science-happiness-uc-berkeleyx-gg101x", @"Path ID incorrectly parsed");
}

-(void)testEnrollURLParsing{
    NSURL *testEnrollURL = [NSURL URLWithString:@"edxapp://enroll?course_id=course-v1:BerkeleyX+GG101x-2+1T2015&email_opt_in=false"];
    OEXCourseInfoViewController *courseInfoViewController = [[OEXCourseInfoViewController alloc] init];
    
    NSString* courseID = nil;
    BOOL emailOptIn = true;
    
    [courseInfoViewController parseURL:testEnrollURL getCourseID:&courseID emailOptIn:&emailOptIn];

    XCTAssertEqualObjects(courseID, @"course-v1:BerkeleyX+GG101x-2+1T2015", @"Course ID incorrectly parsed");
    XCTAssertEqual(emailOptIn, false, @"Email Opt-In incorrectly parsed");
}

-(void)testCourseInfoURLTemplateSubstitution{
    OEXCourseInfoViewController *courseInfoViewController = [[OEXCourseInfoViewController alloc] initWithPathID:@"science-happiness-uc-berkeleyx-gg101x"];
    NSString *courseURLString = [courseInfoViewController courseURLString];
    XCTAssertEqualObjects(courseURLString, @"https://webview.edx.org/course/science-happiness-uc-berkeleyx-gg101x", @"Course Info URL incorrectly determined");
}

@end
