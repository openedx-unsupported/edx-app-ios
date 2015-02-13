//
//  OEXCourseInfoViewController.m
//  edXVideoLocker
//
//  Created by Abhradeep on 03/02/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

#import "OEXCourseInfoViewController.h"
#import "OEXNetworkManager.h"
#import "OEXNetworkConstants.h"
#import "OEXStatusMessageViewController.h"
#import "OEXFlowErrorViewController.h"
#import "OEXInterface.h"
#import "OEXUserCourseEnrollment.h"
#import "OEXCourse.h"
#import "OEXFrontCourseViewController.h"
#import "OEXConstants.h"

#define kCourseInfoScreenName @"Course Info"

@interface OEXCourseInfoViewController ()

@end

@implementation OEXCourseInfoViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    if (self.dataInterface.reachable) {
        [self.webViewHelper loadWebViewWithURLString:self.initialURLString];
    }
}

-(void)reachabilityDidChange:(NSNotification *)notification{
    [super reachabilityDidChange:notification];
    if (self.dataInterface.reachable && !self.webViewHelper.isWebViewLoaded) {
        [self.webViewHelper loadWebViewWithURLString:self.initialURLString];
    }
}

-(void)setNavigationBar{
    [super setNavigationBar];
    
    self.customNavView.lbl_TitleView.text = kCourseInfoScreenName;
    [self.customNavView.btn_Back addTarget:self action:@selector(backPressed) forControlEvents:UIControlEventTouchUpInside];
}

-(void)webViewHelper:(OEXFindCoursesWebViewHelper *)webViewHelper userEnrolledWithCourseID:(NSString *)courseID emailOptIn:(NSString *)emailOptIn{
    BOOL enrollmentExists = NO;
    NSArray *coursesArray = [[OEXInterface sharedInterface] courses];
    for (OEXUserCourseEnrollment * courseEnrollment in coursesArray) {
        OEXCourse * course = courseEnrollment.course;
        if ([course.course_id isEqualToString:courseID]) {
            enrollmentExists = YES;
        }
    }
    
    if (enrollmentExists) {
        [self performSelectorOnMainThread:@selector(showMainScreenWithMessage:) withObject:@"You are already enrolled to this course" waitUntilDone:NO];
        return;
    }

    OEXNetworkManager *networkManager = [OEXNetworkManager sharedManager];
    
    NSDictionary *enrollmentDictionary = @{@"course_details":@{@"course_id": courseID, @"email_opt_in":emailOptIn}};
    
    NSData *enrollmentJSONData = [NSJSONSerialization dataWithJSONObject:enrollmentDictionary options:0 error:nil];
    
    [networkManager callAuthorizedWebServiceWithURLPath:URL_COURSE_ENROLLMENT method:OEXHTTPMethodPOST body:enrollmentJSONData completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        NSLog(@"Res: %@ data: %@",response, [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
        if (httpResponse.statusCode == 200) {
            [self performSelectorOnMainThread:@selector(showMainScreenWithMessage:) withObject:@"You are now enrolled to the course" waitUntilDone:NO];
            return;
        }
        [self performSelectorOnMainThread:@selector(showEnrollmentError) withObject:nil waitUntilDone:NO];
    }];
}

-(void)webViewHelper:(OEXFindCoursesWebViewHelper *)webViewHelper shouldOpenURLString:(NSString *)urlString{
    
}

-(void)showMainScreenWithMessage:(NSString *)message{
    [self.revealViewController.rearViewController performSegueWithIdentifier:@"showCourse" sender:self];
    [self performSelector:@selector(postEnrollmentSuccessNotification:) withObject:message afterDelay:0.5];
}

-(void)showEnrollmentError{
    [[OEXFlowErrorViewController sharedInstance] showErrorWithTitle:@"Enrollment Error" message:@"An error occurred while creating the new course enrollment" onViewController:self.view shouldHide:YES];
}

-(void)postEnrollmentSuccessNotification:(NSString *)message{
    [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_COURSE_ENROLLMENT_SUCCESS object:message];
}

@end
