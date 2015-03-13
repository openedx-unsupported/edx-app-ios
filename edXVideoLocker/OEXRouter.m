//
//  OEXRouter.m
//  edXVideoLocker
//
//  Created by Akiva Leffert on 1/29/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

#import "OEXRouter.h"

#import "OEXCustomTabBarViewViewController.h"
#import "OEXLoginViewController.h"
#import "OEXRegistrationViewController.h"

static OEXRouter* sSharedRouter;

@interface OEXRouter ()

@property (strong, nonatomic) UIStoryboard* mainStoryboard;

@end

@implementation OEXRouter

+ (void)setSharedRouter:(OEXRouter *)router {
    sSharedRouter = router;
}

+ (instancetype)sharedRouter {
    return sSharedRouter;
}

- (id)init {
    self = [super init];
    if(self != nil) {
        self.mainStoryboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    }
    return self;
}


- (void)pushAnimationFromBottomfromController:(UIViewController *)fromController toController:(UIViewController *)toController
{
    CATransition* transition = [CATransition animation];
    transition.duration = ANIMATION_DURATION;
    transition.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    transition.type = kCATransitionMoveIn;
    transition.subtype = kCATransitionFromTop;
    [fromController.navigationController.view.layer addAnimation:transition forKey:nil];
    [[fromController navigationController] pushViewController:toController animated:NO];
}

- (void)popAnimationFromBottomFromController:(UIViewController *)fromController
{
    CATransition* transition = [CATransition animation];
    transition.duration = ANIMATION_DURATION;
    transition.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    transition.type = kCATransitionReveal;
    transition.subtype = kCATransitionFromBottom;
    [fromController.navigationController.view.layer addAnimation:transition forKey:nil];
    [[fromController navigationController] popToRootViewControllerAnimated:NO];
}

- (void)showCourse:(OEXCourse *)course fromController:(UIViewController *)controller {
    OEXCustomTabBarViewViewController *courseController = [self.mainStoryboard instantiateViewControllerWithIdentifier:@"CustomTabBarView"];
    courseController.course = course;
    [controller.navigationController pushViewController:courseController animated:YES];
}

-(void)showLoginScreenFromController:(UIViewController *)controller animated:(BOOL)animated{
    
    OEXLoginViewController *loginController=[self.mainStoryboard instantiateViewControllerWithIdentifier:@"LoginView"];

    if(animated){
        [self pushAnimationFromBottomfromController:controller toController:loginController];
    }else{
        [controller.navigationController pushViewController:loginController animated:NO];
    }
    
}

-(void)showSignUpScreenFromController:(UIViewController *)controller animated:(BOOL)animated{
    
    OEXRegistrationViewController *registrationViewcontroller=[[OEXRegistrationViewController alloc] initWithDefaultRegistrationDescription];
    [self pushAnimationFromBottomfromController:controller toController:registrationViewcontroller];
}




@end
