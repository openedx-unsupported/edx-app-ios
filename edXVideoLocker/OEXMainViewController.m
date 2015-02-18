//
//  OEXMainViewController.m
//  edXVideoLocker
//
//  Created by Jotiram Bhagat on 16/02/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

#import "OEXMainViewController.h"
#import "OEXRegistrationViewController.h"
#import "OEXRouter.h"
@interface OEXMainViewController ()
@end

@implementation OEXMainViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(IBAction)singInBtnPressed:(id)sender{
    
    [[OEXRouter sharedRouter] showLoginScreenFromController:self];
    
}

-(IBAction)signUpBtnPressed:(id)sender{
    
    OEXRegistrationViewController *registrationViewcontroller=[[OEXRegistrationViewController alloc] init];
    [self.navigationController pushViewController:registrationViewcontroller animated:YES];
}


@end
