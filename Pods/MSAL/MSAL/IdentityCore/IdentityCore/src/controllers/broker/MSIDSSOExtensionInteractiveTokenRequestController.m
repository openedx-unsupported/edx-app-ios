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

#if MSID_ENABLE_SSO_EXTENSION
#import "MSIDSSOExtensionInteractiveTokenRequestController.h"
#import "MSIDLocalInteractiveController+Internal.h"
#import "ASAuthorizationSingleSignOnProvider+MSIDExtensions.h"
#import "MSIDThrottlingService.h"
#import "MSIDInteractiveTokenRequestParameters.h"
#import "MSIDDefaultTokenCacheAccessor.h"
#import "MSIDInteractiveTokenRequest+Internal.h"

@implementation MSIDSSOExtensionInteractiveTokenRequestController

- (instancetype)initWithInteractiveRequestParameters:(MSIDInteractiveTokenRequestParameters *)parameters
                                tokenRequestProvider:(id<MSIDTokenRequestProviding>)tokenRequestProvider
                                  fallbackController:(id<MSIDRequestControlling>)fallbackController
                                               error:(NSError **)error
{
    self = [super initWithInteractiveRequestParameters:parameters
                                  tokenRequestProvider:tokenRequestProvider
                                                 error:error];
    if (self)
    {
        _fallbackController = fallbackController;
    }
    
    return self;
}

#pragma mark - MSIDRequestControlling

- (void)acquireToken:(MSIDRequestCompletionBlock)completionBlock
{
    MSID_LOG_WITH_CTX(MSIDLogLevelInfo, self.requestParameters, @"Beginning interactive broker extension flow.");
    
    MSIDInteractiveTokenRequest *request = [self.tokenRequestProvider interactiveSSOExtensionTokenRequestWithParameters:self.interactiveRequestParamaters];

    MSIDRequestCompletionBlock completionBlockWrapper = ^(MSIDTokenResult *result, NSError *error)
    {
        MSID_LOG_WITH_CTX(MSIDLogLevelInfo, self.requestParameters, @"Interactive broker extension flow finished. Result %@, error: %ld error domain: %@", _PII_NULLIFY(result), (long)error.code, error.domain);
        if (!error)
        {
            /**
             Throttling service: when an interactive token succeed, we update the last refresh time of the throttling service
             */
            [MSIDThrottlingService updateLastRefreshTimeDatasource:request.extendedTokenCache context:self.interactiveRequestParamaters error:nil];
           
        }
        else if ([self shouldFallback:error])
        {
            MSID_LOG_WITH_CTX(MSIDLogLevelInfo, self.requestParameters, @"Falling back to local controller.");
            
            [self.fallbackController acquireToken:completionBlock];
            return;
        }
        
        completionBlock(result, error);
    };
    

    [self acquireTokenWithRequest:request completionBlock:completionBlockWrapper];
}

+ (BOOL)canPerformRequest
{
    return [[ASAuthorizationSingleSignOnProvider msidSharedProvider] canPerformAuthorization];
}

#pragma mark - Private

- (BOOL)shouldFallback:(NSError *)error
{
    MSID_LOG_WITH_CTX(MSIDLogLevelInfo, self.requestParameters, @"Looking if we should fallback to fallback controller, error: %ld error domain: %@.", (long)error.code, error.domain);
    
    if (!self.fallbackController)
    {
        MSID_LOG_WITH_CTX(MSIDLogLevelInfo, self.requestParameters, @"fallback controller is nil, SSO extension controller should fallback: NO");
        return NO;
    }
    
    // If it is MSIDErrorDomain and Sso Extension returns unexpected error, we should fall back to local controler and unblock user
    if (![error.domain isEqualToString:ASAuthorizationErrorDomain] && ![error.domain isEqualToString:MSIDErrorDomain]) return NO;
    
    BOOL shouldFallback = NO;
    switch (error.code)
    {
        case ASAuthorizationErrorNotHandled:
        case ASAuthorizationErrorUnknown:
        case ASAuthorizationErrorFailed:
        case MSIDErrorSSOExtensionUnexpectedError:
            shouldFallback = YES;
    }
    
    MSID_LOG_WITH_CTX(MSIDLogLevelInfo, self.requestParameters, @"SSO extension controller should fallback: %@", shouldFallback ? @"YES" : @"NO");
    
    return shouldFallback;
}

@end
#endif
