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

#import "MSIDURLSessionDelegate.h"

@implementation MSIDURLSessionDelegate

#pragma mark - NSURLSessionDelegate

- (void)URLSession:(NSURLSession *)session
didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge
 completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition disposition, NSURLCredential *credential))completionHandler
{
    NSString *authMethod = [challenge.protectionSpace.authenticationMethod lowercaseString];
    
    MSID_LOG_WITH_CTX(MSIDLogLevelVerbose,nil, @"%@ - %@. Host: %@. Previous challenge failure count: %ld", @"session:didReceiveChallenge:completionHandler", authMethod, challenge.protectionSpace.host, (long)challenge.previousFailureCount);
    
    if (self.sessionDidReceiveAuthenticationChallengeBlock)
    {
        self.sessionDidReceiveAuthenticationChallengeBlock(session, challenge, completionHandler);
    }
    else if (completionHandler)
    {
        completionHandler(NSURLSessionAuthChallengePerformDefaultHandling, nil);
    }
}

#pragma mark - NSURLSessionTaskDelegate

- (void)URLSession:(NSURLSession *)session
              task:(NSURLSessionTask *)task
didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge
 completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition disposition, NSURLCredential *credential))completionHandler
{
    NSString *authMethod = [challenge.protectionSpace.authenticationMethod lowercaseString];
    
    MSID_LOG_WITH_CTX(MSIDLogLevelVerbose,nil, @"%@ - %@. Previous challenge failure count: %ld", @"session:task:didReceiveChallenge:completionHandler", authMethod, (long)challenge.previousFailureCount);
    
    if (self.taskDidReceiveAuthenticationChallengeBlock)
    {
        self.taskDidReceiveAuthenticationChallengeBlock(session, task, challenge, completionHandler);
    }
    else if (completionHandler)
    {
        completionHandler(NSURLSessionAuthChallengePerformDefaultHandling, nil);
    }
}

- (void)URLSession:(NSURLSession *)session
              task:(NSURLSessionTask *)task
willPerformHTTPRedirection:(NSHTTPURLResponse *)response
        newRequest:(NSURLRequest *)request
 completionHandler:(void (^)(NSURLRequest *))completionHandler
{
    MSID_LOG_WITH_CTX_PII(MSIDLogLevelInfo, nil, @"Redirecting to %@", request.URL.host);
    
    if (self.taskWillPerformHTTPRedirectionBlock)
    {
        self.taskWillPerformHTTPRedirectionBlock(session, task, response, request, completionHandler);
    }
    else if (completionHandler)
    {
        completionHandler(request);
    }
}

@end
