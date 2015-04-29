//
//  OEXRouter.m
//  edXVideoLocker
//
//  Created by Akiva Leffert on 1/29/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

#import <Masonry/Masonry.h>

#import "OEXRouter.h"

#import "OEXAnalytics.h"
#import "OEXConfig.h"
#import "OEXCourseDashboardViewController.h"
#import "OEXCustomTabBarViewViewController.h"
#import "OEXInterface.h"
#import "OEXLoginSplashViewController.h"
#import "OEXLoginViewController.h"
#import "OEXPushSettingsManager.h"
#import "OEXRegistrationViewController.h"
#import "OEXSession.h"
#import "SWRevealViewController.h"

static OEXRouter* sSharedRouter;

@implementation OEXRouterEnvironment

- (id)initWithAnalytics:(OEXAnalytics*)analytics
                 config:(OEXConfig*)config
              interface:(OEXInterface*)interface
    pushSettingsManager:(OEXPushSettingsManager*)pushSettingsManager
                session:(OEXSession *)session
                 styles:(OEXStyles*)styles {
    self = [super init];
    if(self != nil) {
        _analytics = analytics;
        _config = config;
        _interface = interface;
        _pushSettingsManager = pushSettingsManager;
        _session = session;
        _styles = styles;
    }
    return self;
}
@end

@interface OEXRouter () <
OEXLoginViewControllerDelegate,
OEXRegistrationViewControllerDelegate
>

@property (strong, nonatomic) UIStoryboard* mainStoryboard;
@property (strong, nonatomic) OEXRouterEnvironment* environment;

@property (strong, nonatomic) UIViewController* containerViewController;
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
        self.containerViewController = [[UIViewController alloc] initWithNibName:nil bundle:nil];
    }
    return self;
}

- (void)openInWindow:(UIWindow*)window {
    window.rootViewController = self.containerViewController;
    
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
    [self makeContentControllerCurrent:self.revealController];
}

- (OEXCustomTabBarViewViewController*)tabControllerForCourse:(OEXCourse*)course {
    
    OEXCustomTabBarViewViewController* courseController = [self.mainStoryboard instantiateViewControllerWithIdentifier:@"CustomTabBarView"];
    courseController.course = course;
    courseController.environment = [[OEXCustomTabBarViewViewControllerEnvironment alloc]
                                    initWithAnalytics:self.environment.analytics
                                    config:self.environment.config
                                    pushSettingsManager:self.environment.pushSettingsManager
                                    styles:self.environment.styles];
    return courseController;
}

- (UIViewController*)controllerForCourse:(OEXCourse*)course {
    if([self.environment.config shouldEnableNewCourseNavigation]) {
        OEXCourseDashboardViewControllerEnvironment* environment = [[OEXCourseDashboardViewControllerEnvironment alloc] initWithConfig:self.environment.config router:self];
        OEXCourseDashboardViewController* controller = [[OEXCourseDashboardViewController alloc] initWithEnvironment:environment course:course];
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
    OEXLoginViewController* loginController = [self.mainStoryboard instantiateViewControllerWithIdentifier:@"LoginView"];
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

- (void)showAnnouncementsForCourseWithID:(NSString *)courseID {
    // TODO: Route through new course organization if the [OEXConfig shouldEnableNewCourseNavigation] flag is set
    OEXCourse* course = [self.environment.interface courseWithID:courseID];
    OEXCustomTabBarViewViewController* courseController;
    
    if(course == nil) {
        // Couldn't find course so skip
        // TODO: Load the course remotely from its id
        return;
    }
    
    UINavigationController* navigation = OEXSafeCastAsClass(self.revealController.frontViewController, UINavigationController);
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
