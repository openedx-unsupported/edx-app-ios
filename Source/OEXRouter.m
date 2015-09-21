//
//  OEXRouter.m
//  edXVideoLocker
//
//  Created by Akiva Leffert on 1/29/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

#import <Masonry/Masonry.h>

#import "edX-Swift.h"

#import "OEXRouter.h"

#import "OEXAnalytics.h"
#import "OEXConfig.h"
#import "OEXCustomTabBarViewViewController.h"
#import "OEXEnrollmentConfig.h"
#import "OEXFindCourseInterstitialViewController.h"
#import "OEXFindCoursesViewController.h"
#import "OEXInterface.h"
#import "OEXLoginSplashViewController.h"
#import "OEXLoginViewController.h"
#import "OEXPushSettingsManager.h"
#import "OEXRegistrationViewController.h"
#import "OEXSession.h"
#import "OEXDownloadViewController.h"
#import "OEXCourseVideoDownloadTableViewController.h"
#import "OEXMyVideosSubSectionViewController.h"
#import "OEXMyVideosViewController.h"
#import "OEXCourse.h"
#import "OEXGenericCourseTableViewController.h"
#import "OEXFrontCourseViewController.h"
#import "SWRevealViewController.h"

static OEXRouter* sSharedRouter;

@implementation OEXRouterEnvironment

- (id)initWithAnalytics:(OEXAnalytics*)analytics
                 config:(OEXConfig*)config
            dataManager:(DataManager *)dataManager
              interface:(OEXInterface*)interface
                session:(OEXSession *)session
                 styles:(OEXStyles*)styles
         networkManager:(NetworkManager*)networkManager {
    
    self = [super init];
    if(self != nil) {
        _analytics = analytics;
        _config = config;
        _dataManager = dataManager;
        _interface = interface;
        _session = session;
        _styles = styles;
        _networkManager = networkManager;
    }
    return self;
}
@end



@interface OEXSingleChildContainingViewController : UIViewController

@end

@implementation OEXSingleChildContainingViewController

- (UIViewController*)childViewControllerForStatusBarStyle {
    return self.childViewControllers.lastObject;
}

- (UIViewController*)childViewControllerForStatusBarHidden {
    return self.childViewControllers.lastObject;
}

@end

@interface OEXRouter () <
OEXLoginViewControllerDelegate,
OEXRegistrationViewControllerDelegate
>

@property (strong, nonatomic) UIStoryboard* mainStoryboard;
@property (strong, nonatomic) OEXRouterEnvironment* environment;

@property (strong, nonatomic) OEXSingleChildContainingViewController* containerViewController;
@property (strong, nonatomic) UIViewController* currentContentController;

@property (strong, nonatomic) SWRevealViewController* revealController;

@end
@implementation OEXRouter

+ (void)setSharedRouter:(OEXRouter*)router {
    sSharedRouter = router;
}

+ (instancetype)sharedRouter {
    return sSharedRouter;
}

- (id)initWithEnvironment:(OEXRouterEnvironment *)environment {
    self = [super init];
    if(self != nil) {
        self.mainStoryboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
        self.environment = environment;
        self.containerViewController = [[OEXSingleChildContainingViewController alloc] initWithNibName:nil bundle:nil];
    }
    return self;
}

- (id)init {
    return [self initWithEnvironment:nil];
}

- (void)openInWindow:(UIWindow*)window {
    window.rootViewController = self.containerViewController;
    window.tintColor = [self.environment.styles primaryBaseColor];
    
    OEXUserDetails* currentUser = self.environment.session.currentUser;
    if(currentUser == nil) {
        [self showSplash];
    } else {
        [self showLoggedInContent];
    }
}

- (void)removeCurrentContentController {
    [self.currentContentController willMoveToParentViewController:nil];
    [self.currentContentController.view removeFromSuperview];
    [self.currentContentController removeFromParentViewController];
    self.currentContentController = nil;
}

- (void)makeContentControllerCurrent:(UIViewController*)controller {
    [self.containerViewController addChildViewController:controller];
    [self.containerViewController.view addSubview:controller.view];
    [controller.view mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.containerViewController.view);
    }];
    
    [controller didMoveToParentViewController:self.containerViewController];
    self.currentContentController = controller;
}

- (void)showSplash {
    self.revealController = nil;
    [self removeCurrentContentController];
    
    OEXLoginSplashViewControllerEnvironment* splashEnvironment = [[OEXLoginSplashViewControllerEnvironment alloc] initWithRouter:self];
    OEXLoginSplashViewController* splashController = [[OEXLoginSplashViewController alloc] initWithEnvironment:splashEnvironment];
    [self makeContentControllerCurrent:splashController];
}

