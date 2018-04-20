//
//  OEXMySettingsViewController.m
//  edXVideoLocker
//
//  Created by Abhradeep on 20/02/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

#import "OEXMySettingsViewController.h"

#import "edX-Swift.h"

#import "NSString+OEXFormatting.h"
#import "OEXInterface.h"
#import "OEXStyles.h"

typedef NS_ENUM(NSUInteger, OEXMySettingsAlertTag) {
    OEXMySettingsAlertTagNone,
    OEXMySettingsAlertTagWifiOnly
};

@interface OEXMySettingsViewController () <UITableViewDataSource, UITableViewDelegate>

@property (strong, nonatomic) IBOutlet UITableViewCell* wifiOnlyCell;
@property (weak, nonatomic) IBOutlet UISwitch* wifiOnlySwitch;
@property (weak, nonatomic) IBOutlet UILabel *subtitleLabel;
@property (strong, nonatomic) IBOutlet UILabel *titleLabel;

@end

@implementation OEXMySettingsViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    [self.wifiOnlySwitch setOn:[OEXInterface shouldDownloadOnlyOnWifi]];
    
    [self.subtitleLabel setTextAlignment:NSTextAlignmentNatural];
    [self.titleLabel setText:[Strings wifiOnlyTitle]];
    [self.subtitleLabel setText:[Strings wifiOnlyDetailMessage]];
    
    self.wifiOnlyCell.accessibilityLabel = [NSString stringWithFormat:@"%@ , %@", self.titleLabel.text, self.subtitleLabel.text];
    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"" style:UIBarButtonItemStylePlain target:nil action:nil];
    self.navigationItem.title = [Strings settings];
}

- (void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [[OEXAnalytics sharedAnalytics] trackScreenWithName:OEXAnalyticsScreenSettings];
}

- (NSInteger)tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section {
    return 1;
}

- (CGFloat)tableView:(UITableView*)tableView heightForRowAtIndexPath:(NSIndexPath*)indexPath {
    return self.wifiOnlyCell.bounds.size.height;
}

- (UITableViewCell*)tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath {
    return self.wifiOnlyCell;
}

- (IBAction)wifiOnlySwitchValueChanged:(id)sender {
    if(!self.wifiOnlySwitch.isOn) {
        
        [[UIAlertController alloc] showInViewController:self title:[Strings cellularDownloadEnabledTitle] message:[Strings cellularDownloadEnabledMessage] preferredStyle:UIAlertControllerStyleAlert cancelButtonTitle:[Strings allow] destructiveButtonTitle:nil otherButtonsTitle:@[[Strings doNotAllow]] tapBlock:^(UIAlertController *alertController, UIAlertAction *alertAction, NSInteger buttonIndex) {
            // Allow
            if ( buttonIndex == 0 ) {
                [OEXInterface setDownloadOnlyOnWifiPref:self.wifiOnlySwitch.isOn];
            }
            // Don't Allow
            else if ( buttonIndex == 1 ) {
                [self.wifiOnlySwitch setOn:YES animated:YES];
            }
        } textFieldWithConfigurationHandler:nil];
    }
    else {
        [OEXInterface setDownloadOnlyOnWifiPref:self.wifiOnlySwitch.isOn];
    }
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return [OEXStyles sharedStyles].standardStatusBarStyle;
}

@end
