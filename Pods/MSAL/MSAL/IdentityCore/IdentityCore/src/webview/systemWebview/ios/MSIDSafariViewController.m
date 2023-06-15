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

#import "MSIDSafariViewController.h"
#import "MSIDSystemWebviewController.h"
#import <SafariServices/SafariServices.h>
#import "MSIDWebOAuth2AuthCodeResponse.h"
#import "UIApplication+MSIDExtensions.h"
#import "MSIDWebviewAuthorization.h"
#import "MSIDMainThreadUtil.h"

@interface MSIDSafariViewController() <SFSafariViewControllerDelegate>

@end

@implementation MSIDSafariViewController
{
    SFSafariViewController *_safariViewController;
    
    NSURL *_startURL;
    
    MSIDWebUICompletionHandler _completionHandler;
    
    id<MSIDRequestContext> _context;
}

- (instancetype)initWithURL:(NSURL *)url
           parentController:(UIViewController *)parentController
           presentationType:(UIModalPresentationStyle)presentationType
                    context:(id<MSIDRequestContext>)context
{
    self = [super init];
    if (self)
    {
        _startURL = url;
        _context = context;
        __auto_type config = [SFSafariViewControllerConfiguration new];
        config.entersReaderIfAvailable = NO;
        _safariViewController = [[SFSafariViewController alloc] initWithURL:url configuration:config];
        _safariViewController.delegate = self;
        _safariViewController.modalPresentationStyle = presentationType;
        
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 130000
        if (@available(iOS 13.0, *)) {
            _safariViewController.modalInPresentation = YES;
        }
#endif

        _parentController = parentController;
    }
    return self;
}

- (void)cancelProgrammatically
{
    NSError *error = MSIDCreateError(MSIDErrorDomain, MSIDErrorSessionCanceledProgrammatically, @"Authorization session was cancelled programatically", nil, nil, nil, _context.correlationId, nil, YES);
    
    [self completeSessionWithResponse:nil context:_context error:error];
}

- (void)userCancel
{
    NSError *error = MSIDCreateError(MSIDErrorDomain, MSIDErrorUserCancel, @"User cancelled the authorization session.", nil, nil, nil, _context.correlationId, nil, YES);

    [self completeSessionWithResponse:nil context:_context error:error];
}


- (void)startWithCompletionHandler:(MSIDWebUICompletionHandler)completionHandler
{
    if (!completionHandler)
    {
        MSID_LOG_WITH_CTX(MSIDLogLevelWarning,_context, @"CompletionHandler cannot be nil for interactive session.");
        return;
    }
    
    [MSIDMainThreadUtil executeOnMainThreadIfNeeded:^{
        
        UIViewController *viewController = [UIApplication msidCurrentViewController:self.parentController];
        if (!viewController)
        {
            NSError *error = MSIDCreateError(MSIDErrorDomain, MSIDErrorNoMainViewController, @"Failed to start an interactive session - main viewcontroller is nil", nil, nil, nil, self->_context.correlationId, nil, YES);
            completionHandler(nil, error);
            return;
        }
        
        self->_completionHandler = [completionHandler copy];
        [viewController presentViewController:self->_safariViewController animated:YES completion:nil];
    }];
}

- (BOOL)completeSessionWithResponse:(NSURL *)url
                            context:(__unused id<MSIDRequestContext>)context
                              error:(NSError *)error
{
    [self dismiss];
    
    if (error)
    {
        _completionHandler(nil, error);
        return NO;
    }

    _completionHandler(url, nil);
    return YES;
}

- (void)dismiss
{
    [MSIDMainThreadUtil executeOnMainThreadIfNeeded:^{
        [self->_safariViewController dismissViewControllerAnimated:YES completion:^{
            self->_safariViewController = nil;
        }];
    }];
}

#pragma mark - SFSafariViewControllerDelegate
- (void)safariViewControllerDidFinish:(__unused SFSafariViewController *)controller
{
    // user cancel
    NSError *error = MSIDCreateError(MSIDErrorDomain, MSIDErrorUserCancel, @"User cancelled the authorization session.", nil, nil, nil, _context.correlationId, nil, YES);
    [self completeSessionWithResponse:nil
                              context:_context error:error];
}

- (NSArray<UIActivity*>*)safariViewController:(__unused SFSafariViewController *)controller activityItemsForURL:(__unused NSURL *)URL title:(__unused NSString *)title
{
    return self.appActivities;
}

@end
#endif
