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
#if !MSID_EXCLUDE_SYSTEMWV

#import "MSIDSystemWebviewController.h"
#import "MSIDWebviewAuthorization.h"
#import "MSIDOauth2Factory.h"
#import "MSIDNotifications.h"
#import "MSIDSystemWebViewControllerFactory.h"
#if TARGET_OS_IPHONE
#import "MSIDBackgroundTaskManager.h"
#import "UIApplication+MSIDExtensions.h"
#import "MSIDSafariViewController.h"
#import "MSIDURLResponseHandling.h"
#endif
#import "MSIDTelemetry+Internal.h"
#import "MSIDTelemetryUIEvent.h"
#import "MSIDTelemetryEventStrings.h"

@interface MSIDSystemWebviewController ()

@property (nonatomic, copy) MSIDWebUICompletionHandler completionHandler;
@property (nonatomic) NSString *telemetryRequestId;
#if !EXCLUDE_FROM_MSALCPP
@property (nonatomic) MSIDTelemetryUIEvent *telemetryEvent;
#endif
@property (nonatomic) id<MSIDWebviewInteracting> session;
@property (nonatomic) id<MSIDRequestContext> context;

@property (nonatomic) BOOL useAuthenticationSession;
@property (nonatomic) BOOL allowSafariViewController;
@property (nonatomic) BOOL prefersEphemeralWebBrowserSession;

@end

@implementation MSIDSystemWebviewController

- (instancetype)initWithStartURL:(NSURL *)startURL
                     redirectURI:(NSString *)redirectURI
                parentController:(MSIDViewController *)parentController
        useAuthenticationSession:(BOOL)useAuthenticationSession
       allowSafariViewController:(BOOL)allowSafariViewController
      ephemeralWebBrowserSession:(BOOL)prefersEphemeralWebBrowserSession
                         context:(id<MSIDRequestContext>)context
{
    if (!startURL)
    {
        MSID_LOG_WITH_CTX(MSIDLogLevelWarning,context, @"Attemped to start with nil URL");
        return nil;
    }
    
    NSURL *redirectURL = [NSURL URLWithString:redirectURI];
    if (!redirectURL || !redirectURL.scheme)
    {
        MSID_LOG_WITH_CTX(MSIDLogLevelWarning,context, @"Attemped to start with invalid redirect uri");
        return nil;
    }
    
    self = [super init];
    
    if (self)
    {
        _startURL = startURL;
        _context = context;
        _redirectURL = redirectURL;
        _parentController = parentController;
        _allowSafariViewController = allowSafariViewController;
        _useAuthenticationSession = useAuthenticationSession;
        _prefersEphemeralWebBrowserSession = prefersEphemeralWebBrowserSession;
    }
    return self;
}

- (void)startWithCompletionHandler:(MSIDWebUICompletionHandler)completionHandler
{
    if (!completionHandler)
    {
        MSID_LOG_WITH_CTX(MSIDLogLevelWarning,self.context, @"CompletionHandler cannot be nil for interactive session.");
        return;
    }
    
    self.completionHandler = completionHandler;
    
    NSError *error = nil;
    
    self.session = [self sessionWithAuthSessionAllowed:self.useAuthenticationSession safariAllowed:self.allowSafariViewController];
    
    if (!self.session)
    {
        if (!error)
        {
            error = MSIDCreateError(MSIDErrorDomain, MSIDErrorInteractiveSessionStartFailure, @"Didn't find supported system webview on a particular platform and OS version", nil, nil, nil, self.context.correlationId, nil, YES);
        }
        [MSIDNotifications notifyWebAuthDidFailWithError:error];
        completionHandler(nil, error);
        return;
    }
    
#if TARGET_OS_IPHONE
    [[MSIDBackgroundTaskManager sharedInstance] startOperationWithType:MSIDBackgroundTaskTypeInteractiveRequest];
#endif
    
    self.telemetryRequestId = [self.context telemetryRequestId];
    CONDITIONAL_START_EVENT(CONDITIONAL_SHARED_INSTANCE, self.telemetryRequestId, MSID_TELEMETRY_EVENT_UI_EVENT);
#if !EXCLUDE_FROM_MSALCPP
    self.telemetryEvent = [[MSIDTelemetryUIEvent alloc] initWithName:MSID_TELEMETRY_EVENT_UI_EVENT
                                                             context:self.context];
#endif
    void (^authCompletion)(NSURL *, NSError *) = ^void(NSURL *callbackURL, NSError *authError)
    {
        if (authError && authError.code == MSIDErrorUserCancel)
        {
            CONDITIONAL_UI_EVENT_SET_IS_CANCELLED(self.telemetryEvent, YES);
        }
        
        CONDITIONAL_STOP_EVENT(CONDITIONAL_SHARED_INSTANCE, self.telemetryRequestId, self.telemetryEvent);
        
        [self notifyEndWebAuthWithURL:callbackURL error:authError];
        self.completionHandler(callbackURL, authError);
    };

    [MSIDNotifications notifyWebAuthDidStartLoad:self.startURL userInfo:nil];
    
    [self.session startWithCompletionHandler:authCompletion];
}

