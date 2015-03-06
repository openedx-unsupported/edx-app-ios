//
//  LoginSplashViewController.m
//  edXVideoLocker
//
//  Created by Jotiram Bhagat on 16/02/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

#import "LoginSplashViewController.h"
#import "OEXRegistrationViewController.h"
#import "OEXRouter.h"
#import "OEXLoginViewController.h"
#import "OEXSession.h"
@interface LoginSplashViewController ()
@property (strong, nonatomic) UIStoryboard* mainStoryboard;

@end

@implementation LoginSplashViewController

-(void)viewDidLoad{
    [super viewDidLoad];
    self.mainStoryboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    if([OEXSession activeSession]){
        [[OEXRouter sharedRouter] showLoginScreenFromController:self animated:NO];
    }
}

-(IBAction)singInBtnPressed:(id)sender{
    OEXLoginViewController *loginController=[self.mainStoryboard instantiateViewControllerWithIdentifier:@"LoginView"];
    [[OEXRouter sharedRouter] pushAnimationFromBottomfromController:self toController:loginController];
    
}

-(IBAction)signUpBtnPressed:(id)sender{
    [[OEXRouter sharedRouter] showSignUpScreenFromController:self animated:YES];
}


@end
