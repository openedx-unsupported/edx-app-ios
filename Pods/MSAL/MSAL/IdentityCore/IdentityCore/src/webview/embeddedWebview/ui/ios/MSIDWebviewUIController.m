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

#if !MSID_EXCLUDE_WEBKIT

#import "MSIDWebviewUIController.h"
#import "UIApplication+MSIDExtensions.h"
#import "MSIDAppExtensionUtil.h"
#import "MSIDBackgroundTaskManager.h"
#import "MSIDMainThreadUtil.h"

static WKWebViewConfiguration *s_webConfig;

@interface MSIDWebviewUIController ()
{
    UIActivityIndicatorView *_loadingIndicator;
}

@property (nonatomic) BOOL presentInParentController;

@end

@implementation MSIDWebviewUIController

+ (void)initialize
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        s_webConfig = [MSIDWebviewUIController defaultWKWebviewConfiguration];
    });
}

+ (WKWebViewConfiguration *)defaultWKWebviewConfiguration
{
    WKWebViewConfiguration *webConfig = [WKWebViewConfiguration new];

    if (@available(iOS 9.0, *))
    {
        webConfig.applicationNameForUserAgent = kMSIDPKeyAuthKeyWordForUserAgent;
    }
    
    if (@available(iOS 13.0, *))
    {
        webConfig.defaultWebpagePreferences.preferredContentMode = WKContentModeMobile;
    }
    return webConfig;
}

- (id)initWithContext:(id<MSIDRequestContext>)context
{
    self = [super init];
    if (self)
    {
        _context = context;
    }
    
    return self;
}

- (id)initWithContext:(id<MSIDRequestContext>)context
       platformParams:(MSIDWebViewPlatformParams *)platformParams
{
    self = [super init];
    if (self)
    {
        _context = context;
        _platformParams = platformParams;
    }

    return self;
}

- (void)dealloc
{
    [[MSIDBackgroundTaskManager sharedInstance] stopOperationWithType:MSIDBackgroundTaskTypeInteractiveRequest];
}

- (BOOL)loadView:(NSError **)error
{
    /* Start background transition tracking,
     so we can start a background task, when app transitions to background */
    [[MSIDBackgroundTaskManager sharedInstance] startOperationWithType:MSIDBackgroundTaskTypeInteractiveRequest];
    
    if (_webView)
    {
        self.presentInParentController = NO;
        return YES;
    }
    
    // Get UI container to hold the webview
    // Need parent controller to proceed
    if (![self obtainParentController])
    {
        if (error)
        {
            *error = MSIDCreateError(MSIDErrorDomain, MSIDErrorNoMainViewController, @"The Application does not have a current ViewController", nil, nil, nil, _context.correlationId, nil, YES);
        }
        return NO;
    }
    UIView *rootView = [self view];
    [rootView setFrame:[[UIScreen mainScreen] bounds]];
    [rootView setAutoresizesSubviews:YES];
    [rootView setAutoresizingMask:UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight];
    
    // Prepare the WKWebView
    WKWebView *webView = [[WKWebView alloc] initWithFrame:rootView.frame configuration:s_webConfig];
    [webView setAccessibilityIdentifier:@"MSID_SIGN_IN_WEBVIEW"];
    
    // Customize the UI
    [webView setAutoresizingMask:UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight];
    [self setupCancelButton];
    _loadingIndicator = [self prepareLoadingIndicator:rootView];
    self.view = rootView;
    
    // Append webview and loading indicator
    _webView = webView;
    [rootView addSubview:_webView];
    [rootView addSubview:_loadingIndicator];
    
    // WKWebView was created by MSAL, present it in parent controller.
    // Otherwise we rely on developer to show the web view.
    self.presentInParentController = YES;
    
    return YES;
}

- (void)presentView
{
    if (!self.presentInParentController) return;
    
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:self];
    [navController setModalPresentationStyle:_presentationType];
    
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 130000
    if (@available(iOS 13.0, *)) {
        [navController setModalInPresentation:YES];
    }
#endif
    
    [MSIDMainThreadUtil executeOnMainThreadIfNeeded:^{
        [self.parentController presentViewController:navController animated:YES completion:nil];
    }];
}

- (void)dismissWebview:(void (^)(void))completion
{
    __typeof__(self.parentController) parentController = self.parentController;
    
    //if webview is created by us, dismiss and then complete and return;
    //otherwise just complete and return.
    if (parentController && self.presentInParentController)
    {
        [parentController dismissViewControllerAnimated:YES completion:completion];
    }
    else
    {
        completion();
    }
    
    self.parentController = nil;
}

- (void)showLoadingIndicator
{
    [_loadingIndicator setHidden:NO];
    [_loadingIndicator startAnimating];
}

- (void)dismissLoadingIndicator
{
    [_loadingIndicator setHidden:YES];
    [_loadingIndicator stopAnimating];
}

- (BOOL)obtainParentController
{
    __typeof__(self.parentController) parentController = self.parentController;
    
    if (parentController) return YES;
    
    if (@available(iOS 13.0, *)) return NO;
    
    parentController = [UIApplication msidCurrentViewController:parentController];
    
    return parentController != nil;
}

- (void)setupCancelButton
{
    UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                                                  target:self
                                                                                  action:@selector(userCancel)];
    self.navigationItem.leftBarButtonItem = cancelButton;
}

- (UIActivityIndicatorView *)prepareLoadingIndicator:(UIView *)rootView
{
    UIActivityIndicatorView *loadingIndicator;
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 130000
    if (@available(iOS 13.0, *))
    {
        loadingIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleLarge];
    }
#if !TARGET_OS_MACCATALYST
    else
    {
        loadingIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    }
#endif
#else
    loadingIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
#endif

    [loadingIndicator setColor:[UIColor blackColor]];
    [loadingIndicator setCenter:rootView.center];
    return loadingIndicator;
}

// This is reserved for subclass to handle programatic cancellation.
- (void)cancel
{
    // Overridden in subclass with cancel logic
}

- (void)userCancel
{
    // Overridden in subclass with userCancel logic
}

@end

#endif
