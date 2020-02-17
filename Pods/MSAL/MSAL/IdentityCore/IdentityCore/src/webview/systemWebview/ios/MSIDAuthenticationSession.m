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

#import "MSIDAuthenticationSession.h"

#import "MSIDWebviewAuthorization.h"
#import "MSIDWebOAuth2Response.h"
#import "MSIDTelemetry+Internal.h"
#import "MSIDTelemetryUIEvent.h"
#import "MSIDTelemetryEventStrings.h"
#import "MSIDNotifications.h"
#import "MSIDBackgroundTaskManager.h"
#if !MSID_EXCLUDE_WEBKIT
#import <SafariServices/SafariServices.h>
#import <AuthenticationServices/AuthenticationServices.h>
#endif
#import "UIApplication+MSIDExtensions.h"

#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 130000 && !MSID_EXCLUDE_WEBKIT
@interface MSIDAuthenticationSession (ASWebAuth) <ASWebAuthenticationPresentationContextProviding>

@end

@implementation MSIDAuthenticationSession (ASWebAuth)

- (ASPresentationAnchor)presentationAnchorForWebAuthenticationSession:(__unused ASWebAuthenticationSession *)session
API_AVAILABLE(ios(13.0))
{
    return [self presentationAnchor];
}

- (ASPresentationAnchor)presentationAnchor API_AVAILABLE(ios(13.0))
{
    if (![NSThread isMainThread])
    {
        __block ASPresentationAnchor anchor;
        dispatch_sync(dispatch_get_main_queue(), ^{
            anchor = [self presentationAnchor];
        });
        
        return anchor;
    }
    
    return self.parentController.view.window;
}

@end
#endif

@implementation MSIDAuthenticationSession
{
#if !MSID_EXCLUDE_WEBKIT
    
#if !TARGET_OS_MACCATALYST
    API_AVAILABLE(ios(11.0))
    SFAuthenticationSession *_authSession;
#endif
    
    API_AVAILABLE(ios(12.0))
    ASWebAuthenticationSession *_webAuthSession;
    
#endif
    
    NSURL *_startURL;
    NSString *_callbackURLScheme;

    id<MSIDRequestContext> _context;
    
    MSIDWebUICompletionHandler _completionHandler;
    
    NSString *_telemetryRequestId;
    MSIDTelemetryUIEvent *_telemetryEvent;
}

- (instancetype)initWithURL:(NSURL *)url
          callbackURLScheme:(NSString *)callbackURLScheme
                    context:(id<MSIDRequestContext>)context
{
    self = [super init];
    if (self)
    {
        _startURL = url;
        _context = context;
        _callbackURLScheme = callbackURLScheme;
    }
    
    return self;
}

- (instancetype)initWithURL:(NSURL *)url
          callbackURLScheme:(NSString *)callbackURLScheme
           parentController:(UIViewController *)parentController
 ephemeralWebBrowserSession:(BOOL)prefersEphemeralWebBrowserSession
                    context:(id<MSIDRequestContext>)context
{
    self = [self initWithURL:url callbackURLScheme:callbackURLScheme context:context];
    if (self)
    {
        _parentController = parentController;
        _prefersEphemeralWebBrowserSession = prefersEphemeralWebBrowserSession;
    }
    
    return self;
}

- (BOOL)isErrorCodeCanceledLogin:(NSError *)error
{
    if (!error)
    {
        return NO;
    }

#if !MSID_EXCLUDE_WEBKIT
    if (@available(iOS 12.0, *))
    {
        if (error.code == ASWebAuthenticationSessionErrorCodeCanceledLogin) return YES;
    }
    else if (@available(iOS 11.0, *))
    {
#if !TARGET_OS_MACCATALYST
        if (error.code == SFAuthenticationErrorCanceledLogin) return YES;
#endif
    }
#endif
    
    return NO;
}

