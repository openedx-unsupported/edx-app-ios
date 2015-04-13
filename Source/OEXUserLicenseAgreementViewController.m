//
//  OEXUserLicenseAgreementViewController.m
//  edXVideoLocker
//
//  Created by Jotiram Bhagat on 19/02/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

#import "OEXUserLicenseAgreementViewController.h"
#import "OEXRegistrationAgreement.h"

@interface OEXUserLicenseAgreementViewController () <UIWebViewDelegate>
{
    IBOutlet UIWebView* webView;
    IBOutlet UIActivityIndicatorView* activityIndicator;
}
@property(nonatomic, strong) NSURL* contentUrl;
@end

@implementation OEXUserLicenseAgreementViewController

- (instancetype)initWithContentURL:(NSURL*)contentUrl {
    self = [super init];
    if(self) {
        self.contentUrl = contentUrl;
    }
    return self;
}
- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    NSURLRequest* request = [[NSURLRequest alloc] initWithURL:self.contentUrl];
    webView.delegate = self;
    [webView loadRequest:request];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [UIApplication sharedApplication].statusBarHidden = YES;
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [UIApplication sharedApplication].statusBarHidden = NO;
}

- (IBAction)closeButtonTapped:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (BOOL)webView:(UIWebView*)inWeb shouldStartLoadWithRequest:(NSURLRequest*)inRequest navigationType:(UIWebViewNavigationType)inType {
    if([[inRequest URL] isFileURL]) {
        return YES;
    }

    if(inType == UIWebViewNavigationTypeLinkClicked) {
        [[UIApplication sharedApplication] openURL:[inRequest URL]];
        return NO;
    }
    return YES;
}

- (void)webView:(UIWebView*)webView didFailLoadWithError:(NSError*)error {
    [activityIndicator stopAnimating];
    ELog(@"error==>%@", [error localizedDescription]);
}

- (void)webViewDidFinishLoad:(UIWebView*)webView {
    [activityIndicator stopAnimating];
    ELog(@"Web view did finish loading");
}

- (void)webViewDidStartLoad:(UIWebView*)webView {
    [activityIndicator startAnimating];
    ELog(@"Web view did start loading");
}
@end
