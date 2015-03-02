//
//  OEXRearTableViewController.h
//  edXVideoLocker
//
//  Created by Nirbhay Agarwal on 16/05/14.
//  Copyright (c) 2014 edX. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "OEXInterface.h"
@class OEXCustomLabel;

@interface OEXRearTableViewController : UITableViewController <UIAlertViewDelegate>

- (IBAction)logoutClicked:(id)sender;

@property (weak, nonatomic) IBOutlet OEXCustomLabel *userNameLabel;
@property (weak, nonatomic) IBOutlet OEXCustomLabel *userEmailLabel;
@property (weak, nonatomic) IBOutlet OEXCustomLabel *lbl_AppVersion;

@property (weak, nonatomic) IBOutlet UISwitch *wifiOnlySwitch;
- (IBAction)wifiOnlySwitchChanges:(id)sender;
@end
