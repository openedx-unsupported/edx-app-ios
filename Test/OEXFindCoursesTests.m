//
//  OEXFindCoursesTest.m
//  edXVideoLocker
//
//  Created by Abhradeep on 13/02/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>

#import "edX-Swift.h"
#import "OEXEnvironment.h"
#import "OEXConfig.h"
#import "OEXNetworkManager.h"
#import "OEXFindCoursesViewController.h"
#import "OEXCourseInfoViewController.h"
#import "NSURL+OEXPathExtensions.h"

// TODO: Refactor so these are either on a separate object owned by the controller and hence testable
// or exposed through a special Test interface
@interface OEXFindCoursesViewController (TestCategory) <WebViewNavigationDelegate>
-(NSString *)getCoursePathIDFromURL:(NSURL *)url;
@end

@interface OEXCourseInfoViewController (TestCategory) <WebViewNavigationDelegate>
- (NSString*)courseURLString;
-(void)parseURL:(NSURL *)url getCourseID:(NSString *__autoreleasing *)courseID emailOptIn:(BOOL *)emailOptIn;
@end

@interface OEXFindCoursesTests : XCTestCase

@end

@implementation OEXFindCoursesTests

// TODO: Find a way to use TestRouterEnvironment instead.
// The issue is that this is only available for Swift tests, and trying to import `edXTests-Swift.h` does not work correctly.
-(RouterEnvironment *)mockRouterEnvironment {    
    InternetReachability *reachability = [[InternetReachability alloc] init];
    OEXConfig *config = [[OEXConfig alloc] init];
    OEXSession *session = [[OEXSession alloc] init];
    NetworkManager *mockNetworkManager = [[NetworkManager alloc]
                                          initWithAuthorizationDataProvider:NULL
                                          credentialProvider:NULL
                                          baseURL:[[NSURL alloc] init]
                                          cache:[[PersistentResponseCache alloc] initWithProvider:[[SessionUsernameProvider alloc] initWithSession:session]]];
    EnrollmentManager *mockEnrollmentManager = [[EnrollmentManager alloc]
                                                initWithInterface:NULL
                                                networkManager:mockNetworkManager
                                                config:config];
    OEXAnalytics *analytics = [[OEXAnalytics alloc] init];
    CourseDataManager *mockCourseDataManager = [[CourseDataManager alloc]
                                                initWithAnalytics:analytics
                                                enrollmentManager:mockEnrollmentManager
                                                interface:NULL
                                                networkManager:mockNetworkManager
                                                session:session];
    DataManager *dataManager = [[DataManager alloc]
                                initWithCourseDataManager:mockCourseDataManager
                                enrollmentManager:mockEnrollmentManager
                                interface:NULL
                                pushSettings:[[OEXPushSettingsManager alloc] init]
                                userProfileManager:[[UserProfileManager alloc] initWithNetworkManager:mockNetworkManager session:session]
                                userPreferenceManager:[[UserPreferenceManager alloc] initWithNetworkManager:mockNetworkManager]];
    
    return [[RouterEnvironment alloc]
            initWithAnalytics:analytics
            config:config
            dataManager:dataManager
            interface:NULL
            networkManager:mockNetworkManager
            reachability:reachability
            session:session
            styles:[[OEXStyles alloc] init]
            remoteConfig:[FirebaseRemoteConfiguration shared]
            serverConfig:[ServerConfiguration shared]];
}

-(void)testFindCoursesURLRecognition{
    RouterEnvironment *environment = [self mockRouterEnvironment];
    DiscoveryWebViewHelper* helper = [[DiscoveryWebViewHelper alloc] initWithEnvironment:environment delegate:nil bottomBar:nil searchQuery:nil];
    OEXFindCoursesViewController *findCoursesViewController = [[OEXFindCoursesViewController alloc] init];
    NSURLRequest *testURLRequestCorrect = [NSURLRequest requestWithURL:[NSURL URLWithString:@"edxapp://course_info?path_id=course/science-happiness-uc-berkeleyx-gg101x"]];
    BOOL successCorrect = ![findCoursesViewController webView:helper.t_webView shouldLoad:testURLRequestCorrect];
    XCTAssert(successCorrect, @"Correct URL not recognized");
    
    NSURLRequest *testURLRequestWrong = [NSURLRequest requestWithURL:[NSURL URLWithString:@"edxapps://course_infos?path_id=course/science-happiness-uc-berkeleyx-gg101x"]];
    BOOL successWrong = [findCoursesViewController webView:helper.t_webView shouldLoad:testURLRequestWrong];
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
    OEXCourseInfoViewController *courseInfoViewController = [[OEXCourseInfoViewController alloc] initWithEnvironment:nil pathID:@"abc" bottomBar:nil];

    NSString* courseID = nil;
    BOOL emailOptIn = true;

    [courseInfoViewController parseURL:testEnrollURL getCourseID:&courseID emailOptIn:&emailOptIn];

    XCTAssertEqualObjects(courseID, @"course-v1:BerkeleyX+GG101x-2+1T2015", @"Course ID incorrectly parsed");
    XCTAssertEqual(emailOptIn, false, @"Email Opt-In incorrectly parsed");
}

@end
