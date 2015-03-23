//
//  OEXFindCoursesWebViewHelper.m
//  edXVideoLocker
//
//  Created by Abhradeep on 02/02/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

#import "OEXFindCoursesWebViewHelper.h"
#import "OEXEnrollmentConfig.h"
#import "OEXConfig.h"

@interface OEXFindCoursesWebViewHelper () <UIWebViewDelegate>

@property (nonatomic, weak) UIWebView* webView;
@property (nonatomic, weak) id <OEXFindCoursesWebViewHelperDelegate> delegate;
@property (nonatomic, strong) NSString* courseInfoTemplate;
@property (nonatomic, strong) NSString* webViewURLHost;

@end

@implementation OEXFindCoursesWebViewHelper

- (instancetype)initWithWebView:(UIWebView*)aWebView delegate:(id <OEXFindCoursesWebViewHelperDelegate>)aDelegate {
    self = [super init];
    if(self) {
        self.webView = aWebView;
        _webView.delegate = self;
        self.delegate = aDelegate;
        self.isWebViewLoaded = NO;
        self.courseInfoTemplate = [[[OEXConfig sharedConfig] courseEnrollmentConfig] courseInfoURLTemplate];
    }
    return self;
}

- (void)loadWebViewWithURLString:(NSString*)urlString {
    _webView.hidden = NO;
    NSURL* url = [NSURL URLWithString:urlString];
    self.webViewURLHost = [url host];
    [_webView loadRequest:[NSURLRequest requestWithURL:url]];
}

#pragma mark - UIWebViewDelegate methods
- (BOOL)webView:(UIWebView*)webView shouldStartLoadWithRequest:(NSURLRequest*)request navigationType:(UIWebViewNavigationType)navigationType {
    if(navigationType == UIWebViewNavigationTypeLinkClicked) {
        BOOL shouldLoad = [self.delegate webViewHelper:self shouldLoadURLWithRequest:request navigationType:navigationType];
        if(!shouldLoad) {
            return NO;
        }
    }

    if(![[request.mainDocumentURL host] isEqualToString:self.webViewURLHost]) {
        [[UIApplication sharedApplication] openURL:request.URL];
        return NO;
    }

    return YES;
}

- (void)webViewDidFinishLoad:(UIWebView*)webView {
    if(!webView.loading) {
        self.isWebViewLoaded = YES;
    }
    [self.progressIndicator stopAnimating];
}

- (void)webViewDidStartLoad:(UIWebView*)webView {
    [self.progressIndicator startAnimating];
}

- (void)webView:(UIWebView*)webView didFailLoadWithError:(NSError*)error {
    [self.progressIndicator stopAnimating];
}

@end
