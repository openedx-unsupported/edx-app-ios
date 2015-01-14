//
//  RearTableViewController.h
//  edXVideoLocker
//
//  Created by Nirbhay Agarwal on 16/05/14.
//  Copyright (c) 2014 edX. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "EdXInterface.h"
@class CustomLabel;

@interface RearTableViewController : UITableViewController <UIAlertViewDelegate>

- (IBAction)logoutClicked:(id)sender;

@property (weak, nonatomic) IBOutlet UIButton *btn_Logout;
@property (weak, nonatomic) IBOutlet CustomLabel *userNameLabel;
@property (weak, nonatomic) IBOutlet CustomLabel *userEmailLabel;
@property (weak, nonatomic) IBOutlet CustomLabel *lbl_AppVersion;

@property (weak, nonatomic) IBOutlet UISwitch *wifiOnlySwitch;
- (IBAction)wifiOnlySwitchChanges:(id)sender;
@end
