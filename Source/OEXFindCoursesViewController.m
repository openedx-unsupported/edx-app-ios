//
//  OEXFindCoursesViewController.m
//  edXVideoLocker
//
//  Created by Abhradeep on 02/02/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

#import "OEXFindCoursesViewController.h"
#import "edX-Swift.h"
#import "OEXConfig.h"
#import "OEXCourseInfoViewController.h"
#import "OEXDownloadViewController.h"
#import "NSNotificationCenter+OEXSafeAccess.h"
#import "OEXRouter.h"
#import "OEXStyles.h"
#import "NSURL+OEXPathExtensions.h"

NSString* const OEXFindCoursesLinkURLScheme = @"edxapp";

static NSString* const OEXFindCoursesCourseInfoPath = @"course_info/";
static NSString* const OEXFindCoursesPathIDKey = @"path_id";
static NSString* const OEXFindCoursePathPrefix = @"course/";

@interface OEXFindCoursesViewController () <FindCoursesWebViewHelperDelegate, InterfaceOrientationOverriding>

@property (strong, nonatomic) FindCoursesWebViewHelper* webViewHelper;
@property (strong, nonatomic) UIView* bottomBar;
@property (strong, nonatomic) NSString* searchQuery;
@property (strong, nonatomic) RouterEnvironment* environment;

@end

@implementation OEXFindCoursesViewController

- (instancetype) initWithEnvironment:(RouterEnvironment*)environment bottomBar:(UIView*)bottomBar searchQuery:(nullable NSString *)searchQuery  {
    self = [super init];
    if (self) {
        _environment = environment;
        _bottomBar = bottomBar;
        _searchQuery = searchQuery;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationItem.title = [self courseDiscoveryTitle];
    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"" style:UIBarButtonItemStylePlain target:nil action:nil];
    self.navigationItem.backBarButtonItem.accessibilityIdentifier = @"FindCoursesViewController:cancel-bar-button-item";
    self.webViewHelper = [[FindCoursesWebViewHelper alloc] initWithEnvironment:self.environment delegate:self bottomBar:_bottomBar showSearch:YES searchQuery:_searchQuery showSubjects:YES];
    self.view.backgroundColor = [self.environment.styles standardBackgroundColor];

    self.webViewHelper.searchBaseURL = [self enrollmentConfig].webviewConfig.searchURL;
    NSURL* urlToLoad = nil;
    switch (self.startURL) {
        case OEXFindCoursesBaseTypeFindCourses:
            urlToLoad = [self enrollmentConfig].webviewConfig.searchURL;
            break;
        case OEXFindCoursesBaseTypeExploreSubjects:
            self.navigationItem.title = [Strings startupExploreSubjects];
            urlToLoad = [self enrollmentConfig].webviewConfig.exploreSubjectsURL;
            break;
    }
    [self.webViewHelper loadWithURL:urlToLoad];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    [self.webViewHelper updateSubjectsVisibility];
}
    
-(NSString *) courseDiscoveryTitle {
    if ([[self enrollmentConfig] isCourseDiscoveryNative]) {
        return [Strings findCourses];
    }
    
    return [Strings discover];
}

- (void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    if ([self.environment.session currentUser]) {
        [self.webViewHelper refreshView];
    }
    
    [self.environment.analytics trackScreenWithName:OEXAnalyticsScreenFindCourses];
}

- (EnrollmentConfig*)enrollmentConfig {
    return [self.environment.config courseEnrollmentConfig];
}

- (void)showCourseInfoWithPathID:(NSString*)coursePathID {
    // FindCoursesWebViewHelper and OEXCourseInfoViewController are showing bottom bars so each should have their own copy of botombar view
    
    OEXCourseInfoViewController* courseInfoViewController = [[OEXCourseInfoViewController alloc] initWithEnvironment: self.environment pathID:coursePathID bottomBar:[_bottomBar copy]];
    [self.navigationController pushViewController:courseInfoViewController animated:YES];
}

- (BOOL) webViewHelperWithHelper:(FindCoursesWebViewHelper *)helper shouldLoadLinkWithRequest:(NSURLRequest *)request {
    NSString* coursePathID = [self getCoursePathIDFromURL:request.URL];
    if(coursePathID != nil) {
        [self showCourseInfoWithPathID:coursePathID];
        return NO;
    }
    return YES;
}

- (UIViewController*)containingControllerForWebViewHelperWithHelper:(FindCoursesWebViewHelper *)helper {
    return self;
}

- (NSString*)getCoursePathIDFromURL:(NSURL*)url {
    if([url.scheme isEqualToString:OEXFindCoursesLinkURLScheme] && [url.oex_hostlessPath isEqualToString:OEXFindCoursesCourseInfoPath]) {
        NSString* path = url.oex_queryParameters[OEXFindCoursesPathIDKey];
        // the site sends us things of the form "course/<path_id>" we only want the path id
        NSString* pathID = [path stringByReplacingOccurrencesOfString:OEXFindCoursePathPrefix withString:@"" options:0 range:NSMakeRange(0, OEXFindCoursePathPrefix.length)];
        return pathID;
    }
    return nil;
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return self.environment.styles.standardStatusBarStyle;
}

- (BOOL) shouldAutorotate {
    return true;
}

- (UIInterfaceOrientationMask) supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskAllButUpsideDown;
}

@end
