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

@interface OEXCourseInfoViewController () <WebViewNavigationDelegate, InterfaceOrientationOverriding>

@property (strong, nonatomic) FindCoursesWebViewHelper* webViewHelper;
@property (strong, nonatomic) NSString* pathID;
@property (strong,nonatomic, nullable) UIView *bottomBar;
@property (strong, nonatomic) RouterEnvironment* environment;

@end

@implementation OEXCourseInfoViewController

- (instancetype)initWithEnvironment:(RouterEnvironment* _Nullable)environment pathID:(NSString*)pathID bottomBar:(nullable UIView*) bottomBar {
    self = [super initWithNibName:nil bundle:nil];
    if(self != nil) {
        self.environment = environment;
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
    return [self.environment.config courseEnrollmentConfig];
}
    
-(NSString *) courseDiscoveryTitle {
    if ([[self enrollmentConfig] isCourseDiscoveryNative]) {
        return [Strings findCourses];
    }
    
    return [Strings discover];
}

- (void)viewDidLoad {
    [super viewDidLoad];

    self.webViewHelper = [[FindCoursesWebViewHelper alloc] initWithEnvironment:self.environment delegate:self bottomBar:self.bottomBar showSearch:NO searchQuery:nil showSubjects:NO];
    [self.webViewHelper loadWithURL:self.courseInfoURL];
    self.view.backgroundColor = [self.environment.styles standardBackgroundColor];
}

- (void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    if ([self.environment.session currentUser]) {
        [self.webViewHelper refreshView];
    }
    
    [self.environment.analytics trackScreenWithName:OEXAnalyticsScreenCourseInfo];
}

- (BOOL)webView:(WKWebView * _Nonnull)webView shouldLoad:(NSURLRequest * _Nonnull)request {
    NSString* courseID = nil;
    BOOL emailOptIn = false;
    [self parseURL:request.URL getCourseID:&courseID emailOptIn:&emailOptIn];
    if(courseID != nil) {
        [CourseDiscoveryHelper enrollInCourseWithCourseID:courseID emailOpt:emailOptIn from:self];
        return NO;
    }
    return YES;
}

- (UIViewController * _Nonnull)webViewContainingController {
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
    [self.environment.router showMyCoursesAnimated:YES pushingCourseWithID:courseID];
    [self performSelector:@selector(postEnrollmentSuccessNotification:) withObject:message afterDelay:0.5];
}

- (void)postEnrollmentSuccessNotification:(NSString*)message {
    [[NSNotificationCenter defaultCenter] postNotificationName:EnrollmentShared.successNotification object:message];

    if ([self isRootModal]) {
        [self.view.window.rootViewController dismissViewControllerAnimated:YES completion:nil];
    }
}

- (BOOL) shouldAutorotate {
    return true;
}

- (UIInterfaceOrientationMask) supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskAllButUpsideDown;
}

@end
