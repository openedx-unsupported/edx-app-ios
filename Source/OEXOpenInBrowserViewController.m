//
//  OEXOpenInBrowserViewController.m
//  edXVideoLocker
//
//  Created by Rahul Varma on 19/06/14.
//  Copyright (c) 2014 edX. All rights reserved.
//

@import edXCore;

#import "OEXOpenInBrowserViewController.h"

#import "edX-Swift.h"
#import "Logger+OEXObjC.h"

#import "OEXAppDelegate.h"
#import "OEXAuthentication.h"
#import "OEXUserDetails.h"
#import "OEXAnalytics.h"

@interface OEXOpenInBrowserViewController ()
@end

static OEXOpenInBrowserViewController* _sharedInterface = nil;

@implementation OEXOpenInBrowserViewController

+ (id)sharedInstance {
    if(!_sharedInterface) {
        _sharedInterface = [[OEXOpenInBrowserViewController alloc] init];
    }

    return _sharedInterface;
}

#pragma mark Public Actions

- (void)addViewToSuperview:(UIView*)parentView {
    //Set initial frame

    _sharedInterface.view.frame = CGRectMake(self.view.frame.origin.x,
                                             parentView.frame.size.height - self.view.frame.size.height,
                                             self.view.frame.size.width,
                                             self.view.frame.size.height);
    [parentView addSubview:_sharedInterface.view];
}

- (void)addViewToContainerSuperview:(UIView*)parentView {
    //Set initial frame
    self.view_BG.backgroundColor = [UIColor colorWithRed:40.0 / 255.0 green:43.0 / 255.0 blue:47.0 / 255.0 alpha:0.9];
    _sharedInterface.view.frame = CGRectMake(0,
                                             0,
                                             self.view.frame.size.width,
                                             self.view.frame.size.height);
    [parentView addSubview:_sharedInterface.view];
}

- (void)removeSelfFromSuperView {
    [self.view removeFromSuperview];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.

    self.lbl_Title.text = [Strings openInBrowserTitle];

    [self.btn_OpenInBrowser setTitle:[[Strings openInBrowser] oex_uppercaseStringInCurrentLocale] forState:UIControlStateNormal];
}

- (IBAction)openInBrowserClicked:(id)sender {
    if([_str_browserURL length] > 0) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wnonnull"
        // Since we check right above this that _str_browserURL.length > 0
        [[OEXAnalytics sharedAnalytics] trackOpenInBrowserWithURL:_str_browserURL courseID:nil blockID:nil minifiedBlockID:nil supported:true];
#pragma clang diagnostic pop
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:_str_browserURL]];
    }
    else {
        OEXLogError(@"OPEN IN BROWSWER", @"Unexpected empty URL");
    }
}

@end
