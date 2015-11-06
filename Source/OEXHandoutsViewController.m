//
//  OEXHandoutsViewController.m
//  edXVideoLocker
//
//  Created by Abhradeep on 17/02/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

#import "OEXHandoutsViewController.h"

#import "edX-Swift.h"

#import "OEXStyles.h"
#import "OEXConfig.h"
#import "DACircularProgressView.h"
#import "OEXCustomNavigationView.h"
#import "Reachability.h"
#import "OEXInterface.h"
#import "OEXDownloadViewController.h"

@interface OEXHandoutsViewController () <UIWebViewDelegate>

@property (strong, nonatomic) IBOutlet UILabel* handoutsUnavailableLabel;
@property (strong, nonatomic) NSString* handoutsString;

@end

@implementation OEXHandoutsViewController

- (instancetype)initWithHandoutsString:(NSString*)aHandoutsString {
    self = [super initWithNibName:nil bundle:nil];
    if(self) {
        self.handoutsString = aHandoutsString;
    }
    return self;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:true animated:animated];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.customNavView.lbl_TitleView.text = [Strings courseHandouts];
    [self.customNavView.btn_Back addTarget:self action:@selector(backPressed) forControlEvents:UIControlEventTouchUpInside];
    [[OEXStyles sharedStyles] applyMockBackButtonStyleToButton:self.customNavView.btn_Back];

    [[self.dataInterface progressViews] addObject:self.customProgressBar];
    [[self.dataInterface progressViews] addObject:self.showDownloadsButton];

    if(self.handoutsString.length > 0) {
        NSString* styledHandouts = [[OEXStyles sharedStyles] styleHTMLContent:self.handoutsString];
        [self.webView loadHTMLString:styledHandouts baseURL:[OEXConfig sharedConfig].apiHostURL];
    }
    else {
        self.handoutsUnavailableLabel.text = [Strings handoutsUnavailable];
        self.handoutsUnavailableLabel.hidden = NO;
        self.webView.hidden = YES;
    }
    self.webView.delegate = self;
    [[OEXStyles sharedStyles] applyMockNavigationBarStyleToView:self.customNavView label:self.customNavView.lbl_TitleView leftIconButton:self.customNavView.btn_Back];
    
}

// Ensure external links open in a web browser
- (BOOL)webView:(UIWebView*)webView shouldStartLoadWithRequest:(NSURLRequest*)request navigationType:(UIWebViewNavigationType)navigationType {
    if(navigationType != UIWebViewNavigationTypeOther) {
        [[UIApplication sharedApplication] openURL:request.URL];
        return NO;
    }
    return YES;
}

- (void)hideOfflineLabel:(BOOL)isOnline {
    self.customNavView.lbl_Offline.hidden = isOnline;
    self.customNavView.view_Offline.hidden = isOnline;
}

@end
