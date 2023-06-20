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

#import "MSIDWebviewAuthorization.h"
#if TARGET_OS_IPHONE
#import <SafariServices/SafariServices.h>
#import "MSIDSystemWebviewController.h"
#endif
#import "MSIDError.h"
#import "NSURL+MSIDExtensions.h"
#import "MSIDTelemetry.h"
#import "MSIDAADOAuthEmbeddedWebviewController.h"
#import "MSIDWebviewFactory.h"
#import "MSIDMainThreadUtil.h"

@implementation MSIDWebviewAuthorization

static MSIDWebviewSession *s_currentSession = nil;

#if !MSID_EXCLUDE_WEBKIT

+ (void)startSessionWithWebView:(NSObject<MSIDWebviewInteracting> *)webview
                  oauth2Factory:(MSIDOauth2Factory *)oauth2Factory
                  configuration:(MSIDBaseWebRequestConfiguration *)configuration
                        context:(id<MSIDRequestContext>)context
              completionHandler:(MSIDWebviewAuthCompletionHandler)completionHandler
{
    MSIDWebviewSession *session = [[MSIDWebviewSession alloc] initWithWebviewController:webview
                                                                                factory:oauth2Factory.webviewFactory
                                                                          configuration:configuration];
    
    [MSIDMainThreadUtil executeOnMainThreadIfNeeded:^{
        [self startSession:session context:context completionHandler:completionHandler];
    }];
}

+ (void)startSession:(MSIDWebviewSession *)session
             context:(id<MSIDRequestContext>)context
   completionHandler:(MSIDWebviewAuthCompletionHandler)completionHandler
{
    if (!completionHandler)
    {
        MSID_LOG_WITH_CTX(MSIDLogLevelWarning,context, @"CompletionHandler cannot be nil for interactive session.");
        return;
    }
    
    // check session nil
    if (!session)
    {
        NSError *error = MSIDCreateError(MSIDErrorDomain, MSIDErrorInternal, @"Interactive session failed to create.", nil, nil, nil, context.correlationId, nil, YES);
        completionHandler(nil, error);
        return;
    }
    
    if (![self setCurrentSession:session])
    {
        NSError *error = MSIDCreateError(MSIDErrorDomain, MSIDErrorInteractiveSessionAlreadyRunning, @"Only one interactive session is allowed at a time.", nil, nil, nil, context.correlationId, nil, YES);
        completionHandler(nil, error);
        return;
    }
    
    void (^startCompletionBlock)(NSURL *, NSError *) = ^void(NSURL *callbackURL, NSError *error) {
        MSID_LOG_WITH_CTX(MSIDLogLevelInfo, context, @"Result from authorization session callbackURL host: %@ , has error: %@", callbackURL.host, error ? @"YES" : @"NO");

        if (error) {
            [MSIDWebviewAuthorization clearCurrentWebAuthSessionAndFactory];
            completionHandler(nil, error);
            return;
        }
        
        NSError *responseError = nil;
        
        MSIDWebviewResponse *response = [s_currentSession.webViewConfiguration responseWithResultURL:callbackURL
                                                                                             factory:s_currentSession.factory
                                                                                             context:context
                                                                                               error:&responseError];
        
        [MSIDWebviewAuthorization clearCurrentWebAuthSessionAndFactory];
        completionHandler(response, responseError);
    };
    
    MSID_LOG_WITH_CTX(MSIDLogLevelError, context, @"Start webview authorization session with webview controller class %@: ", [s_currentSession.webviewController class]);
    
    [s_currentSession.webviewController startWithCompletionHandler:startCompletionBlock];
}

+ (BOOL)setCurrentSession:(MSIDWebviewSession *)session
{
    @synchronized([MSIDWebviewAuthorization class])
    {
        if (s_currentSession) {
            MSID_LOG_WITH_CTX(MSIDLogLevelInfo, nil, @"Session is already running. Please wait or cancel the session before setting it new.");
            return NO;
        }
        
        s_currentSession = session;
        
        return YES;
    }
    return NO;
}


+ (void)clearCurrentWebAuthSessionAndFactory
{
    @synchronized ([MSIDWebviewAuthorization class])
    {
        if (!s_currentSession)
        {
            // There's no error param because this isn't on a critical path. Just log that you are
            // trying to clear a session when there isn't one.
            MSID_LOG_WITH_CTX(MSIDLogLevelInfo, nil, @"Trying to clear out an empty session");
        }
        
        s_currentSession = nil;
    }
}


+ (MSIDWebviewSession *)currentSession
{
    return s_currentSession;
}


+ (void)cancelCurrentSession
{
    @synchronized([MSIDWebviewAuthorization class])
    {
        if (s_currentSession)
        {
            [s_currentSession.webviewController cancelProgrammatically];
            s_currentSession = nil;
        }
    }
}

#endif

#if TARGET_OS_IPHONE && !MSID_EXCLUDE_SYSTEMWV
+ (BOOL)handleURLResponseForSystemWebviewController:(NSURL *)url
{
    @synchronized([MSIDWebviewAuthorization class])
    {
        if (s_currentSession
            && [s_currentSession.webviewController isKindOfClass:MSIDSystemWebviewController.class])
        {
            return [((MSIDSystemWebviewController *)s_currentSession.webviewController) handleURLResponse:url];
        }
    }
    return NO;
}
#endif


@end
