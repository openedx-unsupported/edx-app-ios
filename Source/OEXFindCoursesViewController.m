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
#import "OEXEnrollmentConfig.h"
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

@end

@implementation OEXFindCoursesViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationItem.title = [Strings findCourses];

    self.webViewHelper = [[FindCoursesWebViewHelper alloc] initWithConfig:[OEXConfig sharedConfig] delegate:self];
    self.view.backgroundColor = [[OEXStyles sharedStyles] standardBackgroundColor];

    [self.webViewHelper loadRequestWithURL:[self enrollmentConfig].searchURL];
}

- (OEXEnrollmentConfig*)enrollmentConfig {
    return [[OEXConfig sharedConfig] courseEnrollmentConfig];
}

- (void)showCourseInfoWithPathID:(NSString*)coursePathID {
    OEXCourseInfoViewController* courseInfoViewController = [[OEXCourseInfoViewController alloc] initWithPathID:coursePathID];
    [self.navigationController pushViewController:courseInfoViewController animated:YES];
}

- (BOOL)webViewHelper:(FindCoursesWebViewHelper *)helper shouldLoadLinkWithRequest:(NSURLRequest *)request {
    NSString* coursePathID = [self getCoursePathIDFromURL:request.URL];
    if(coursePathID != nil) {
        [self showCourseInfoWithPathID:coursePathID];
        return NO;
    }
    return YES;
}

- (UIViewController*)containingControllerForWebViewHelper:(FindCoursesWebViewHelper *)helper {
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
