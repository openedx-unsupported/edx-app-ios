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


#import "MSIDAADRequestErrorHandler.h"
#import "MSIDHttpResponseSerializer.h"
#import "MSIDAADJsonResponsePreprocessor.h"
#import "MSIDAADTokenResponse.h"
#import "MSIDWorkPlaceJoinConstants.h"
#import "MSIDPKeyAuthHandler.h"
#import "MSIDMainThreadUtil.h"

@implementation MSIDAADRequestErrorHandler

- (void)handleError:(NSError *)error
       httpResponse:(NSHTTPURLResponse *)httpResponse
               data:(NSData *)data
        httpRequest:(NSObject<MSIDHttpRequestProtocol> *)httpRequest
 responseSerializer:(id<MSIDResponseSerialization>)responseSerializer
            context:(id<MSIDRequestContext>)context
    completionBlock:(MSIDHttpRequestDidCompleteBlock)completionBlock
{
    if (!httpResponse)
    {
        if (completionBlock) completionBlock(nil, error);
        return;
    }
    
    BOOL shouldRetry = YES;
    shouldRetry &= httpRequest.retryCounter > 0;
    // 5xx Server errors.
    shouldRetry &= httpResponse.statusCode >= 500 && httpResponse.statusCode <= 599;

    if (shouldRetry)
    {
        httpRequest.retryCounter--;
        
        MSID_LOG_WITH_CTX(MSIDLogLevelVerbose,context, @"Retrying network request, retryCounter: %ld", (long)httpRequest.retryCounter);
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(httpRequest.retryInterval * NSEC_PER_SEC)), dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [httpRequest sendWithBlock:completionBlock];
        });
        
        return;
    }
    
    // pkeyauth challenge
    if (httpResponse.statusCode == 400 || httpResponse.statusCode == 401)
    {
        NSString *wwwAuthValue = [httpResponse.allHeaderFields valueForKey:kMSIDWwwAuthenticateHeader];
        
        if (![NSString msidIsStringNilOrBlank:wwwAuthValue] && [wwwAuthValue containsString:kMSIDPKeyAuthName])
        {
            [MSIDPKeyAuthHandler handleWwwAuthenticateHeader:wwwAuthValue
                                                  requestUrl:httpRequest.urlRequest.URL
                                                     context:context
                                           completionHandler:^void (NSString *authHeader, NSError *error){
                                               if (![NSString msidIsStringNilOrBlank:authHeader])
                                               {
                                                   // append auth header
                                                   NSMutableURLRequest *newRequest = [httpRequest.urlRequest mutableCopy];
                                                   [newRequest setValue:authHeader forHTTPHeaderField:@"Authorization"];
                                                   httpRequest.urlRequest = newRequest;
                                                   
                                                   // resend the request
                                                   dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                                                       [httpRequest sendWithBlock:completionBlock];
                                                   });
                                                   return;
                                               }
                                               
                                               if (completionBlock) { completionBlock(nil, error); }
                                           }];
            return;
        }
        
        NSError *responseError = nil;
        id responseObject = [responseSerializer responseObjectForResponse:httpResponse data:data context:context error:&responseError];
        
        if (completionBlock)
        {
            completionBlock(responseObject, responseError);
        }
        return;
    }

    id errorDescription = [NSHTTPURLResponse localizedStringForStatusCode:httpResponse.statusCode];

    MSID_LOG_WITH_CTX_PII(MSIDLogLevelWarning, context, @"Http error raised. Http Code: %ld Description %@", (long)httpResponse.statusCode, MSID_PII_LOG_MASKABLE(errorDescription));
    
    NSMutableDictionary *additionalInfo = [NSMutableDictionary new];
    [additionalInfo setValue:httpResponse.allHeaderFields
                      forKey:MSIDHTTPHeadersKey];

    [additionalInfo setValue:[NSString stringWithFormat: @"%ld", (long)httpResponse.statusCode]
                      forKey:MSIDHTTPResponseCodeKey];

    if (httpResponse.statusCode >= 500 && httpResponse.statusCode <= 599)
    {
        [additionalInfo setValue:@1 forKey:MSIDServerUnavailableStatusKey];
    }
    
    NSError *httpError = MSIDCreateError(MSIDHttpErrorCodeDomain, MSIDErrorServerUnhandledResponse, errorDescription, nil, nil, nil, context.correlationId, additionalInfo, YES);
    
    if (completionBlock) completionBlock(nil, httpError);
}

@end