- (void)cancel:(NSError *)error
{
    CONDITIONAL_UI_EVENT_SET_IS_CANCELLED(self.telemetryEvent, YES);
    CONDITIONAL_STOP_EVENT(CONDITIONAL_SHARED_INSTANCE, self.telemetryRequestId, self.telemetryEvent);
    
    [self.session cancelProgrammatically];
    
    [self notifyEndWebAuthWithURL:nil error:error];
    self.completionHandler(nil, error);
}

- (void)cancelProgrammatically
{
    MSID_LOG_WITH_CTX(MSIDLogLevelInfo, self.context, @"Authorization session was cancelled programatically");
    NSError *error = MSIDCreateError(MSIDErrorDomain,
                                     MSIDErrorSessionCanceledProgrammatically,
                                     @"Authorization session was cancelled programatically.", nil, nil, nil, self.context.correlationId, nil, YES);
    [self cancel:error];
}

- (void)userCancel
{
    MSID_LOG_WITH_CTX(MSIDLogLevelInfo, self.context, @"Canceled authorization session by the user.");
    NSError *error = MSIDCreateError(MSIDErrorDomain,
                                     MSIDErrorSessionCanceledProgrammatically,
                                     @"Canceled authorization session by the user.", nil, nil, nil, self.context.correlationId, nil, YES);
    [self cancel:error];
}

- (BOOL)handleURLResponse:(NSURL *)url
{
    if (!self.session)
    {
        return NO;
    }
    
    if ([self.redirectURL.scheme caseInsensitiveCompare:url.scheme] != NSOrderedSame
        || [self.redirectURL.host caseInsensitiveCompare:url.host] != NSOrderedSame)
    {
        return NO;
    }
    
    CONDITIONAL_STOP_EVENT(CONDITIONAL_SHARED_INSTANCE, self.telemetryRequestId, self.telemetryEvent);
    
    [self.session dismiss];
    
    [self notifyEndWebAuthWithURL:url error:nil];
    if (self.completionHandler)self.completionHandler(url, nil);
    return YES;
}

- (void)dismiss
{
    [self.session dismiss];
}

#pragma mark - Helpers

- (id<MSIDWebviewInteracting>)sessionWithAuthSessionAllowed:(BOOL)authSessionAllowed
                                              safariAllowed:(BOOL)safariAllowed
{
    MSIDViewController *currentViewController = self.parentController;
    
#if TARGET_OS_IPHONE
    currentViewController = [UIApplication msidCurrentViewController:currentViewController];
#endif
    
    if (authSessionAllowed)
    {
        return [MSIDSystemWebViewControllerFactory authSessionWithParentController:currentViewController
                                                                          startURL:self.startURL
                                                                    callbackScheme:self.redirectURL.scheme
                                                                useEmpheralSession:self.prefersEphemeralWebBrowserSession
                                                                           context:self.context];
    }
        
#if TARGET_OS_IPHONE
        
    if (safariAllowed)
    {
        MSIDSafariViewController *safariController = [[MSIDSafariViewController alloc] initWithURL:self.startURL
                                                                                  parentController:currentViewController
                                                                                  presentationType:self.presentationType
                                                                                           context:self.context];
        
        safariController.appActivities = self.appActivities;
        return safariController;
    }
#else
    MSID_LOG_WITH_CTX(MSIDLogLevelInfo, nil, @"Couldn't create session on macOS. Safari allowed flag %d", safariAllowed);
#endif
    
    return nil;
}

- (void)notifyEndWebAuthWithURL:(NSURL *)url
                          error:(NSError *)error
{
    
    // If the web auth session is ended, make sure that active background tasks started for the system webview session
    // have been stopped.
#if TARGET_OS_IPHONE
        [[MSIDBackgroundTaskManager sharedInstance] stopOperationWithType:MSIDBackgroundTaskTypeInteractiveRequest];
#endif
    
    if (error)
    {
        [MSIDNotifications notifyWebAuthDidFailWithError:error];
    }
    else
    {
        [MSIDNotifications notifyWebAuthDidCompleteWithURL:url];
    }
}

@end
#endif
