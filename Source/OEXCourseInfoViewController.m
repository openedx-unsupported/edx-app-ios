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
#import "OEXFindCoursesViewController.h"
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
@property (strong,nonatomic, nullable) UIView *bottomBar;

@end

@implementation OEXCourseInfoViewController

- (instancetype)initWithPathID:(NSString*)pathID bottomBar:(nullable UIView*) bottomBar {
    self = [super initWithNibName:nil bundle:nil];
    if(self != nil) {
        self.pathID = pathID;
        self.bottomBar = bottomBar;
        self.navigationItem.title = [self courseDiscoveryTitle];
    }
    return self;
}

- (NSURL*)courseInfoURL {
    NSString* urlString = [[self enrollmentConfig].webviewConfig.courseInfoURLTemplate stringByReplacingOccurrencesOfString:OEXCourseInfoLinkPathIDPlaceholder withString:self.pathID];
    NSURL* URL = [NSURL URLWithString:urlString];
    return URL;
}

- (EnrollmentConfig*)enrollmentConfig {
    return [[OEXConfig sharedConfig] courseEnrollmentConfig];
}
    
-(NSString *) courseDiscoveryTitle {
    if ([[self enrollmentConfig] isCourseDiscoveryNative]) {
        return [Strings findCourses];
    }
    
    return [Strings discover];
}

- (void)viewDidLoad {
    [super viewDidLoad];

    self.webViewHelper = [[FindCoursesWebViewHelper alloc] initWithConfig:[OEXConfig sharedConfig] delegate:self bottomBar:self.bottomBar showSearch:NO];
    [self.webViewHelper loadRequestWithURL:self.courseInfoURL];
    self.view.backgroundColor = [[OEXStyles sharedStyles] standardBackgroundColor];
}

- (void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    if ([[OEXSession sharedSession] currentUser]) {
        [self.webViewHelper.bottomBar removeFromSuperview];
    }
    
    [[OEXAnalytics sharedAnalytics] trackScreenWithName:OEXAnalyticsScreenCourseInfo];
}

- (BOOL)webViewHelperWithHelper:(FindCoursesWebViewHelper *)helper shouldLoadLinkWithRequest:(NSURLRequest *)request {
    NSString* courseID = nil;
    BOOL emailOptIn = false;
    [self parseURL:request.URL getCourseID:&courseID emailOptIn:&emailOptIn];
    if(courseID != nil) {
        [self  enrollInCourseWithCourseID:courseID emailOpt:emailOptIn];
        return NO;
    }
    return YES;
}

- (UIViewController *)containingControllerForWebViewHelperWithHelper:(FindCoursesWebViewHelper *)helper {
    return self;
}

- (void)parseURL:(NSURL*)url getCourseID:(NSString* __autoreleasing*)courseID emailOptIn:(BOOL*)emailOptIn {
    if([url.scheme isEqualToString:OEXFindCoursesLinkURLScheme] && [url.oex_hostlessPath isEqualToString:OEXFindCoursesEnrollPath]) {
        NSDictionary* queryParameters = url.oex_queryParameters;
        *courseID = queryParameters[OEXCourseEnrollURLCourseIDKey];
        *emailOptIn = [queryParameters[OEXCourseEnrollURLEmailOptInKey] boolValue];
    }
}

- (void)showMainScreenWithMessage:(NSString*)message courseID:(NSString*)courseID {
    [[OEXRouter sharedRouter] showMyCoursesAnimated:YES pushingCourseWithID:courseID];
    [self performSelector:@selector(postEnrollmentSuccessNotification:) withObject:message afterDelay:0.5];
}

- (void)postEnrollmentSuccessNotification:(NSString*)message {
    [[NSNotificationCenter defaultCenter] postNotificationName:EnrollmentShared.successNotification object:message];
    
    if ([self isModal]) {
        [self.view.window.rootViewController dismissViewControllerAnimated:YES completion:nil];
    }
}

@end
