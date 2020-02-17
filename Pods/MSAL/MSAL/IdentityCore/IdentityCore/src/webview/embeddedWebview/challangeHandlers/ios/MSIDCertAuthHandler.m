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
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.


#import "MSIDCertAuthHandler+iOS.h"
#import <SafariServices/SafariServices.h>
#import "MSIDWebviewAuthorization.h"
#import "MSIDOAuth2EmbeddedWebviewController.h"
#import "UIApplication+MSIDExtensions.h"
#import "MSIDMainThreadUtil.h"

#if !MSID_EXCLUDE_SYSTEMWV

static NSArray<UIActivity *> *s_activities = nil;
static NSObject<SFSafariViewControllerDelegate> *s_safariDelegate = nil;
static SFSafariViewController *s_safariController = nil;
static BOOL s_certAuthInProgress = NO;
static ChallengeCompletionHandler s_challengeCompletionHandler = nil;
static NSString *s_redirectPrefix = nil;
static NSString *s_redirectScheme = nil;

@interface MSIDCertAuthDelegate: NSObject<SFSafariViewControllerDelegate>
@end

@implementation MSIDCertAuthDelegate
/*! @abstract Delegate callback called when the user taps the Done button. Upon this call, the view controller is dismissed modally. */
- (void)safariViewControllerDidFinish:(__unused SFSafariViewController *)controller
{
    NSError *cancelledError = MSIDCreateError(MSIDErrorDomain, MSIDErrorUserCancel, @"Certificate based authentication got cancelled", nil, nil, nil, nil, nil, YES);
    [MSIDCertAuthHandler completeCertAuthChallenge:nil error:cancelledError];
}

/*! @abstract Invoked when the initial URL load is complete.
 @param didLoadSuccessfully YES if loading completed successfully, NO if loading failed.
 @discussion This method is invoked when SFSafariViewController completes the loading of the URL that you pass
 to its initializer. It is not invoked for any subsequent page loads in the same SFSafariViewController instance.
 */
- (void)safariViewController:(__unused SFSafariViewController *)controller didCompleteInitialLoad:(__unused BOOL)didLoadSuccessfully
{
    
}

- (NSArray<UIActivity*>*)safariViewController:(__unused SFSafariViewController *)controller activityItemsForURL:(__unused NSURL *)URL title:(__unused NSString *)title
{
    return s_activities;
}
@end

#endif

@implementation MSIDCertAuthHandler

#if TARGET_OS_IPHONE && !MSID_EXCLUDE_SYSTEMWV

+ (void)load
{
    s_safariDelegate = [MSIDCertAuthDelegate new];
}

+ (void)setRedirectUriPrefix:(NSString *)prefix
                   forScheme:(NSString *)scheme
{
    s_redirectScheme = scheme;
    s_redirectPrefix = prefix;
}

+ (void)setCustomActivities:(NSArray<UIActivity *> *)activities
{
    s_activities = activities;
}

+ (BOOL)completeCertAuthChallenge:(NSURL *)endUrl error:(NSError *)error
{
    MSID_LOG_WITH_CTX_PII(MSIDLogLevelInfo, nil, @"Complete cert auth challenge with end URL: %@", [endUrl msidPIINullifiedURL]);
    
    if (s_certAuthInProgress)
    {
        s_certAuthInProgress = NO;
        
        MSIDWebviewSession *currentSession = [MSIDWebviewAuthorization currentSession];
        MSIDOAuth2EmbeddedWebviewController *embeddedViewController = (MSIDOAuth2EmbeddedWebviewController  *)currentSession.webviewController;
        
        [MSIDMainThreadUtil executeOnMainThreadIfNeeded:^{
            [s_safariController dismissViewControllerAnimated:YES completion:nil];
            
            if (endUrl || error)
            {
                [embeddedViewController endWebAuthWithURL:endUrl error:error];
            }
            else
            {
                NSError *error = MSIDCreateError(MSIDErrorDomain, MSIDErrorInternal, @"Unexpected Cert Auth response received.", nil, nil, nil, nil, nil, YES);
                [embeddedViewController endWebAuthWithURL:nil error:error];
            }
        }];
        
        return YES;
    }
    
    return NO;
}

#endif

+ (void)resetHandler { }

+ (BOOL)handleChallenge:(NSURLAuthenticationChallenge *)challenge
                webview:(__unused WKWebView *)webview
#if TARGET_OS_IPHONE
       parentController:(UIViewController *)parentViewController
#endif
                context:(id<MSIDRequestContext>)context
      completionHandler:(ChallengeCompletionHandler)completionHandler
{
#if !MSID_EXCLUDE_SYSTEMWV
    MSIDWebviewSession *currentSession = [MSIDWebviewAuthorization currentSession];
    
    if (!currentSession)
    {
        MSID_LOG_WITH_CTX(MSIDLogLevelError, context, @"There is no current session open to continue with the cert auth challenge.");
        return NO;
    }
    
    MSID_LOG_WITH_CTX_PII(MSIDLogLevelInfo, context, @"Received CertAuthChallengehost from : %@", MSID_PII_LOG_TRACKABLE(challenge.protectionSpace.host));
    
    NSURL *requestURL = [currentSession.webviewController startURL];
    
    if (s_redirectScheme)
    {
        NSURLComponents *requestURLComponents = [NSURLComponents componentsWithURL:requestURL resolvingAgainstBaseURL:NO];
        NSArray<NSURLQueryItem *> *queryItems = [requestURLComponents queryItems];
        NSMutableDictionary *newQueryItems = [NSMutableDictionary new];
        NSString *redirectSchemePrefix = [NSString stringWithFormat:@"%@://", s_redirectScheme];
        
        for (NSURLQueryItem *item in queryItems)
        {
            if ([item.name isEqualToString:MSID_OAUTH2_REDIRECT_URI]
                && ![item.value.lowercaseString hasPrefix:redirectSchemePrefix.lowercaseString])
            {
                newQueryItems[MSID_OAUTH2_REDIRECT_URI] = [s_redirectPrefix stringByAppendingString:item.value.msidURLEncode];
            }
            else
            {
                newQueryItems[item.name] = item.value;
            }
        }
        requestURLComponents.percentEncodedQuery = [newQueryItems msidURLEncode];
        requestURL = requestURLComponents.URL;
    }
    
    s_safariController = nil;
    s_challengeCompletionHandler = completionHandler;
    s_certAuthInProgress = YES;
    
    [MSIDMainThreadUtil executeOnMainThreadIfNeeded:^{
        // This will launch a Safari view within the current Application, removing the app flip. Our control of this
        // view is extremely limited. Safari is still running in a separate sandbox almost completely isolated from us.
        s_safariController = [[SFSafariViewController alloc] initWithURL:requestURL];
        s_safariController.delegate = s_safariDelegate;
        
        UIViewController *currentViewController = [UIApplication msidCurrentViewController:parentViewController];
        [currentViewController presentViewController:s_safariController animated:YES completion:nil];
    }];
    
    // Cancel the Cert Auth Challenge happened in UIWebview, as we have already handled it in SFSafariViewController
    completionHandler(NSURLSessionAuthChallengeCancelAuthenticationChallenge, NULL);
    
    return YES;
#else
    return NO;
#endif
}

@end
