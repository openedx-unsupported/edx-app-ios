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

#import <WebKit/WebKit.h>
#import "MSIDNTLMHandler.h"
#import "MSIDChallengeHandler.h"
#import "MSIDNTLMUIPrompt.h"

@implementation MSIDNTLMHandler

+ (void)load
{
    [MSIDChallengeHandler registerHandler:self
                               authMethod:NSURLAuthenticationMethodNTLM];
}

+ (void)resetHandler
{
    @synchronized(self)
    {
        [MSIDNTLMUIPrompt dismissPrompt];
    }
}

+ (BOOL)handleChallenge:(NSURLAuthenticationChallenge *)challenge
                webview:(__unused WKWebView *)webview
#if TARGET_OS_IPHONE
       parentController:(UIViewController *)parentViewController
#endif
                context:(id<MSIDRequestContext>)context
      completionHandler:(ChallengeCompletionHandler)completionHandler
{
    @synchronized(self)
    {
        // This is the NTLM challenge: use the identity to authenticate:
        
        MSID_LOG_WITH_CTX_PII(MSIDLogLevelInfo, context, @"Attempting to handle NTLM challenge host: %@", MSID_PII_LOG_TRACKABLE(challenge.protectionSpace.host));
#if TARGET_OS_IPHONE
        [MSIDNTLMUIPrompt presentPromptInParentController:parentViewController completionHandler:^(NSString *username, NSString *password, BOOL cancel)
#else
        [MSIDNTLMUIPrompt presentPrompt:^(NSString *username, NSString *password, BOOL cancel)
#endif
         {
             if (cancel)
             {
                 MSID_LOG_WITH_CTX_PII(MSIDLogLevelInfo, context, @"NTLM challenge cancelled - host: %@", MSID_PII_LOG_TRACKABLE(challenge.protectionSpace.host));
                 
                 completionHandler(NSURLSessionAuthChallengePerformDefaultHandling, nil);
             }
             else
             {
                 NSURLCredential *credential = [NSURLCredential credentialWithUser:username
                                                                          password:password
                                                                       persistence:NSURLCredentialPersistenceForSession];
                 
                 completionHandler(NSURLSessionAuthChallengeUseCredential, credential);
                 
                 MSID_LOG_WITH_CTX_PII(MSIDLogLevelInfo, context, @"NTLM credentials added - host: %@", MSID_PII_LOG_TRACKABLE(challenge.protectionSpace.host));
             }
         }];
    }//@synchronized
    
    return YES;
}

@end
