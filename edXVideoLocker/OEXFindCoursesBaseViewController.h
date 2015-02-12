//
//  OEXFindCoursesBaseViewController.h
//  edXVideoLocker
//
//  Created by Abhradeep on 04/02/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SWRevealViewController.h"
#import "OEXDownloadViewController.h"
#import "DACircularProgressView.h"
#import "OEXCustomNavigationView.h"
#import "OEXInterface.h"
#import "OEXFindCoursesWebViewHelper.h"
#import "Reachability.h"
#import "OEXEnvironment.h"
#import "OEXConfig.h"

@interface OEXFindCoursesBaseViewController : UIViewController <OEXFindCoursesWebViewHelperDelegate>

@property (weak, nonatomic) IBOutlet DACircularProgressView *customProgressBar;
@property (weak, nonatomic) IBOutlet OEXCustomNavigationView *customNavView;
@property (weak, nonatomic) IBOutlet UIButton *showDownloadsButton;
@property (weak, nonatomic) IBOutlet UIWebView *webView;
@property (weak, nonatomic) IBOutlet UILabel *notReachableLabel;
@property (strong, nonatomic) OEXInterface *dataInterface;
@property (strong, nonatomic) OEXFindCoursesWebViewHelper *webViewHelper;

-(void)reachabilityDidChange:(NSNotification *)notification;
-(void)setExclusiveTouches;
-(void)setNavigationBar;
-(void)backPressed;
-(IBAction)showDownloadButtonPressed:(id)sender;
@end
