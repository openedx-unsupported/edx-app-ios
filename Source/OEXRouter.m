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
#import "OEXFindCoursesViewController.h"
#import "OEXInterface.h"
#import "OEXLoginSplashViewController.h"
#import "OEXLoginViewController.h"
#import "OEXPushSettingsManager.h"
#import "OEXRegistrationViewController.h"
#import "OEXSession.h"
#import "OEXDownloadViewController.h"
#import "OEXCourse.h"
#import "SWRevealViewController.h"


static OEXRouter* sSharedRouter;

NSString* OEXSideNavigationChangedStateNotification = @"OEXSideNavigationChangedStateNotification";
NSString* OEXSideNavigationChangedStateKey = @"OEXSideNavigationChangedStateKey";

@interface OEXRouter () <
OEXLoginViewControllerDelegate,
OEXRegistrationViewControllerDelegate
>

@property (strong, nonatomic) UIStoryboard* mainStoryboard;
@property (strong, nonatomic) RouterEnvironment* environment;

@property (strong, nonatomic) SingleChildContainingViewController* containerViewController;
@property (strong, nonatomic) UIViewController* currentContentController;

@property (strong, nonatomic) RevealViewController* revealController;
@property (strong, nonatomic) void(^registrationCompletion)(void);

@end

@implementation OEXRouter

+ (void)setSharedRouter:(OEXRouter*)router {
    sSharedRouter = router;
}

+ (instancetype)sharedRouter {
    return sSharedRouter;
}

- (id)initWithEnvironment:(RouterEnvironment *)environment {
    self = [super init];
    if(self != nil) {
        environment.router = self;
        self.mainStoryboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
        self.environment = environment;
        self.containerViewController = [[SingleChildContainingViewController alloc] initWithNibName:nil bundle:nil];
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

- (void)showLoggedInContent {
    [self removeCurrentContentController];
    
    OEXUserDetails* currentUser = self.environment.session.currentUser;
    [self.environment.analytics identifyUser:currentUser];
    
    self.revealController = [self.mainStoryboard instantiateViewControllerWithIdentifier:@"SideNavigationContainer"];
    self.revealController.delegate = self.revealController;
    [self showMyCoursesAnimated:NO pushingCourseWithID:nil];
    
    UIViewController* rearController = [self.mainStoryboard instantiateViewControllerWithIdentifier:@"RearViewController"];
    [self.revealController setDrawerViewControllerWithController:rearController animated:NO];
    [self makeContentControllerCurrent:self.revealController];
}

- (void)showLoginScreenFromController:(UIViewController*)controller completion:(void(^)(void))completion {
    [self presentViewController:[self loginViewController] fromController:[controller topMostController] completion:completion];
}

- (UINavigationController *) loginViewController {
    OEXLoginViewController* loginController = [[UIStoryboard storyboardWithName:@"OEXLoginViewController" bundle:nil] instantiateViewControllerWithIdentifier:@"LoginView"];
    loginController.delegate = self;
    loginController.environment = self.environment;
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:loginController];
    
    return navController;
}

- (void)showSignUpScreenFromController:(UIViewController*)controller completion:(void(^)(void))completion {
    self.registrationCompletion = completion;
    OEXRegistrationViewController* registrationController = [[OEXRegistrationViewController alloc] initWithEnvironment:self.environment];
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:registrationController];
    registrationController.delegate = self;
    
    [self presentViewController:navController fromController:[controller topMostController] completion:nil];
}

- (void)presentViewController:(UIViewController*)controller fromController:(UIViewController*)fromController completion:(void(^)(void))completion {
    if (fromController == nil) {
        fromController = self.containerViewController;
    }

    [fromController presentViewController:controller animated:YES completion:completion];
}

- (void)showLoggedOutScreen {
    [self showLoginScreenFromController:nil completion:^{
        [self showSplash];
    }];
    
}

- (void)showAnnouncementsForCourseWithID:(NSString *)courseID {
    UINavigationController* navigation = OEXSafeCastAsClass(self.revealController.frontViewController, UINavigationController);
    CourseAnnouncementsViewController* currentController = OEXSafeCastAsClass(navigation.topViewController, CourseAnnouncementsViewController);
    BOOL showingChosenCourse = [currentController.courseID isEqual:courseID];
    
    if(!showingChosenCourse) { 
        CourseAnnouncementsViewController* announcementController = [[CourseAnnouncementsViewController alloc] initWithEnvironment:self.environment courseID:courseID];
        [navigation pushViewController:announcementController animated:YES];
    }
}

- (UIBarButtonItem*)showNavigationBarItem {
    UIBarButtonItem* item = [[UIBarButtonItem alloc] initWithImage:[UIImage MenuIcon] style:UIBarButtonItemStylePlain target:self action:@selector(showSidebar:)];
    item.accessibilityLabel = [Strings accessibilityMenu];
    item.accessibilityIdentifier = @"navigation-bar-button";
    
    return item;
}

- (void)showSidebar:(id)sender {
    [self.revealController toggleDrawerAnimatedWithAnimated:YES];
}

- (void)showContentStackWithRootController:(UIViewController*)controller animated:(BOOL)animated {
    controller.navigationItem.leftBarButtonItem = [self showNavigationBarItem];
    NSAssert( self.revealController != nil, @"oops! must have a revealViewController" );
    
    [controller.view addGestureRecognizer:self.revealController.panGestureRecognizer];
    UINavigationController* navigationController = [[ForwardingNavigationController alloc] initWithRootViewController:controller];
    [self.revealController pushFrontViewController:navigationController animated:animated];
}

- (void)showDownloadsFromViewController:(UIViewController*)controller {
    OEXDownloadViewController* vc = [[UIStoryboard storyboardWithName:@"OEXDownloadViewController" bundle:nil] instantiateViewControllerWithIdentifier:@"OEXDownloadViewController"];
    [controller.navigationController pushViewController:vc animated:YES];
}

- (void)showMySettings {
    OEXMySettingsViewController* controller = [[OEXMySettingsViewController alloc] initWithNibName:nil bundle:nil];
    [self showContentStackWithRootController:controller animated:YES];
}

#pragma Delegate Implementations

- (void)registrationViewControllerDidRegister:(OEXRegistrationViewController *)controller completion:(void (^)(void))completion {
    [self showLoggedInContent];
    [controller dismissViewControllerAnimated:YES completion:completion];
    if (self.registrationCompletion) {
        self.registrationCompletion();
        self.registrationCompletion = nil;
    }
}

- (void)loginViewControllerDidLogin:(OEXLoginViewController *)loginController {
    [self showLoggedInContent];
    [loginController dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark Testing

@end

@implementation OEXRouter(Testing)

- (NSArray*)t_navigationHierarchy {
    return OEXSafeCastAsClass(self.revealController.frontViewController, UINavigationController).viewControllers ?: @[];
}

- (BOOL)t_showingLogin {
    return [self.currentContentController isKindOfClass:[OEXLoginSplashViewController class]];
}

- (BOOL)t_hasDrawerController {
    return self.revealController.drawerViewController != nil;
}

@end