- (void)showLoggedInContent {
    [self removeCurrentContentController];
    
    OEXUserDetails* currentUser = self.environment.session.currentUser;
    [self.environment.analytics identifyUser:currentUser];
    
    self.revealController = [self.mainStoryboard instantiateViewControllerWithIdentifier:@"SideNavigationContainer"];
    OEXFrontCourseViewController* vc = [[UIStoryboard storyboardWithName:@"OEXFrontCourseViewController" bundle:nil]instantiateViewControllerWithIdentifier:@"MyCourses"];
    UINavigationController *nc = [[ForwardingNavigationController alloc] initWithRootViewController:vc];
    [self.revealController pushFrontViewController:nc animated:YES];
    [self makeContentControllerCurrent:self.revealController];
}

- (OEXCustomTabBarViewViewController*)tabControllerForCourse:(OEXCourse*)course {
    
    OEXCustomTabBarViewViewController* courseController = [[UIStoryboard storyboardWithName:@"OEXCustomTabBarViewViewController" bundle:nil] instantiateViewControllerWithIdentifier:@"CustomTabBarView"];
    courseController.course = course;
    courseController.environment = [[OEXCustomTabBarViewViewControllerEnvironment alloc]
                                    initWithAnalytics:self.environment.analytics
                                    config:self.environment.config
                                    pushSettingsManager:self.environment.dataManager.pushSettings
                                    styles:self.environment.styles];
    return courseController;
}

- (UIViewController*)controllerForCourse:(OEXCourse*)course {
    if([self.environment.config shouldEnableNewCourseNavigation]) {
        CourseDashboardViewControllerEnvironment *environment =
        [[CourseDashboardViewControllerEnvironment alloc]
         initWithAnalytics:self.environment.analytics
         config:self.environment.config
         networkManager: self.environment.networkManager
         router:self
         ];
        CourseDashboardViewController* controller = [[CourseDashboardViewController alloc] initWithEnvironment:environment course:course];
        return controller;
    }
    else {
        return [self tabControllerForCourse:course];
    }
}

- (void)showCourse:(OEXCourse*)course fromController:(UIViewController*)controller {
    UIViewController* courseController = [self controllerForCourse:course];
    [controller.navigationController pushViewController:courseController animated:YES];
}

- (void)showLoginScreenFromController:(UIViewController*)controller completion:(void(^)(void))completion {
    OEXLoginViewController* loginController = [[UIStoryboard storyboardWithName:@"OEXLoginViewController" bundle:nil] instantiateViewControllerWithIdentifier:@"LoginView"];
    loginController.delegate = self;
    
    [self presentViewController:loginController fromController:self.containerViewController completion:completion];
}

- (void)showSignUpScreenFromController:(UIViewController*)controller {
    OEXRegistrationViewControllerEnvironment* registrationEnvironment = [[OEXRegistrationViewControllerEnvironment alloc] initWithAnalytics:self.environment.analytics config:self.environment.config router:self];
    OEXRegistrationViewController* registrationController = [[OEXRegistrationViewController alloc] initWithEnvironment:registrationEnvironment];
    registrationController.delegate = self;
    [self presentViewController:registrationController fromController:self.containerViewController completion:nil];
}

- (void)presentViewController:(UIViewController*)controller fromController:(UIViewController*)presenter completion:(void(^)(void))completion {
    [presenter presentViewController:controller animated:YES completion:completion];
}

- (void)showLoggedOutScreen {
    [self showLoginScreenFromController:nil completion:^{
        [self showSplash];
    }];
    
}

- (void)showFindCourses {
    [[OEXAnalytics sharedAnalytics] trackUserFindsCourses];
    if(self.environment.config.courseEnrollmentConfig.enabled) {
        OEXFindCoursesViewController* findCoursesViewController = [[OEXFindCoursesViewController alloc] init];
        UINavigationController* nc = [[UINavigationController alloc] initWithRootViewController:findCoursesViewController];
        [self.revealController pushFrontViewController:nc animated:YES];
    }
    else {
        OEXFindCourseInterstitialViewController* interstitialViewController = [[OEXFindCourseInterstitialViewController alloc] init];
        [self.containerViewController presentViewController:interstitialViewController animated:YES completion:nil];
    }
}

- (void)showAnnouncementsForCourseWithID:(NSString *)courseID {
    OEXCourse* course = [self.environment.interface courseWithID:courseID];
    UINavigationController* navigation = OEXSafeCastAsClass(self.revealController.frontViewController, UINavigationController);
    if(course == nil) {
        // Couldn't find course so skip
        // TODO: Load the course remotely from its id
        return;
    }
    
    if([self.environment.config shouldEnableNewCourseNavigation]) {
        CourseAnnouncementsViewControllerEnvironment* environment = [[CourseAnnouncementsViewControllerEnvironment alloc] initWithConfig:self.environment.config dataInterface:self.environment.interface router:self styles:self.environment.styles pushSettingsManager:self.environment.dataManager.pushSettings];
        
        CourseAnnouncementsViewController* announcementController = [[CourseAnnouncementsViewController alloc] initWithEnvironment:environment course:course];
        [navigation pushViewController:announcementController animated:true];
    }
    else {
        OEXCustomTabBarViewViewController* courseController;
        // Check if we're already showing announcements for this course
        OEXCustomTabBarViewViewController* currentController = OEXSafeCastAsClass(navigation.topViewController, OEXCustomTabBarViewViewController);
        BOOL showingChosenCourse = [currentController.course.course_id isEqual:courseID];
        if(showingChosenCourse) {
        courseController = currentController;
    }
    
    if(courseController == nil) {
        courseController = [self tabControllerForCourse:course];
        [navigation pushViewController:courseController animated:NO];
    }
    
    [courseController showTab:OEXCourseTabCourseInfo];
    
    }
}

