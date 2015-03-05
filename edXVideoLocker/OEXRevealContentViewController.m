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

@interface OEXRevealContentViewController ()<MFMailComposeViewControllerDelegate>

@end

@implementation OEXRevealContentViewController

- (IBAction)overlayButtonTapped:(id)sender {
    [self.revealViewController revealToggleAnimated:YES];
}

- (void)revealController:(SWRevealViewController *)revealController didMoveToPosition:(FrontViewPosition)position{
    if (position == FrontViewPositionLeft){
        [UIView animateWithDuration:0.2 delay:0.0 options:0 animations:^{
            self.overlayButton.alpha = 0.0f;
        } completion:^(BOOL finished) {
            self.overlayButton.hidden = YES;
        }];
        
        OEXAppDelegate *appDelegate = (OEXAppDelegate *)[[UIApplication sharedApplication] delegate];
        if (appDelegate.pendingMailComposerLaunch) {
            appDelegate.pendingMailComposerLaunch = NO;
            if (![MFMailComposeViewController canSendMail]) {
                [[[UIAlertView alloc] initWithTitle:OEXLocalizedString(@"EMAIL_ACCOUNT_NOT_SET_UP_TITLE", nil)
                                            message:OEXLocalizedString(@"EMAIL_ACCOUNT_NOT_SET_UP_MESSAGE", nil)                                         delegate:nil
                                  cancelButtonTitle:OEXLocalizedString(@"OK", nil)
                                  otherButtonTitles:nil] show];
            }
            else{
                MFMailComposeViewController * mailComposer = [[MFMailComposeViewController alloc] init];
                [mailComposer setMailComposeDelegate:self];
                [mailComposer setSubject:@"Customer Feedback"];
                [mailComposer setMessageBody:@"" isHTML:NO];
                NSString* feedbackAddress = [OEXConfig sharedConfig].feedbackEmailAddress;
                if(feedbackAddress != nil) {
                    [mailComposer setToRecipients:@[feedbackAddress]];
                }
                [self presentViewController:mailComposer animated:YES completion:nil];
            }
        }
    }
    else if (position == FrontViewPositionRight){
        self.overlayButton.hidden = NO;
        [self.navigationController popToViewController:self animated:NO];
        [UIView animateWithDuration:0.5 delay:0 options:0 animations:^{
            self.overlayButton.alpha = 0.5f;
        } completion:^(BOOL finished) {
            
        }];
    }
}

-(void)mailComposeController:(MFMailComposeViewController*)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error {
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
