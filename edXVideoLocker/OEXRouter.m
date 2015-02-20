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

- (void)showCourse:(OEXCourse *)course fromController:(UIViewController *)controller {
    OEXCustomTabBarViewViewController *courseController = [self.mainStoryboard instantiateViewControllerWithIdentifier:@"CustomTabBarView"];
    courseController.course = course;
    [controller.navigationController pushViewController:courseController animated:YES];
}

-(void)showLoginScreenFromController:(UIViewController *)controller animated:(BOOL)animated{
    
    OEXLoginViewController *loginController=[self.mainStoryboard instantiateViewControllerWithIdentifier:@"LoginView"];
    [controller.navigationController pushViewController:loginController animated:animated];
}

@end
