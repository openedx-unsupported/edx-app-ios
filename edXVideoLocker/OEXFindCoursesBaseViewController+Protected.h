//
//  OEXFindCoursesBaseViewController+Protected.h
//  edXVideoLocker
//
//  Created by Abhradeep on 13/02/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

#import "OEXFindCoursesBaseViewController.h"
#import "SWRevealViewController.h"
#import "OEXDownloadViewController.h"
#import "DACircularProgressView.h"
#import "OEXCustomNavigationView.h"
#import "OEXInterface.h"
#import "OEXFindCoursesWebViewHelper.h"
#import "Reachability.h"
#import "OEXEnvironment.h"
#import "OEXConfig.h"

@interface OEXFindCoursesBaseViewController()

@property (strong, nonatomic) IBOutlet DACircularProgressView *customProgressBar;
@property (strong, nonatomic) IBOutlet OEXCustomNavigationView *customNavView;
@property (strong, nonatomic) IBOutlet UIButton *showDownloadsButton;
@property (strong, nonatomic) IBOutlet UIWebView *webView;
@property (strong, nonatomic) IBOutlet UILabel *notReachableLabel;
@property (strong, nonatomic) OEXInterface *dataInterface;

-(void)reachabilityDidChange:(NSNotification *)notification;
-(void)setExclusiveTouches;
-(void)setNavigationBar;
-(void)backPressed;
-(IBAction)showDownloadButtonPressed:(id)sender;

@end
