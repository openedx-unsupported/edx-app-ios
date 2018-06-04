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

#import "OEXRegistrationAgreement.h"

@interface OEXUserLicenseAgreementViewController () <UIWebViewDelegate>
{
    IBOutlet UIWebView* webView;
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
    NSURLRequest* request = [[NSURLRequest alloc] initWithURL:self.contentUrl];
    webView.delegate = self;
    [webView loadRequest:request];
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
    OEXLogInfo(@"EULA", @"Error is %@", error.localizedDescription);
    [[UIAlertController alloc] showAlertWithTitle:nil message:error.localizedDescription onViewController:self];
}

- (void)webViewDidFinishLoad:(UIWebView*)webView {
    [activityIndicator stopAnimating];
    OEXLogInfo(@"EULA", @"Web View did finish loading");
}

- (void)webViewDidStartLoad:(UIWebView*)webView {
    [activityIndicator startAnimating];
    OEXLogInfo(@"EULA", @"Web View did start loading");
}
@end
