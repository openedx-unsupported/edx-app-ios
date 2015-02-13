//
//  OEXFindCoursesBaseViewController.m
//  edXVideoLocker
//
//  Created by Abhradeep on 04/02/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

#import "OEXFindCoursesBaseViewController+Protected.h"

#define kShouldShowDownloadProgress NO

@interface OEXFindCoursesBaseViewController ()

@end

@implementation OEXFindCoursesBaseViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.notReachableLabel.text = NSLocalizedString(@"FIND_COURSES_OFFLINE_MESSAGE", nil);
    [self setExclusiveTouches];
    self.dataInterface = [OEXInterface sharedInterface];
    [self setNavigationBar];
    
    if (kShouldShowDownloadProgress) {
        [[self.dataInterface progressViews] addObject:self.customProgressBar];
        [[self.dataInterface progressViews] addObject:self.showDownloadsButton];
    }
    else{
        self.showDownloadsButton.hidden = YES;
        self.customProgressBar.hidden = YES;
    }
    
    self.webViewHelper = [[OEXFindCoursesWebViewHelper alloc] initWithWebView:self.webView delegate:self];
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    self.navigationController.navigationBarHidden = YES;

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reachabilityDidChange:) name:kReachabilityChangedNotification object:nil];
    [self hideOfflineLabel:_dataInterface.reachable];
}

-(void)viewDidDisappear:(BOOL)animated{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

-(void)reachabilityDidChange:(NSNotification *)notification{
    Reachability *reachability = (Reachability *)[notification object];
    _dataInterface.reachable = [reachability isReachable];
    [self hideOfflineLabel:_dataInterface.reachable];
}

-(void)setExclusiveTouches{
    self.customNavView.btn_Back.exclusiveTouch=YES;
    self.webView.exclusiveTouch = YES;
    self.view.exclusiveTouch=YES;
}

-(void)setNavigationBar{
    self.navigationController.navigationBar.topItem.title = @"";
    self.navigationItem.hidesBackButton = YES;
    
    [self.customProgressBar setProgressTintColor:PROGRESSBAR_PROGRESS_TINT_COLOR];
    [self.customProgressBar setTrackTintColor:PROGRESSBAR_TRACK_TINT_COLOR];
    [self.customProgressBar setProgress:_dataInterface.totalProgress animated:YES];
}

- (void)hideOfflineLabel:(BOOL)isOnline{
    self.customNavView.lbl_Offline.hidden = isOnline;
    self.customNavView.view_Offline.hidden = isOnline;
    self.notReachableLabel.hidden = isOnline;
    if (!isOnline) {
        self.webView.hidden = YES;
        [self.webView stopLoading];
    }
}

- (void)backPressed{
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    [self.navigationController popViewControllerAnimated:YES];
}

-(IBAction)showDownloadButtonPressed:(id)sender{
    OEXDownloadViewController *downloadViewController = [[UIStoryboard storyboardWithName:@"Main" bundle:nil] instantiateViewControllerWithIdentifier:@"OEXDownloadViewController"];
    downloadViewController.isFromFrontViews = YES;
    [self.navigationController pushViewController:downloadViewController animated:YES];
}

-(void)webViewHelper:(OEXFindCoursesWebViewHelper *)webViewHelper shouldOpenURLString:(NSString *)urlString{
    
}

-(void)webViewHelper:(OEXFindCoursesWebViewHelper *)webViewHelper userEnrolledWithCourseID:(NSString *)courseID emailOptIn:(NSString *)emailOptIn{
    
}

-(void)dealloc{
    self.customProgressBar = nil;
    self.customNavView = nil;
    self.showDownloadsButton = nil;
    self.webView = nil;
    self.notReachableLabel = nil;
    self.webViewHelper = nil;
}

@end
