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

@interface OEXFindCoursesViewController () <FindCoursesWebViewHelperDelegate>

@property (strong, nonatomic) FindCoursesWebViewHelper* webViewHelper;
@property (strong, nonatomic) UIView* bottomBar;

@end

@implementation OEXFindCoursesViewController

- (instancetype) initWithBottomBar:(UIView*)bottomBar {
    self = [super init];
    if (self) {
        _bottomBar = bottomBar;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationItem.title = [Strings findCourses];

    self.webViewHelper = [[FindCoursesWebViewHelper alloc] initWithConfig:[OEXConfig sharedConfig] delegate:self bottomBar:self.bottomBar showSearch:YES];
    self.view.backgroundColor = [[OEXStyles sharedStyles] standardBackgroundColor];

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
    [self.webViewHelper loadRequestWithURL: urlToLoad];
}

- (void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    if ([[OEXSession sharedSession] currentUser]) {
        [self.webViewHelper.bottomBar removeFromSuperview];
    }
    
    [[OEXAnalytics sharedAnalytics] trackScreenWithName:OEXAnalyticsScreenFindCourses];
}

- (EnrollmentConfig*)enrollmentConfig {
    return [[OEXConfig sharedConfig] courseEnrollmentConfig];
}

- (void)showCourseInfoWithPathID:(NSString*)coursePathID {
    // FindCoursesWebViewHelper and OEXCourseInfoViewController are showing bottom bars so each should have their own copy of botombar view
    
    OEXCourseInfoViewController* courseInfoViewController = [[OEXCourseInfoViewController alloc] initWithPathID:coursePathID bottomBar:[_bottomBar copy]];
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
    return [OEXStyles sharedStyles].standardStatusBarStyle;
}

@end
