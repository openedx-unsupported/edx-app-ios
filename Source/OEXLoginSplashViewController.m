//
//  LoginSplashViewController.m
//  edXVideoLocker
//
//  Created by Jotiram Bhagat on 16/02/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

#import "OEXLoginSplashViewController.h"
#import "OEXRouter.h"
#import "OEXLoginViewController.h"
#import "OEXSession.h"
@interface OEXLoginSplashViewController ()
@property(weak, nonatomic) IBOutlet UIButton* signInButton;
@property(weak, nonatomic) IBOutlet UIButton* signUpButton;
@end

@implementation OEXLoginSplashViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    [self.signInButton setTitle:OEXLocalizedString(@"LOGIN_SPLASH_SIGN_IN", nil) forState:UIControlStateNormal];
    [self.signUpButton setTitle:OEXLocalizedString(@"LOGIN_SPLASH_SIGN_UP", nil) forState:UIControlStateNormal];
    if([OEXSession sharedSession].currentUser != nil) {
        /// When the login screen is shown, it then check if the user has a token and hides itself
        [[OEXRouter sharedRouter] showLoginScreenFromController:self animated:NO];
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:YES animated:animated];
}

- (IBAction)showLogin:(id)sender {
    [[OEXRouter sharedRouter] showLoginScreenFromController:self animated:YES];
}

- (IBAction)showRegistration:(id)sender {
    [[OEXRouter sharedRouter] showSignUpScreenFromController:self animated:YES];
}

@end
