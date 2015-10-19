//
//  LoginSplashViewController.m
//  edXVideoLocker
//
//  Created by Jotiram Bhagat on 16/02/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

#import "OEXLoginSplashViewController.h"

#import "edX-Swift.h"

#import "OEXRouter.h"
#import "OEXLoginViewController.h"
#import "OEXSession.h"

@implementation OEXLoginSplashViewControllerEnvironment

- (id)initWithRouter:(OEXRouter *)router {
    self = [super init];
    if(self != nil) {
        _router = router;
    }
    return self;
}

@end

@interface OEXLoginSplashViewController ()

@property (strong, nonatomic) IBOutlet UIButton* signInButton;
@property (strong, nonatomic) IBOutlet UIButton* signUpButton;

@property (strong, nonatomic) OEXLoginSplashViewControllerEnvironment* environment;

@end

@implementation OEXLoginSplashViewController

- (id)initWithEnvironment:(OEXLoginSplashViewControllerEnvironment*)environment {
    self = [super initWithNibName:nil bundle:nil];
    if(self != nil) {
        self.environment = environment;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    [self.signInButton setTitle:[Strings loginSplashSignIn] forState:UIControlStateNormal];
    [self.signUpButton setTitle:[Strings loginSplashSignUp] forState:UIControlStateNormal];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:YES animated:animated];
}

- (IBAction)showLogin:(id)sender {
    [self.environment.router showLoginScreenFromController:self completion:nil];
}

- (IBAction)showRegistration:(id)sender {
    [self.environment.router showSignUpScreenFromController:self];
}

@end