- (void)showCourseVideoDownloadsFromViewController:(UIViewController*) controller forCourse:(OEXCourse*) course lastAccessedVideo:(OEXHelperVideoDownload*) video downloadProgress:(NSArray*) downloadProgress selectedPath:(NSArray*) path {
    OEXCourseVideoDownloadTableViewController* vc = [[UIStoryboard storyboardWithName:@"OEXCourseVideoDownloadTableViewController" bundle:nil] instantiateViewControllerWithIdentifier:@"CourseVideos"];
    vc.course = course;
    vc.lastAccessedVideo = video;
    vc.arr_DownloadProgress = downloadProgress;
    vc.selectedPath = path;
    [controller.navigationController pushViewController:vc animated:YES];
}

- (void)showDownloadsFromViewController:(UIViewController*)controller {
    OEXDownloadViewController* vc = [[UIStoryboard storyboardWithName:@"OEXDownloadViewController" bundle:nil] instantiateViewControllerWithIdentifier:@"OEXDownloadViewController"];
    [controller.navigationController pushViewController:vc animated:YES];
}

- (void)showVideoSubSectionFromViewController:(UIViewController*) controller forCourse:(OEXCourse*) course withCourseData:(NSMutableArray*) courseData{
    OEXMyVideosSubSectionViewController* vc = [[UIStoryboard storyboardWithName:@"OEXMyVideosSubSectionViewController" bundle:nil] instantiateViewControllerWithIdentifier:@"MyVideosSubsection"];
    vc.course = course;
    vc.arr_CourseData = courseData;
    [controller.navigationController pushViewController:vc animated:YES];
}

- (void)showMyVideos {
    OEXMyVideosViewController* vc = [[UIStoryboard storyboardWithName:@"OEXMyVideosViewController" bundle:nil]instantiateViewControllerWithIdentifier:@"MyVideos"];
    NSAssert( self.revealController != nil, @"oops! must have a revealViewController" );
    NSAssert( [self.revealController.frontViewController isKindOfClass: [UINavigationController class]], @"oops!  for this segue we want a permanent navigation controller in the front!" );
    UINavigationController* nc = [[UINavigationController alloc]initWithRootViewController:vc];
    [self.revealController pushFrontViewController:nc animated:YES];
}

- (void)showGenericCoursesFromViewController:(UIViewController*) controller forCourse:(OEXCourse*) course withCourseData:(NSArray*) courseData selectedChapter:(OEXVideoPathEntry*) chapter {
    OEXGenericCourseTableViewController* vc = [[UIStoryboard storyboardWithName:@"OEXGenericCourseTableViewController" bundle:nil]instantiateViewControllerWithIdentifier:@"GenericTableView"];
    vc.course = course;
    vc.arr_TableCourseData = courseData;
    vc.selectedChapter = chapter;
    [controller.navigationController pushViewController:vc animated:YES];
}

- (void)showMyCourses {
    OEXFrontCourseViewController* vc = [[UIStoryboard storyboardWithName:@"OEXFrontCourseViewController" bundle:nil]instantiateViewControllerWithIdentifier:@"MyCourses"];
    NSAssert( self.revealController != nil, @"oops! must have a revealViewController" );
    NSAssert( [self.revealController.frontViewController isKindOfClass: [UINavigationController class]], @"oops!  for this segue we want a permanent navigation controller in the front!" );
    UINavigationController *nc = [[ForwardingNavigationController alloc]initWithRootViewController:vc];
    [self.revealController pushFrontViewController:nc animated:YES];
}

#pragma Delegate Implementations

- (void)registrationViewControllerDidRegister:(OEXRegistrationViewController *)controller completion:(void (^)(void))completion {
    [self showLoggedInContent];
    [controller dismissViewControllerAnimated:YES completion:completion];
}

- (void)loginViewControllerDidLogin:(OEXLoginViewController *)loginController {
    [self showLoggedInContent];
    [loginController dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark Testing


- (NSArray*)t_navigationHierarchy {
    return OEXSafeCastAsClass(self.revealController.frontViewController, UINavigationController).viewControllers;
}

- (BOOL)t_showingLogin {
    return [self.currentContentController isKindOfClass:[OEXLoginSplashViewController class]];
}

@end
