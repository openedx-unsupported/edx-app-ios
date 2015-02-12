//
//  OEXCourseInfoViewController.m
//  edXVideoLocker
//
//  Created by Abhradeep on 03/02/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

#import "OEXCourseInfoViewController.h"
#import "OEXURLSessionManager.h"
#import "OEXNetworkConstants.h"
#import "OEXStatusMessageViewController.h"
#import "OEXFlowErrorViewController.h"
#import "OEXInterface.h"
#import "OEXUserCourseEnrollment.h"
#import "OEXCourse.h"
#import "OEXFrontCourseViewController.h"

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
    if (self.dataInterface.reachable) {
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
        [[OEXFlowErrorViewController sharedInstance] showErrorWithTitle:@"Enrollment Error" message:@"You are already enrolled in this course" onViewController:self.view shouldHide:YES];
        return;
    }

    OEXURLSessionManager *urlSessionManager = [OEXURLSessionManager sharedURLSessionManager];
    
    NSDictionary *enrollmentDictionary = @{@"course_details":@{@"course_id": courseID, @"email_opt_in":emailOptIn}};
    
    NSData *enrollmentJSONData = [NSJSONSerialization dataWithJSONObject:enrollmentDictionary options:0 error:nil];
    
    [urlSessionManager callWebServiceWithURLPath:URL_COURSE_ENROLLMENT method:@"POST" body:enrollmentJSONData completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
        if (httpResponse.statusCode == 200) {
            [self.revealViewController.rearViewController performSegueWithIdentifier:@"showCourse" sender:self];
            return;
        }
        [[OEXFlowErrorViewController sharedInstance] showErrorWithTitle:@"Enrollment Error" message:@"An error occurred while creating the new course enrollment" onViewController:self.view shouldHide:YES];
    }];
}

-(void)dealloc{
    self.initialURLString = nil;
}

@end
