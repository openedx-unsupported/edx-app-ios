//
//  OEXCourseInfoViewController.m
//  edXVideoLocker
//
//  Created by Abhradeep on 03/02/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

#import "OEXCourseInfoViewController.h"

#import "edX-Swift.h"

#import "NSNotificationCenter+OEXSafeAccess.h"
#import "NSURL+OEXPathExtensions.h"

#import "OEXAnalytics.h"
#import "OEXConstants.h"
#import "OEXCourse.h"
#import "OEXEnrollmentConfig.h"
#import "OEXFindCoursesViewController.h"
#import "OEXFlowErrorViewController.h"
#import "OEXInterface.h"
#import "OEXNetworkManager.h"
#import "OEXNetworkConstants.h"
#import "OEXRouter.h"
#import "OEXStyles.h"

static NSString* const OEXFindCoursesEnrollPath = @"enroll/";
static NSString* const OEXCourseEnrollURLCourseIDKey = @"course_id";
static NSString* const OEXCourseEnrollURLEmailOptInKey = @"email_opt_in";
static NSString* const OEXCourseInfoLinkPathIDPlaceholder = @"{path_id}";

@interface OEXCourseInfoViewController () <FindCoursesWebViewHelperDelegate>

@property (strong, nonatomic) FindCoursesWebViewHelper* webViewHelper;
@property (strong, nonatomic) NSString* pathID;

@end

@implementation OEXCourseInfoViewController

- (instancetype)initWithPathID:(NSString*)pathID {
    self = [super initWithNibName:nil bundle:nil];
    if(self != nil) {
        self.pathID = pathID;
    }
    return self;
}

- (NSURL*)courseInfoURL {
    NSString* urlString = [[self enrollmentConfig].courseInfoURLTemplate stringByReplacingOccurrencesOfString:OEXCourseInfoLinkPathIDPlaceholder withString:self.pathID];
    NSURL* URL = [NSURL URLWithString:urlString];
    return URL;
}

- (OEXEnrollmentConfig*)enrollmentConfig {
    return [[OEXConfig sharedConfig] courseEnrollmentConfig];
}

- (void)viewDidLoad {
    [super viewDidLoad];

    self.webViewHelper = [[FindCoursesWebViewHelper alloc] initWithConfig:[OEXConfig sharedConfig] delegate:self];
    [self.webViewHelper loadRequestWithURL:self.courseInfoURL];
    self.view.backgroundColor = [[OEXStyles sharedStyles] standardBackgroundColor];
}

- (BOOL)webViewHelper:(FindCoursesWebViewHelper *)helper shouldLoadLinkWithRequest:(NSURLRequest *)request {
    NSString* courseID = nil;
    BOOL emailOptIn = false;
    [self parseURL:request.URL getCourseID:&courseID emailOptIn:&emailOptIn];
    if(courseID != nil) {
        [self enrollInCourseWithCourseID:courseID emailOptIn:emailOptIn];
        return NO;
    }
    return YES;
}

- (UIViewController*)containingControllerForWebViewHelper:(FindCoursesWebViewHelper *)helper {
    return self;
}

- (void)parseURL:(NSURL*)url getCourseID:(NSString* __autoreleasing*)courseID emailOptIn:(BOOL*)emailOptIn {
    if([url.scheme isEqualToString:OEXFindCoursesLinkURLScheme] && [url.oex_hostlessPath isEqualToString:OEXFindCoursesEnrollPath]) {
        NSDictionary* queryParameters = url.oex_queryParameters;
        *courseID = queryParameters[OEXCourseEnrollURLCourseIDKey];
        *emailOptIn = [queryParameters[OEXCourseEnrollURLEmailOptInKey] boolValue];
    }
}

- (void)enrollInCourseWithCourseID:(NSString*)courseID emailOptIn:(BOOL)emailOptIn {
    UserCourseEnrollment* courseEnrollment = [[OEXInterface sharedInterface] enrollmentForCourseWithID:courseID];

    if(courseEnrollment) {
        [self showMainScreenWithMessage:[Strings findCoursesAlreadyEnrolledMessage] courseID:courseID];
        return;
    }

    OEXNetworkManager* networkManager = [OEXNetworkManager sharedManager];

    NSDictionary* enrollmentDictionary = @{@"course_details":@{@"course_id": courseID, @"email_opt_in":@(emailOptIn)}};

    NSData* enrollmentJSONData = [NSJSONSerialization dataWithJSONObject:enrollmentDictionary options:0 error:nil];

    [[OEXAnalytics sharedAnalytics] trackUserEnrolledInCourse:courseID];

    [networkManager callAuthorizedWebServiceWithURLPath:URL_COURSE_ENROLLMENT method:OEXHTTPMethodPOST body:enrollmentJSONData completionHandler:^(NSData* data, NSURLResponse* response, NSError* error) {
        NSHTTPURLResponse* httpResponse = (NSHTTPURLResponse*)response;
        if(httpResponse.statusCode == 200) {
            if([NSThread isMainThread]) {
                [self showMainScreenWithMessage:[Strings findCoursesEnrollmentSuccessfulMessage] courseID:courseID];
            }
            else {
                dispatch_async(dispatch_get_main_queue(), ^{
                        [self showMainScreenWithMessage:[Strings findCoursesEnrollmentSuccessfulMessage] courseID:courseID];
                    });
            }
            return;
        }
        if([NSThread isMainThread]) {
            [self showEnrollmentError];
        }
        else {
            dispatch_async(dispatch_get_main_queue(), ^{
                    [self showEnrollmentError];
                });
        }
    }];
}

- (void)showMainScreenWithMessage:(NSString*)message courseID:(NSString*)courseID {
    [[OEXRouter sharedRouter] showMyCoursesAnimated:YES pushingCourseWithID:courseID];
    [self performSelector:@selector(postEnrollmentSuccessNotification:) withObject:message afterDelay:0.5];
}

- (void)showEnrollmentError {
    [[OEXFlowErrorViewController sharedInstance] showErrorWithTitle:[Strings findCoursesEnrollmentErrorTitle] message:[Strings findCoursesEnrollmentErrorDescription] onViewController:self.view shouldHide:YES];
}

- (void)postEnrollmentSuccessNotification:(NSString*)message {
    [[NSNotificationCenter defaultCenter] postNotificationName:EnrollmentShared.successNotification object:message];
}

@end
