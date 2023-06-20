//------------------------------------------------------------------------------
//
// Copyright (c) Microsoft Corporation.
// All rights reserved.
//
// This code is licensed under the MIT License.
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files(the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and / or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions :
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.
//
//------------------------------------------------------------------------------

#import "MSIDOAuth2EmbeddedWebviewController.h"
#import "MSIDError.h"
#import "MSIDChallengeHandler.h"
#import "MSIDAuthority.h"
#import "MSIDWorkPlaceJoinConstants.h"
#import "MSIDAADNetworkConfiguration.h"
#import "MSIDNotifications.h"

#import "MSIDTelemetry+Internal.h"
#import "MSIDTelemetryUIEvent.h"
#import "MSIDTelemetryEventStrings.h"
#import "MSIDMainThreadUtil.h"
#import "MSIDAppExtensionUtil.h"

#if !MSID_EXCLUDE_WEBKIT

@interface MSIDOAuth2EmbeddedWebviewController()

@property (nonatomic) NSDictionary<NSString *, NSString *> *customHeaders;

@end

@implementation MSIDOAuth2EmbeddedWebviewController
{
    NSURL *_endURL;
    MSIDWebUICompletionHandler _completionHandler;

    NSLock *_completionLock;
    NSTimer *_spinnerTimer; // Used for managing the activity spinner
    
    id<MSIDRequestContext> _context;
    
    NSString *_telemetryRequestId;
#if !EXCLUDE_FROM_MSALCPP
    MSIDTelemetryUIEvent *_telemetryEvent;
#endif
}

- (id)initWithStartURL:(NSURL *)startURL
                endURL:(NSURL *)endURL
               webview:(WKWebView *)webview
         customHeaders:(NSDictionary<NSString *, NSString *> *)customHeaders
        platfromParams:(MSIDWebViewPlatformParams *)platformParams
               context:(id<MSIDRequestContext>)context
{
    if (!startURL)
    {
        MSID_LOG_WITH_CTX(MSIDLogLevelWarning,context, @"Attemped to start with nil URL");
        return nil;
    }
    
    if (!endURL)
    {
        MSID_LOG_WITH_CTX(MSIDLogLevelWarning,context, @"Attemped to start with nil endURL");
        return nil;
    }
    
    self = [super initWithContext:context
                   platformParams:platformParams];

    if (self)
    {
        self.webView = webview;
        _startURL = startURL;
        _endURL = endURL;
        _customHeaders = customHeaders;
        
        _completionLock = [[NSLock alloc] init];

        _context = context;
        
        _complete = NO;
    }
    
    return self;
}

-(void)dealloc
{
    if ([self.webView.navigationDelegate isEqual:self])
    {
        [self.webView setNavigationDelegate:nil];
    }
    
    self.webView = nil;
}

- (void)startWithCompletionHandler:(MSIDWebUICompletionHandler)completionHandler
{
    if (!completionHandler)
    {
        MSID_LOG_WITH_CTX(MSIDLogLevelWarning,_context, @"CompletionHandler cannot be nil for interactive session.");
        return;
    }
    
    // Save the completion block
    _completionHandler = [completionHandler copy];
    
    [MSIDMainThreadUtil executeOnMainThreadIfNeeded:^{
        
        NSError *error = nil;
        [self loadView:&error];
        if (error)
        {
            [self endWebAuthWithURL:nil error:error];
            return;
        }
        
        NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:self.startURL];
        for (NSString *headerKey in self.customHeaders)
            [request addValue:self.customHeaders[headerKey] forHTTPHeaderField:headerKey];
        
        [self startRequest:request];
        
    }];
}

- (void)cancelProgrammatically
{
    MSID_LOG_WITH_CTX(MSIDLogLevelInfo, self.context, @"Canceled web view contoller.");
    
    // End web auth with error
    NSError *error = MSIDCreateError(MSIDErrorDomain, MSIDErrorSessionCanceledProgrammatically, @"Authorization session was cancelled programatically.", nil, nil, nil, self.context.correlationId, nil, NO);
    
    CONDITIONAL_UI_EVENT_SET_IS_CANCELLED(_telemetryEvent, YES);
    [self endWebAuthWithURL:nil error:error];
}