- (void)startWithCompletionHandler:(MSIDWebUICompletionHandler)completionHandler
{
    if (!completionHandler)
    {
        MSID_LOG_WITH_CTX(MSIDLogLevelWarning,_context, @"CompletionHandler cannot be nil for interactive session.");
        return;
    }

#if !MSID_EXCLUDE_WEBKIT
    
    [[MSIDBackgroundTaskManager sharedInstance] startOperationWithType:MSIDBackgroundTaskTypeInteractiveRequest];

    NSError *error = nil;
    
    if (@available(iOS 11.0, *))
    {
        _telemetryRequestId = [_context telemetryRequestId];
        [[MSIDTelemetry sharedInstance] startEvent:_telemetryRequestId eventName:MSID_TELEMETRY_EVENT_UI_EVENT];
        _telemetryEvent = [[MSIDTelemetryUIEvent alloc] initWithName:MSID_TELEMETRY_EVENT_UI_EVENT
                                                             context:_context];
        
        _completionHandler = [completionHandler copy];
        
        void (^authCompletion)(NSURL *, NSError *) = ^void(NSURL *callbackURL, NSError *authError)
        {
            if ([self isErrorCodeCanceledLogin:authError])
            {
                authError = MSIDCreateError(MSIDErrorDomain, MSIDErrorUserCancel, @"User cancelled the authorization session.", nil, nil, nil, _context.correlationId, nil, YES);
                [_telemetryEvent setIsCancelled:YES];
            }
            
            [[MSIDTelemetry sharedInstance] stopEvent:_telemetryRequestId event:_telemetryEvent];
            
            [self notifyEndWebAuthWithURL:callbackURL error:authError];
            _completionHandler(callbackURL, authError);
        };

        [MSIDNotifications notifyWebAuthDidStartLoad:_startURL userInfo:nil];
        
        if (@available(iOS 12.0, *))
        {
            _webAuthSession = [[ASWebAuthenticationSession alloc] initWithURL:_startURL
                                                            callbackURLScheme:_callbackURLScheme
                                                            completionHandler:authCompletion];
            
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 130000
            if (@available(iOS 13.0, *))
            {
                _webAuthSession.presentationContextProvider = self;
                _webAuthSession.prefersEphemeralWebBrowserSession = self.prefersEphemeralWebBrowserSession;
            }
#endif
            if ([_webAuthSession start]) return;
        }
        else
        {
#if !TARGET_OS_MACCATALYST
            _authSession = [[SFAuthenticationSession alloc] initWithURL:_startURL
                                                      callbackURLScheme:_callbackURLScheme
                                                      completionHandler:authCompletion];
            if ([_authSession start]) return;
#endif
        }
  
        error = MSIDCreateError(MSIDErrorDomain, MSIDErrorInteractiveSessionStartFailure, @"Failed to start an interactive session", nil, nil, nil, _context.correlationId, nil, YES);
    }
    else
    {
        error = MSIDCreateError(MSIDErrorDomain, MSIDErrorUnsupportedFunctionality, @"SFAuthenticationSession/ASWebAuthenticationSession is not available for iOS 10 and older.", nil, nil, nil, _context.correlationId, nil, YES);
    }
    
    [self notifyEndWebAuthWithURL:nil error:error];
    completionHandler(nil, error);
#endif
}

- (void)cancel
{
    MSID_LOG_WITH_CTX(MSIDLogLevelInfo, _context, @"Authorization session was cancelled programatically");
    [_telemetryEvent setIsCancelled:YES];
    [[MSIDTelemetry sharedInstance] stopEvent:_telemetryRequestId event:_telemetryEvent];
    
    if (@available(iOS 12.0, *))
    {
        [_webAuthSession cancel];
    }
#if !TARGET_OS_MACCATALYST
    else
    {
        [_authSession cancel];
    }
#endif
    
    NSError *error = MSIDCreateError(MSIDErrorDomain,
                                     MSIDErrorSessionCanceledProgrammatically,
                                     @"Authorization session was cancelled programatically.", nil, nil, nil, _context.correlationId, nil, YES);
    
    [self notifyEndWebAuthWithURL:nil error:error];
    _completionHandler(nil, error);
}

- (void)notifyEndWebAuthWithURL:(NSURL *)url
                          error:(NSError *)error
{
    [[MSIDBackgroundTaskManager sharedInstance] stopOperationWithType:MSIDBackgroundTaskTypeInteractiveRequest];
    
    if (error)
    {
        [MSIDNotifications notifyWebAuthDidFailWithError:error];
    }
    else
    {
        [MSIDNotifications notifyWebAuthDidCompleteWithURL:url];
    }
}

- (BOOL)handleURLResponse:(NSURL *)url
{
    [[MSIDTelemetry sharedInstance] stopEvent:_telemetryRequestId event:_telemetryEvent];
    
    if (@available(iOS 12.0, *))
    {
        [_webAuthSession cancel];
    }
    else
    {
        [_authSession cancel];
    }
    
    [self notifyEndWebAuthWithURL:url error:nil];
    _completionHandler(url, nil);
    return YES;
}

- (void)dealloc
{
    [[MSIDBackgroundTaskManager sharedInstance] stopOperationWithType:MSIDBackgroundTaskTypeInteractiveRequest];
}

@end
#endif
