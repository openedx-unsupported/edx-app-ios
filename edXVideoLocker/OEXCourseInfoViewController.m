//
//  OEXCourseInfoViewController.m
//  edXVideoLocker
//
//  Created by Abhradeep on 03/02/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

#import "OEXCourseInfoViewController.h"

#import "NSURL+OEXPathExtensions.h"

#import "OEXConstants.h"
#import "OEXCourse.h"
#import "OEXEnrollmentMessage.h"
#import "OEXFlowErrorViewController.h"
#import "OEXFrontCourseViewController.h"
#import "OEXInterface.h"
#import "OEXNetworkManager.h"
#import "OEXNetworkConstants.h"
#import "OEXStatusMessageViewController.h"
#import "OEXUserCourseEnrollment.h"


static NSString* const OEXFindCoursesEnrollPath = @"enroll/";
static NSString* const OEXCourseEnrollURLCourseIDKey = @"course_id";
static NSString* const OEXCourseEnrollURLEmailOptInKey = @"email_opt_in";
static NSString* const OEXCourseInfoLinkPathIDPlaceholder = @"{path_id}";

@interface OEXCourseInfoViewController ()<OEXFindCoursesWebViewHelperDelegate>

@property (strong, nonatomic) OEXFindCoursesWebViewHelper* webViewHelper;
@property (strong, nonatomic) NSString* pathID;

-(void)showMainScreenWithMessage:(OEXEnrollmentMessage *)message;
-(void)showEnrollmentError;
-(void)postEnrollmentSuccessNotification:(NSString *)message;

@end

@implementation OEXCourseInfoViewController

- (instancetype)initWithPathID:(NSString *)pathID {
    self = [super initWithNibName:nil bundle:nil];
    if(self != nil) {
        self.pathID = pathID;
    }
    return self;
}

- (NSString*)courseURLString {
    return [[self enrollmentConfig].courseInfoURLTemplate stringByReplacingOccurrencesOfString:OEXCourseInfoLinkPathIDPlaceholder withString:self.pathID];
}

- (OEXEnrollmentConfig*)enrollmentConfig {
    return [[OEXConfig sharedConfig] courseEnrollmentConfig];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.webViewHelper = [[OEXFindCoursesWebViewHelper alloc] initWithWebView:self.webView delegate:self];
    if (self.dataInterface.reachable) {
        [self.webViewHelper loadWebViewWithURLString:self.courseURLString];
    }
}

-(void)reachabilityDidChange:(NSNotification *)notification{
    [super reachabilityDidChange:notification];
    if (self.dataInterface.reachable && !self.webViewHelper.isWebViewLoaded) {
        [self.webViewHelper loadWebViewWithURLString:self.courseURLString];
    }
}

-(void)setNavigationBar{
    [super setNavigationBar];
    
    self.customNavView.lbl_TitleView.text = OEXLocalizedString(@"FIND_COURSES", nil);
    [self.customNavView.btn_Back addTarget:self action:@selector(backPressed) forControlEvents:UIControlEventTouchUpInside];
}

- (BOOL)webViewHelper:(OEXFindCoursesWebViewHelper *)webViewHelper shouldLoadURLWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
    NSString *courseID = nil;
    BOOL emailOptIn = false;
    [self parseURL:request.URL getCourseID:&courseID emailOptIn:&emailOptIn];
    if(courseID != nil) {
        [self enrollInCourseWithCourseID:courseID emailOptIn:emailOptIn];
        return NO;
    }
    return YES;
}

-(void)parseURL:(NSURL *)url getCourseID:(NSString *__autoreleasing *)courseID emailOptIn:(BOOL *)emailOptIn{
    if([url.scheme isEqualToString:OEXFindCoursesLinkURLScheme] && [url.oex_hostlessPath isEqualToString:OEXFindCoursesEnrollPath]) {
        NSDictionary* queryParameters = url.oex_queryParameters;
        *courseID = queryParameters[OEXCourseEnrollURLCourseIDKey];
        *emailOptIn = [queryParameters[OEXCourseEnrollURLEmailOptInKey] boolValue];
    }
}

-(void)enrollInCourseWithCourseID:(NSString *)courseID emailOptIn:(BOOL)emailOptIn {
    BOOL enrollmentExists = NO;
    NSArray *coursesArray = [[OEXInterface sharedInterface] courses];
    for (OEXUserCourseEnrollment * courseEnrollment in coursesArray) {
        OEXCourse * course = courseEnrollment.course;
        if ([course.course_id isEqualToString:courseID]) {
            enrollmentExists = YES;
        }
    }
    
    if (enrollmentExists) {
        OEXEnrollmentMessage *message = [[OEXEnrollmentMessage alloc] init];
        message.messageBody = OEXLocalizedString(@"FIND_COURSES_ALREADY_ENROLLED_MESSAGE", nil);
        message.shouldReloadTable = NO;
        [self showMainScreenWithMessage:message];
        return;
    }

    OEXNetworkManager *networkManager = [OEXNetworkManager sharedManager];
    
    NSDictionary *enrollmentDictionary = @{@"course_details":@{@"course_id": courseID, @"email_opt_in":@(emailOptIn)}};
    
    NSData *enrollmentJSONData = [NSJSONSerialization dataWithJSONObject:enrollmentDictionary options:0 error:nil];
    
    [networkManager callAuthorizedWebServiceWithURLPath:URL_COURSE_ENROLLMENT method:OEXHTTPMethodPOST body:enrollmentJSONData completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
        if (httpResponse.statusCode == 200) {
            OEXEnrollmentMessage *message = [[OEXEnrollmentMessage alloc] init];
            message.messageBody = OEXLocalizedString(@"FIND_COURSES_ENROLLMENT_SUCCESSFUL_MESSAGE", nil);
            message.shouldReloadTable = YES;
            if ([NSThread isMainThread]) {
                [self showMainScreenWithMessage:message];
            }
            else{
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self showMainScreenWithMessage:message];
                });
            }
            return;
        }
        if ([NSThread isMainThread]) {
            [self showEnrollmentError];
        }
        else{
            dispatch_async(dispatch_get_main_queue(), ^{
                [self showEnrollmentError];
            });
        }
    }];
}

-(void)showMainScreenWithMessage:(OEXEnrollmentMessage *)message{
    [self.revealViewController.rearViewController performSegueWithIdentifier:@"showCourse" sender:self];
    [self performSelector:@selector(postEnrollmentSuccessNotification:) withObject:message afterDelay:0.5];
}

-(void)showEnrollmentError{
    [[OEXFlowErrorViewController sharedInstance] showErrorWithTitle:OEXLocalizedString(@"FIND_COURSES_ENROLLMENT_ERROR_TITLE", nil) message:OEXLocalizedString(@"FIND_COURSES_ENROLLMENT_ERROR_DESCRIPTION", nil) onViewController:self.view shouldHide:YES];
}

-(void)postEnrollmentSuccessNotification:(NSString *)message{
    [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_COURSE_ENROLLMENT_SUCCESS object:message];
}

@end