- (void)dismiss
{
    [self cancelProgrammatically];
}

- (void)userCancel
{
    MSID_LOG_WITH_CTX(MSIDLogLevelInfo, self.context, @"Canceled web view contoller by the user.");
    
    // End web auth with error
    NSError *error = MSIDCreateError(MSIDErrorDomain, MSIDErrorUserCancel, @"User cancelled the authorization session.", nil, nil, nil, self.context.correlationId, nil, NO);
    
    CONDITIONAL_UI_EVENT_SET_IS_CANCELLED(_telemetryEvent, YES);
    [self endWebAuthWithURL:nil error:error];
}

- (BOOL)loadView:(NSError **)error
{
    // create and load the view if not provided
    BOOL result = [super loadView:error];
    
    self.webView.navigationDelegate = self;
    
    return result;
}

- (void)endWebAuthWithURL:(NSURL *)endURL
                    error:(NSError *)error
{
    if (self.complete)
    {
        MSID_LOG_WITH_CTX(MSIDLogLevelInfo, self.context, @"endWebAuthWithURL called for a second time, disregarding");
        return;
    }
    self.complete = YES;
    
    if (error)
    {
        [MSIDNotifications notifyWebAuthDidFailWithError:error];
    }
    else
    {
        [MSIDNotifications notifyWebAuthDidCompleteWithURL:endURL];
    }
    
    CONDITIONAL_STOP_EVENT(CONDITIONAL_SHARED_INSTANCE, _telemetryRequestId, _telemetryEvent);
    
    [MSIDMainThreadUtil executeOnMainThreadIfNeeded:^{
        MSID_LOG_WITH_CTX(MSIDLogLevelInfo, self.context, @"Dismissed web view contoller.");
        [self dismissWebview:^{[self dispatchCompletionBlock:endURL error:error];}];
    }];
    
    return;
}

- (void)dispatchCompletionBlock:(NSURL *)url error:(NSError *)error
{
    // NOTE: It is possible that competition between a successful completion
    //       and the user cancelling the authentication dialog can
    //       occur causing this method to be called twice. The competition
    //       cannot be blocked at its root, and so this method must
    //       be resilient to this condition and should not generate
    //       two callbacks.
    [_completionLock lock];
    
    [MSIDChallengeHandler resetHandlers];
    
    if (_completionHandler)
    {
        MSIDWebUICompletionHandler completionHandler = _completionHandler;
        _completionHandler = nil;
        [_completionLock unlock];
        
        completionHandler(url, error);
    }
    else
    {
        [_completionLock unlock];
    }
}

- (void)startRequest:(NSURLRequest *)request
{
    MSID_LOG_WITH_CTX(MSIDLogLevelInfo, self.context, @"Presenting web view contoller.");
    
    _telemetryRequestId = [_context telemetryRequestId];
    CONDITIONAL_START_EVENT(CONDITIONAL_SHARED_INSTANCE, _telemetryRequestId, MSID_TELEMETRY_EVENT_UI_EVENT);
#if !EXCLUDE_FROM_MSALCPP
    _telemetryEvent = [[MSIDTelemetryUIEvent alloc] initWithName:MSID_TELEMETRY_EVENT_UI_EVENT
                                                         context:_context];
#endif
    [self loadRequest:request];
    [self presentView];
}

- (void)loadRequest:(NSURLRequest *)request
{
    [self.webView loadRequest:request];
}

#pragma mark - WKNavigationDelegate Protocol

- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler
{
    NSURL *requestURL = navigationAction.request.URL;
    
    MSID_LOG_WITH_CTX_PII(MSIDLogLevelVerbose, self.context, @"-decidePolicyForNavigationAction host: %@", MSID_PII_LOG_TRACKABLE(requestURL.host));
    
    [MSIDNotifications notifyWebAuthDidStartLoad:requestURL userInfo:webView ? @{@"webview" : webView} : nil];
    
    [self decidePolicyForNavigationAction:navigationAction webview:webView decisionHandler:decisionHandler];
}

