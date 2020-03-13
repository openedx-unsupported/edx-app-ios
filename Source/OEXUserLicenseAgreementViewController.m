//
//  OEXUserLicenseAgreementViewController.m
//  edXVideoLocker
//
//  Created by Jotiram Bhagat on 19/02/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

#import "OEXUserLicenseAgreementViewController.h"

#import "edX-Swift.h"
#import "Logger+OEXObjC.h"
#import <WebKit/WebKit.h>
#import "OEXRegistrationAgreement.h"
#import <Masonry/Masonry.h>

@interface OEXUserLicenseAgreementViewController () <WKNavigationDelegate>
{
    __weak IBOutlet UIView *webviewContainer;
    WKWebView* webView;
    IBOutlet UIActivityIndicatorView* activityIndicator;
}
@property(nonatomic, strong) NSURL* contentUrl;
@property (weak, nonatomic) IBOutlet UIButton *closeButton;
@end

@implementation OEXUserLicenseAgreementViewController

- (instancetype)initWithContentURL:(NSURL*)contentUrl {
    self = [super init];
    if(self) {
        self.contentUrl = contentUrl;
    }
    return self;
}

- (BOOL)prefersStatusBarHidden {
    return YES;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    [_closeButton setTitle:[Strings close] forState:UIControlStateNormal];
    [self addAndConfigureWebview];
    [self loadURL];
    [self addObserver];
}

- (void) addAndConfigureWebview {
    webView = [[WKWebView alloc] init];
    webView.navigationDelegate = self;
    [self.view addSubview:webView];
    [self.view bringSubviewToFront:webView];

    [webView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(webviewContainer);
    }];
}

- (void)addObserver {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(reload)
                                                 name:NOTIFICATION_DYNAMIC_TEXT_TYPE_UPDATE object:nil];
}

- (void)loadURL {
    NSURLRequest* request = [[NSURLRequest alloc] initWithURL:self.contentUrl];
    [webView loadRequest:request];
}

- (void)reload {
    if (!webView.isLoading) {
        [webView reload];
    }
}

- (IBAction)closeButtonTapped:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - WKNavigationDelegate methods

- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler {
    NSURL *URL = navigationAction.request.URL;
    if ([URL isFileURL]) {
        decisionHandler(WKNavigationActionPolicyAllow);
        return;
    }

    switch (navigationAction.navigationType) {
        case WKNavigationTypeLinkActivated:
            if ([[UIApplication sharedApplication] canOpenURL:URL]) {
                [[UIApplication sharedApplication] openURL:URL];
            }
            break;
        default:
            break;
    }

    decisionHandler(WKNavigationActionPolicyCancel);

}

- (void)webView:(WKWebView *)webView didFailNavigation:(WKNavigation *)navigation withError:(NSError *)error {
    [activityIndicator stopAnimating];
    OEXLogInfo(@"EULA", @"Error is %@", error.localizedDescription);
    [[UIAlertController alloc] showAlertWithTitle:nil message:error.localizedDescription onViewController:self];
}

- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation {
    [activityIndicator stopAnimating];
    OEXLogInfo(@"EULA", @"Web View did finish loading");
}

@end
