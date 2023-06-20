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

#import "MSIDChallengeHandler.h"
#import "MSIDClientTLSHandler.h"
#import "MSIDCertAuthHandler.h"
#import "MSIDWPJChallengeHandler.h"

@implementation MSIDClientTLSHandler

+ (void)load
{
    [MSIDChallengeHandler registerHandler:self authMethod:NSURLAuthenticationMethodClientCertificate];
}

+ (void)resetHandler
{
    [MSIDCertAuthHandler resetHandler];
}

+ (BOOL)handleChallenge:(NSURLAuthenticationChallenge *)challenge
                webview:(WKWebView *)webview
#if TARGET_OS_IPHONE
       parentController:(UIViewController *)parentViewController
#endif
                context:(id<MSIDRequestContext>)context
      completionHandler:(ChallengeCompletionHandler)completionHandler
{
    NSString *host = challenge.protectionSpace.host;
    
    MSID_LOG_WITH_CTX_PII(MSIDLogLevelInfo, context, @"Attempting to handle client TLS challenge. host: %@", MSID_PII_LOG_TRACKABLE(host));
    
    // See if this is a challenge for the WPJ cert.
    if ([MSIDWPJChallengeHandler shouldHandleChallenge:challenge])
    {
        return [MSIDWPJChallengeHandler handleChallenge:challenge
                                                webview:webview
#if TARGET_OS_IPHONE
                                       parentController:parentViewController
#endif
                                                context:context
                                      completionHandler:completionHandler];
    }
    
    // If it is not WPJ challenge, it has to be CBA.
    return [MSIDCertAuthHandler handleChallenge:challenge
                                        webview:webview
#if TARGET_OS_IPHONE
                               parentController:parentViewController
#endif
                                        context:context
                              completionHandler:completionHandler];
}

@end
