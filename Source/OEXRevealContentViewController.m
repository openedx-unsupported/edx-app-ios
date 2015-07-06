//
//  OEXRevealContentViewController.m
//  edXVideoLocker
//
//  Created by Abhradeep on 16/02/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

#import "OEXRevealContentViewController+Protected.h"
#import <MessageUI/MessageUI.h>
#import "OEXAppDelegate.h"
#import "OEXConfig.h"

#import "NSString+OEXFormatting.h"

@interface OEXRevealContentViewController () <MFMailComposeViewControllerDelegate>

@end

@implementation OEXRevealContentViewController

- (IBAction)overlayButtonTapped:(id)sender {
    [self.revealViewController revealToggleAnimated:YES];
}

- (void)revealController:(SWRevealViewController*)revealController didMoveToPosition:(FrontViewPosition)position {
    if(position == FrontViewPositionLeft) {
        [UIView animateWithDuration:0.2 delay:0.0 options:0 animations:^{
            self.overlayButton.alpha = 0.0f;
        } completion:^(BOOL finished) {
            self.overlayButton.hidden = YES;
        }];
    }
    else if(position == FrontViewPositionRight) {
        self.overlayButton.hidden = NO;
        [self.navigationController popToViewController:self animated:NO];
        [UIView animateWithDuration:0.5 delay:0 options:0 animations:^{
            self.overlayButton.alpha = 0.5f;
        } completion:^(BOOL finished) {
        }];
    }
}

@end
