//
//  OEXMySettingsViewController.m
//  edXVideoLocker
//
//  Created by Abhradeep on 20/02/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

#import "OEXMySettingsViewController.h"

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

@end

@implementation OEXMySettingsViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    if(self.revealViewController) {
        self.revealViewController.delegate = self;
        [self.view addGestureRecognizer:self.revealViewController.panGestureRecognizer];
    }

    self.overlayButton.alpha = 0.0f;

    [[self.dataInterface progressViews] addObject:self.customProgressBar];
    [[self.dataInterface progressViews] addObject:self.showDownloadsButton];
    [self.wifiOnlySwitch setOn:[OEXInterface shouldDownloadOnlyOnWifi]];
    
    [[OEXStyles sharedStyles] applyMockNavigationBarStyleToView:self.customNavView label:self.customNavView.lbl_TitleView leftIconButton:self.customNavView.btn_Back];
    
    //UILabel now respects RTL
    [self.subtitleLabel setTextAlignment:NSTextAlignmentNatural];
}

- (void)setExclusiveTouches {
    [super setExclusiveTouches];
    self.overlayButton.exclusiveTouch = YES;
}

- (void)setNavigationBar {
    [super setNavigationBar];

    self.customNavView.lbl_TitleView.text = OEXLocalizedString(@"SETTINGS", nil);
    for(UIView* view in self.customNavView.subviews) {
        if([view isKindOfClass:[UIButton class]]) {
            [((UIButton*)view)setImage : nil forState : UIControlStateNormal];
        }
    }
    [self.customNavView.btn_Back setImage:[UIImage imageNamed:@"ic_navigation.png"] forState:UIControlStateNormal ];
    [self.customNavView.btn_Back setFrame:CGRectMake(8, 31, 22, 22)];
    [self.customNavView.btn_Back addTarget:self action:@selector(backNavigationPressed) forControlEvents:UIControlEventTouchUpInside];
}

- (void)backNavigationPressed {
    self.view.userInteractionEnabled = NO;
    self.overlayButton.hidden = NO;
    [self.navigationController popToViewController:self animated:NO];
    [UIView animateWithDuration:0.9 animations:^{
        self.overlayButton.alpha = 0.5;
    }];
    [self performSelector:@selector(toggleReveal) withObject:nil afterDelay:0.2];
}

- (void)toggleReveal {
    [self.revealViewController revealToggle:self.customNavView.btn_Back];
}

- (void)revealController:(SWRevealViewController*)revealController didMoveToPosition:(FrontViewPosition)position {
    self.view.userInteractionEnabled = YES;
    [super revealController:revealController didMoveToPosition:position];
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
        UIAlertView* alert = [[UIAlertView alloc] initWithTitle:[OEXLocalizedString(@"CELLULAR_DOWNLOAD_ENABLED_TITLE", nil) oex_uppercaseStringInCurrentLocale]
                                                        message:OEXLocalizedString(@"CELLULAR_DOWNLOAD_ENABLED_MESSAGE", nil)
                                                       delegate:self
                                              cancelButtonTitle:[OEXLocalizedString(@"ALLOW", nil) oex_uppercaseStringInCurrentLocale]
                                              otherButtonTitles:[OEXLocalizedString(@"DO_NOT_ALLOW", nil) oex_uppercaseStringInCurrentLocale], nil];
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

@end
