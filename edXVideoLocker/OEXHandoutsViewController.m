//
//  OEXHandoutsViewController.m
//  edXVideoLocker
//
//  Created by Abhradeep on 17/02/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

#import "OEXHandoutsViewController.h"
#import "OEXStyles.h"
#import "OEXConfig.h"
#import "DACircularProgressView.h"
#import "OEXCustomNavigationView.h"
#import "Reachability.h"
#import "OEXInterface.h"
#import "OEXDownloadViewController.h"

#define kHandoutsScreenName @"Handouts"

@interface OEXHandoutsViewController ()

@property (strong, nonatomic) OEXInterface *dataInterface;
@property (strong, nonatomic) IBOutlet DACircularProgressView *customProgressBar;
@property (strong, nonatomic) IBOutlet OEXCustomNavigationView *customNavView;
@property (strong, nonatomic) IBOutlet UIButton *showDownloadsButton;
@property (strong, nonatomic) IBOutlet UIWebView *webView;
@property (strong, nonatomic) IBOutlet UILabel *handoutsUnavailableLabel;
@property (strong, nonatomic) NSString *handoutsString;

@end

@implementation OEXHandoutsViewController

-(instancetype)initWithHandoutsString:(NSString *)aHandoutsString{
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        self.handoutsString = aHandoutsString;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.customNavView.lbl_TitleView.text = kHandoutsScreenName;
    [self.customNavView.btn_Back addTarget:self action:@selector(backPressed) forControlEvents:UIControlEventTouchUpInside];
    
    [self setExclusiveTouches];
    self.dataInterface = [OEXInterface sharedInterface];
    [self setNavigationBar];
    
    self.showDownloadsButton.hidden = YES;
    self.customProgressBar.hidden = YES;
    [[self.dataInterface progressViews] addObject:self.customProgressBar];
    [[self.dataInterface progressViews] addObject:self.showDownloadsButton];
    
    if (self.handoutsString.length > 0) {
        NSString* styledHandouts = [OEXStyles styleHTMLContent:self.handoutsString];
        [self.webView loadHTMLString:styledHandouts baseURL:[NSURL URLWithString:[OEXConfig sharedConfig].apiHostURL]];
    }
    else{
        self.handoutsUnavailableLabel.text = NSLocalizedString(@"HANDOUTS_UNAVAILABLE", nil);
        self.handoutsUnavailableLabel.hidden = NO;
        self.webView.hidden = YES;
    }
    
}

-(void)backPressed{
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    [self.navigationController popViewControllerAnimated:YES];
}

-(IBAction)showDownloadsButtonPressed:(id)sender{
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    OEXDownloadViewController *downloadViewController = [storyboard instantiateViewControllerWithIdentifier:@"OEXDownloadViewController"];
    [self.navigationController pushViewController:downloadViewController animated:YES];
}

-(void)viewWillAppear:(BOOL)animated{
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
    [self.customNavView adjustPositionIfOnline:isOnline];
}

@end
