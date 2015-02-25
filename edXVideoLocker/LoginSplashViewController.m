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
@end

@implementation LoginSplashViewController

-(void)viewDidLoad{
    [super viewDidLoad];
    if([OEXSession activeSession]){
        [[OEXRouter sharedRouter] showLoginScreenFromController:self animated:NO];
    }
}

-(IBAction)singInBtnPressed:(id)sender{
    [[OEXRouter sharedRouter] showLoginScreenFromController:self animated:YES];
}

-(IBAction)signUpBtnPressed:(id)sender{
    
    OEXRegistrationViewController *registrationViewcontroller=[[OEXRegistrationViewController alloc] init];
    [self.navigationController pushViewController:registrationViewcontroller animated:YES];
}


@end
