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

typedef enum : NSUInteger
{
    OEXMySettingsAlertTagNone,
    OEXMySettingsAlertTagWifiOnly
} OEXMySettingsAlertTag;

@interface OEXMySettingsViewController () <UITableViewDataSource, UITableViewDelegate>

@property (strong, nonatomic) IBOutlet UITableViewCell* wifiOnlyCell;
@property (weak, nonatomic) IBOutlet UISwitch* wifiOnlySwitch;
@property (weak, nonatomic) IBOutlet UILabel *subtitleLabel;
@property (strong, nonatomic) IBOutlet UILabel *titleLabel;

@end

@implementation OEXMySettingsViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    [[self.dataInterface progressViews] addObject:self.customProgressBar];
    [[self.dataInterface progressViews] addObject:self.showDownloadsButton];
    [self.wifiOnlySwitch setOn:[OEXInterface shouldDownloadOnlyOnWifi]];
    
    [[OEXStyles sharedStyles] applyMockNavigationBarStyleToView:self.customNavView label:self.customNavView.lbl_TitleView leftIconButton:self.customNavView.btn_Back];
    
    //UILabel now respects RTL
    [self.subtitleLabel setTextAlignment:NSTextAlignmentNatural];
    
    self.wifiOnlyCell.accessibilityLabel = [NSString stringWithFormat:@"%@ , %@", self.titleLabel.text, self.subtitleLabel.text ];
}

- (void)setNavigationBar {
    [super setNavigationBar];

    self.customNavView.lbl_TitleView.text = [Strings settings];
    for(UIView* view in self.customNavView.subviews) {
        if([view isKindOfClass:[UIButton class]]) {
            [((UIButton*)view)setImage : nil forState : UIControlStateNormal];
        }
    }
    [self.customNavView.btn_Back setImage:[UIImage MenuIcon] forState:UIControlStateNormal];
    [self.customNavView.btn_Back setFrame:CGRectMake(8, 31, 22, 22)];
    [self.customNavView.btn_Back addTarget:self action:@selector(backNavigationPressed) forControlEvents:UIControlEventTouchUpInside];
}

- (void)backNavigationPressed {
    [self toggleReveal];
}

- (void)toggleReveal {
    [self.revealViewController toggleDrawerAnimated:YES];
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
        UIAlertView* alert = [[UIAlertView alloc] initWithTitle:[Strings cellularDownloadEnabledTitle]
                                                        message:[Strings cellularDownloadEnabledMessage]
                                                       delegate:self
                                              cancelButtonTitle:[Strings allow]
                                              otherButtonTitles:[Strings doNotAllow], nil];
        alert.tag = OEXMySettingsAlertTagWifiOnly;
        [alert show];
    }
    else {
        [OEXInterface setDownloadOnlyOnWifiPref:self.wifiOnlySwitch.isOn];
    }
}

- (void)alertView:(UIAlertView*)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    switch(alertView.tag) {
        case OEXMySettingsAlertTagWifiOnly: {
            if(buttonIndex == 1) {
                [self.wifiOnlySwitch setOn:YES animated:YES];
            }
            [OEXInterface setDownloadOnlyOnWifiPref:self.wifiOnlySwitch.isOn];
        }
        break;

        default:
            break;
    }
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return [OEXStyles sharedStyles].standardStatusBarStyle;
}

@end