- (void)webView:(__unused WKWebView *)webView didStartProvisionalNavigation:(null_unspecified __unused WKNavigation *)navigation
{
    if (!self.loading)
    {
        self.loading = YES;
        if (_spinnerTimer)
        {
            [_spinnerTimer invalidate];
        }
        _spinnerTimer = [NSTimer scheduledTimerWithTimeInterval:2.0
                                                         target:self
                                                       selector:@selector(onStartLoadingIndicator:)
                                                       userInfo:nil
                                                        repeats:NO];
        [_spinnerTimer setTolerance:0.3];
    }
}

- (void)webView:(WKWebView *)webView didFinishNavigation:(null_unspecified __unused WKNavigation *)navigation
{
    NSURL *url = webView.URL;
    [self notifyFinishedNavigation:url webView:webView];
}

- (void)webView:(__unused WKWebView *)webView didFailNavigation:(null_unspecified __unused WKNavigation *)navigation withError:(NSError *)error
{
    [self webAuthFailWithError:error];
}

- (void)webView:(__unused WKWebView *)webView didFailProvisionalNavigation:(__unused WKNavigation *)navigation withError:(NSError *)error
{
    [self webAuthFailWithError:error];
}

- (void)webView:(WKWebView *)webView didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge completionHandler:(ChallengeCompletionHandler)completionHandler
{
    NSString *authMethod = [challenge.protectionSpace.authenticationMethod lowercaseString];
    
    MSID_LOG_WITH_CTX(MSIDLogLevelVerbose,self.context,
                     @"%@ - %@. Previous challenge failure count: %ld",
                     @"webView:didReceiveAuthenticationChallenge:completionHandler",
                     authMethod, (long)challenge.previousFailureCount);
    
    [MSIDChallengeHandler handleChallenge:challenge
                                  webview:webView
#if TARGET_OS_IPHONE
                         parentController:self.parentController
#endif
                                  context:self.context
                        completionHandler:completionHandler];
}

- (void)webView:(WKWebView *)webView decidePolicyForNavigationResponse:(WKNavigationResponse *)navigationResponse decisionHandler:(void (^)(WKNavigationResponsePolicy))decisionHandler
{
    if (self.navigationResponseBlock && navigationResponse && navigationResponse.response)
    {
        NSHTTPURLResponse *response = (NSHTTPURLResponse *)navigationResponse.response;
        if (response)
        {
            self.navigationResponseBlock(response);
        }
    }
    
    decisionHandler(WKNavigationResponsePolicyAllow);
}

- (void)completeWebAuthWithURL:(NSURL *)endURL
{
    MSID_LOG_WITH_CTX_PII(MSIDLogLevelInfo, self.context, @"-completeWebAuthWithURL: %@", [endURL msidPIINullifiedURL]);
    
    [self endWebAuthWithURL:endURL error:nil];
}

// Authentication failed somewhere
- (void)webAuthFailWithError:(NSError *)error
{
    if (self.complete)
    {
        return;
    }
    
    if ([error.domain isEqualToString:NSURLErrorDomain] && NSURLErrorCancelled == error.code)
    {
        //This is a common error that webview generates and could be ignored.
        //See this thread for details: https://discussions.apple.com/thread/1727260
        return;
    }
    
    [self stopSpinner];
    
    // WebKitErrorDomain includes WebKitErrorFrameLoadInterruptedByPolicyChange and
    // other web page errors like JavaUnavailable etc. Ignore them here.
    if([error.domain isEqualToString:@"WebKitErrorDomain"])
    {
        return;
    }
    
    MSID_LOG_WITH_CTX_PII(MSIDLogLevelError, self.context, @"-webAuthFailWithError: %@", MSID_PII_LOG_MASKABLE(error));
    
    [self endWebAuthWithURL:nil error:error];
}

