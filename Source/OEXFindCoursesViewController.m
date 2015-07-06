//
//  OEXFindCoursesViewController.m
//  edXVideoLocker
//
//  Created by Abhradeep on 02/02/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

#import <MessageUI/MessageUI.h>

#import "OEXFindCoursesViewController.h"

#import "OEXConfig.h"
#import "OEXCourseInfoViewController.h"
#import "OEXDownloadViewController.h"
#import "OEXEnrollmentConfig.h"
#import "OEXRouter.h"
#import "OEXStyles.h"
#import "NSURL+OEXPathExtensions.h"

static NSString* const OEXFindCoursesCourseInfoPath = @"course_info/";
static NSString* const OEXFindCoursesPathIDKey = @"path_id";
static NSString* const OEXFindCoursePathPrefix = @"course/";

@interface OEXFindCoursesViewController () <OEXFindCoursesWebViewHelperDelegate>
@property(nonatomic, strong) IBOutlet UIActivityIndicatorView* loadingIndicator;
@property (strong, nonatomic) OEXFindCoursesWebViewHelper* webViewHelper;

@end

@implementation OEXFindCoursesViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.webViewHelper = [[OEXFindCoursesWebViewHelper alloc] initWithWebView:self.webView delegate:self];
    self.webViewHelper.progressIndicator = self.loadingIndicator;
    if(self.revealViewController) {
        self.revealViewController.delegate = self;
        [self.view addGestureRecognizer:self.revealViewController.panGestureRecognizer];
    }

    self.overlayButton.alpha = 0.0f;
    if(self.dataInterface.reachable) {
        [self.webViewHelper loadWebViewWithURLString:[self enrollmentConfig].searchURL];
    }
}

- (OEXEnrollmentConfig*)enrollmentConfig {
    return [[OEXConfig sharedConfig] courseEnrollmentConfig];
}

- (void)reachabilityDidChange:(NSNotification*)notification {
    [super reachabilityDidChange:notification];
    if([self enrollmentConfig].enabled && self.dataInterface.reachable && !self.webViewHelper.isWebViewLoaded) {
        [self.webViewHelper loadWebViewWithURLString:[self enrollmentConfig].searchURL];
    }
}

- (void)setExclusiveTouches {
    [super setExclusiveTouches];
    self.overlayButton.exclusiveTouch = YES;
}

- (void)setNavigationBar {
    [super setNavigationBar];

    self.customNavView.lbl_TitleView.text = OEXLocalizedString(@"FIND_COURSES", nil);
    for(UIView* view in self.customNavView.subviews) {
        if([view isKindOfClass:[UIButton class]]) {
            [((UIButton*)view)setImage : nil forState : UIControlStateNormal];
        }
    }
    [self.customNavView.btn_Back setImage:[UIImage imageNamed:@"ic_navigation.png"] forState:UIControlStateNormal ];
    [self.customNavView.btn_Back setFrame:CGRectMake(8, 31, 22, 22)];
    [self.customNavView.btn_Back addTarget:self action:@selector(backNavigationPressed) forControlEvents:UIControlEventTouchUpInside];
    
    [[OEXStyles sharedStyles] applyMockNavigationBarStyleToView:self.customNavView label:self.customNavView.lbl_TitleView leftIconButton:self.customNavView.btn_Back];
}

- (void)backNavigationPressed {
    self.view.userInteractionEnabled = NO;
    self.overlayButton.hidden = NO;
    [self.navigationController popToViewController:self animated:NO];
    [UIView animateWithDuration:0.9 animations:^{
        self.overlayButton.alpha = 0.5;
    }];
    [self performSelector:@selector(toggleReveal) withObject:nil afterDelay:0.2];
}

- (void)toggleReveal {
    [self.revealViewController revealToggle:self.customNavView.btn_Back];
}

- (void)revealController:(SWRevealViewController*)revealController didMoveToPosition:(FrontViewPosition)position {
    self.view.userInteractionEnabled = YES;
    [super revealController:revealController didMoveToPosition:position];
}

- (void)showCourseInfoWithPathID:(NSString*)coursePathID {
    OEXCourseInfoViewController* courseInfoViewController = [[OEXCourseInfoViewController alloc] initWithPathID:coursePathID];
    [self.navigationController pushViewController:courseInfoViewController animated:YES];
}

- (BOOL)webViewHelper:(OEXFindCoursesWebViewHelper*)webViewHelper shouldLoadURLWithRequest:(NSURLRequest*)request navigationType:(UIWebViewNavigationType)navigationType {
    NSString* coursePathID = [self getCoursePathIDFromURL:request.URL];
    if(coursePathID != nil) {
        [self showCourseInfoWithPathID:coursePathID];
        return NO;
    }
    return YES;
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
