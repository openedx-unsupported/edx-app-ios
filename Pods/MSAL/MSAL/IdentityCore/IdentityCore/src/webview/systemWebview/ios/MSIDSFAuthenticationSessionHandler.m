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

#if !MSID_EXCLUDE_WEBKIT && !TARGET_OS_MACCATALYST

#import "MSIDSFAuthenticationSessionHandler.h"
#import <SafariServices/SafariServices.h>

@interface MSIDSFAuthenticationSessionHandler()

@property (nonatomic) SFAuthenticationSession *webAuthSession;
@property (nonatomic) NSURL *startURL;
@property (nonatomic) NSString *callbackURLScheme;
@property (nonatomic) BOOL sessionDismissed;

@end

@implementation MSIDSFAuthenticationSessionHandler

- (instancetype)initWithStartURL:(NSURL *)startURL
                  callbackScheme:(NSString *)callbackURLScheme
{
    self = [super init];
    
    if (self)
    {
        _startURL = startURL;
        _callbackURLScheme = callbackURLScheme;
    }
    
    return self;
}

#pragma mark - MSIDAuthSessionHandling
                                      
- (void)startWithCompletionHandler:(MSIDWebUICompletionHandler)completionHandler
{
    void (^authCompletion)(NSURL *, NSError *) = ^void(NSURL *callbackURL, NSError *authError)
    {
        if (self.sessionDismissed)
        {
            self.webAuthSession = nil;
            return;
        }
        
        if (authError.code == SFAuthenticationErrorCanceledLogin)
        {
            NSError *cancelledError = MSIDCreateError(MSIDErrorDomain, MSIDErrorUserCancel, @"User cancelled the authorization session.", nil, nil, nil, nil, nil, YES);
            
            self.webAuthSession = nil;
            if (completionHandler) completionHandler(nil, cancelledError);
            return;
        }
        
        self.webAuthSession = nil;
        completionHandler(callbackURL, authError);
    };
    
    self.webAuthSession = [[SFAuthenticationSession alloc] initWithURL:self.startURL
                                                     callbackURLScheme:self.callbackURLScheme
                                                     completionHandler:authCompletion];
    
    if (![self.webAuthSession start])
    {
        NSError *error = MSIDCreateError(MSIDErrorDomain, MSIDErrorInteractiveSessionStartFailure, @"Failed to start an interactive session", nil, nil, nil, nil, nil, YES);
        if (completionHandler) completionHandler(nil, error);
    }
    
}

- (void)cancelProgrammatically
{
    [self.webAuthSession cancel];
}

- (void)userCancel {
     [self cancelProgrammatically];
}

- (void)dismiss
{
    self.sessionDismissed = YES;
    [self cancelProgrammatically];
}

@end

#endif