- (void)decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction
                                webview:(__unused WKWebView *)webView
                        decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler
{
    NSURL *requestURL = navigationAction.request.URL;
    NSString *requestURLString = [requestURL.absoluteString lowercaseString];
    
    // Stop at the end URL.
    if ([requestURLString hasPrefix:[_endURL.absoluteString lowercaseString]])
    {
        NSURL *url = navigationAction.request.URL;
        [self completeWebAuthWithURL:url];
        decisionHandler(WKNavigationActionPolicyCancel);
        return;
    }
    
    if ([requestURLString isEqualToString:@"about:blank"] || [requestURLString isEqualToString:@"about:srcdoc"])
    {
        decisionHandler(WKNavigationActionPolicyAllow);
        return;
    }
    
    // Handle anchor links that were clicked
    if ([navigationAction navigationType] == WKNavigationTypeLinkActivated)
    {
        //Open secure web links with target=new window in default browser or non-web links with URL schemes that can be opened by the application
        // If the target of the navigation is a new window, navigationAction.targetFrame is nil. (See discussions in : https://developer.apple.com/documentation/webkit/wknavigationaction/1401918-targetframe?language=objc)
        if (([requestURL.scheme.lowercaseString isEqualToString:@"https"] && !navigationAction.targetFrame) || ![requestURL.scheme.lowercaseString hasPrefix:@"http"])
        {
            MSID_LOG_WITH_CTX_PII(MSIDLogLevelInfo, self.context, @"Opening URL outside embedded webview with scheme: %@ host: %@", requestURL.scheme, MSID_PII_LOG_TRACKABLE(requestURL.host));
            [MSIDAppExtensionUtil sharedApplicationOpenURL:requestURL];
            [self notifyFinishedNavigation:requestURL webView:webView];
            decisionHandler(WKNavigationActionPolicyCancel);
            return;
        }
    }
    
    // redirecting to non-https url is not allowed
    if (![requestURL.scheme.lowercaseString isEqualToString:@"https"])
    {
        MSID_LOG_WITH_CTX(MSIDLogLevelInfo, self.context, @"Server is redirecting to a non-https url");
        
        NSError *error = MSIDCreateError(MSIDErrorDomain, MSIDErrorServerNonHttpsRedirect, @"The server has redirected to a non-https url.", nil, nil, nil, self.context.correlationId, nil, NO);
        [self endWebAuthWithURL:nil error:error];
        
        decisionHandler(WKNavigationActionPolicyCancel);
        return;
    }
    
    decisionHandler(WKNavigationActionPolicyAllow);
}

- (void)webView:(WKWebView *)webView didReceiveServerRedirectForProvisionalNavigation:(WKNavigation *)navigation
{
    NSURL *url = webView.URL;
    if (url && [url.absoluteString containsString:[NSString stringWithFormat:@"%@=", MSID_SSO_NONCE_QUERY_PARAM_KEY]])
    {
        [self completeWebAuthWithURL:url];
    }
}

#pragma mark - Loading Indicator

- (void)onStartLoadingIndicator:(__unused id)sender
{
    if (self.loading)
    {
        [self showLoadingIndicator];
    }
    _spinnerTimer = nil;
}

- (void)stopSpinner
{
    if (!self.loading)
    {
        return;
    }
    
    self.loading = NO;
    if (_spinnerTimer)
    {
        [_spinnerTimer invalidate];
        _spinnerTimer = nil;
    }
    
    [self dismissLoadingIndicator];
}

-(void)notifyFinishedNavigation:(NSURL *)url webView:(WKWebView *)webView
{
    MSID_LOG_WITH_CTX_PII(MSIDLogLevelVerbose, self.context, @"-didFinishNavigation host: %@", MSID_PII_LOG_TRACKABLE(url.host));
    
    [MSIDNotifications notifyWebAuthDidFinishLoad:url userInfo:webView ? @{@"webview": webView} : nil];
    
    [self stopSpinner];
}

@end

#endif
