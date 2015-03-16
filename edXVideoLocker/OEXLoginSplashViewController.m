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

-(void)viewDidLoad {
    [super viewDidLoad];

    [self.signInButton setTitle:OEXLocalizedString(@"LOGIN_SPLASH_SIGN_IN", nil) forState:UIControlStateNormal];
    [self.signUpButton setTitle:OEXLocalizedString(@"LOGIN_SPLASH_SIGN_UP", nil) forState:UIControlStateNormal];
    if([OEXSession activeSession]) {
        [[OEXRouter sharedRouter] showLoginScreenFromController:self animated:NO];
    }
}

-(IBAction)singInBtnPressed:(id)sender {
    [[OEXRouter sharedRouter] showLoginScreenFromController:self animated:YES];
}

-(IBAction)signUpBtnPressed:(id)sender {
    [[OEXRouter sharedRouter] showSignUpScreenFromController:self animated:YES];
}

@end
