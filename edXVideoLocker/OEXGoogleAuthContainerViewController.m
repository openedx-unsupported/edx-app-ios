//
//  OEXGoogleAuthContainerViewController.m
//  edXVideoLocker
//
//  Created by Akiva Leffert on 4/8/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

#import <Masonry/Masonry.h>
#import <GooglePlus/GooglePlus.h>

#import "OEXGoogleAuthContainerViewController.h"
#import "NSBundle+OEXConveniences.h"

@interface OEXGoogleAuthContainerViewController () <UIWebViewDelegate>

@property (strong, nonatomic) NSURL* url;
@property (strong, nonatomic) UIWebView* webView;
@property (strong, nonatomic) UIActivityIndicatorView* activityIndicator;

@end

@implementation OEXGoogleAuthContainerViewController

- (id)initWithAuthorizationURL:(NSURL*)url {
    self = [super initWithNibName:nil bundle:nil];
    if(self != nil) {
        self.url = url;
        self.title = OEXLocalizedString(@"SIGN_IN_BUTTON_TEXT", nil);
        self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancelTapped:)];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.webView = [[UIWebView alloc] initWithFrame:self.view.bounds];
    self.webView.delegate = self;
    [self.view addSubview:self.webView];
    
    self.activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    [self.view addSubview:self.activityIndicator];
    [self.activityIndicator startAnimating];
    
    [self.webView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.view);
    }];
    [self.activityIndicator mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(self.view);
    }];
    
    NSURLRequest* request = [[NSURLRequest alloc] initWithURL:self.url];
    [self.webView loadRequest:request];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.navigationController.navigationBar.translucent = NO;
}

- (void)hide {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)cancelTapped:(id)sender {
    [self hide];
}

- (void)webViewDidFinishLoad:(UIWebView *)webView {
    self.activityIndicator.hidden = YES;
}

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
    // This is the redirect back, so send it directly to GPlus
    if([request.URL.scheme isEqualToString:[NSBundle mainBundle].bundleIdentifier]) {
        // This doesn't work unless we pretend the request came from Safari
        [[GPPSignIn sharedInstance] handleURL:request.URL sourceApplication:@"com.apple.mobilesafari" annotation:nil];
        [self hide];
        return NO;
    }
    return YES;
}

@end
