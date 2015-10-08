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
#import "OEXStyles.h"

#import "NSString+OEXFormatting.h"

@interface OEXRevealContentViewController () <SWRevealViewControllerDelegate>

@property (strong, nonatomic) UIButton* overlayButton;

@end

@implementation OEXRevealContentViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.overlayButton = [[UIButton alloc] initWithFrame:self.view.bounds];
    self.overlayButton.hidden = YES;
    self.overlayButton.alpha = 0;
    self.overlayButton.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    self.overlayButton.backgroundColor = [[OEXStyles sharedStyles] neutralBlack];
    self.overlayButton.exclusiveTouch = YES;
    [self.overlayButton addTarget:self action:@selector(overlayButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
}

- (void)overlayButtonTapped:(id)sender {
    [self.revealViewController revealToggleAnimated:YES];
}

- (void)revealController:(SWRevealViewController*)revealController didMoveToPosition:(FrontViewPosition)position {
    if(position == FrontViewPositionLeft) {
        // Hide
        [UIView animateWithDuration:0.2 delay:0.0 options:0 animations:^{
            self.overlayButton.alpha = 0.0f;
        } completion:^(BOOL finished) {
            self.overlayButton.hidden = YES;
            [self.overlayButton removeFromSuperview];
        }];
    }
    else if(position == FrontViewPositionRight) {
        // Show
        self.overlayButton.frame = self.revealViewController.frontViewController.view.bounds;
        [self.revealViewController.frontViewController.view addSubview:self.overlayButton];
        
        self.overlayButton.hidden = NO;
        [self.navigationController popToViewController:self animated:NO];
        [UIView animateWithDuration:0.5 delay:0 options:0 animations:^{
            self.overlayButton.alpha = 0.5f;
        } completion:NULL];
    }
}

@end
