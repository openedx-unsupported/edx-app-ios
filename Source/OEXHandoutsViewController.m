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
#import <Masonry/Masonry.h>

@interface OEXHandoutsViewController () <WKNavigationDelegate>

@property (strong, nonatomic) IBOutlet UILabel* handoutsUnavailableLabel;
@property (strong, nonatomic) IBOutlet UILabel* notReachableLabel;
@property (strong, nonatomic) IBOutlet WKWebView* webView;

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

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationItem.title = [Strings courseHandouts];
    
    [super viewDidLoad];
    self.webView = [[WKWebView alloc] initWithFrame:self.view.bounds configuration:[[WKWebViewConfiguration alloc] init]];
    [self.view insertSubview:self.webView atIndex:0];
    [self.webView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.view);
    }];
    
    self.notReachableLabel.text = [Strings findCoursesOfflineMessage];

    if(self.handoutsString.length > 0) {
        NSString* styledHandouts = [[OEXStyles sharedStyles] styleHTMLContent:self.handoutsString];
        [self.webView loadHTMLString:styledHandouts baseURL:[OEXConfig sharedConfig].apiHostURL];
    }
    else {
        self.handoutsUnavailableLabel.text = [Strings handoutsUnavailable];
        self.handoutsUnavailableLabel.hidden = NO;
        self.webView.hidden = YES;
    }
    self.webView.navigationDelegate = self;
    
}

// Ensure external links open in a web browser
- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler {
    if(navigationAction.navigationType != WKNavigationTypeOther) {
        [[UIApplication sharedApplication] openURL:navigationAction.request.URL];
        decisionHandler(WKNavigationActionPolicyCancel);
    }
    decisionHandler(WKNavigationActionPolicyAllow);
}

@end
