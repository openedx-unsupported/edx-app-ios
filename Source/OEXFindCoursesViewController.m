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

@interface OEXFindCoursesViewController () <WebViewNavigationDelegate, InterfaceOrientationOverriding>

@property (strong, nonatomic) DiscoveryWebViewHelper* webViewHelper;
@property (strong, nonatomic) UIView* bottomBar;
@property (nonatomic) BOOL showBottomBar;
@property (strong, nonatomic) NSString* searchQuery;
@property (strong, nonatomic) RouterEnvironment* environment;

@end

@implementation OEXFindCoursesViewController

- (instancetype) initWithEnvironment:(RouterEnvironment *)environment showBottomBar:(BOOL) showBottomBar bottomBar:(UIView *)bottomBar searchQuery:(nullable NSString *)searchQuery  {
    self = [super init];
    if (self) {
        _environment = environment;
        _bottomBar = bottomBar;
        _searchQuery = searchQuery;
        _showBottomBar = showBottomBar;

        [self loadCourseDiscovery];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationItem.title = [self courseDiscoveryTitle];
    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"" style:UIBarButtonItemStylePlain target:nil action:nil];
    self.navigationItem.backBarButtonItem.accessibilityIdentifier = @"FindCoursesViewController:cancel-bar-button-item";
}

- (void) loadCourseDiscovery {
    self.webViewHelper = [[DiscoveryWebViewHelper alloc] initWithEnvironment:self.environment delegate:self bottomBar:_showBottomBar ? _bottomBar : nil showSearch:YES searchQuery:_searchQuery];
    self.view.backgroundColor = [self.environment.styles standardBackgroundColor];

    self.webViewHelper.baseURL = [self discoveryConfig].webview.baseURL;
    NSURL* urlToLoad = nil;
    switch (self.startURL) {
        case OEXFindCoursesBaseTypeFindCourses:
            urlToLoad = [self discoveryConfig].webview.baseURL;
            break;
    }
    
    [self.webViewHelper loadWithURL:urlToLoad];
}
    
-(NSString *) courseDiscoveryTitle {
    if ([[self discoveryConfig] isCourseDiscoveryNative]) {
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

- (CourseDiscovery*)discoveryConfig {
    return [self.environment.config.discovery course];
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

- (BOOL)webView:(WKWebView * _Nonnull)webView shouldLoad:(NSURLRequest * _Nonnull)request {

    if (request.URL != nil) {
        return ![DiscoveryHelper navigateTo:request.URL from:self bottomBar:_bottomBar];
    }

    return YES;
}

- (UIViewController * _Nonnull)webViewContainingController {
    return self;
}

@end
