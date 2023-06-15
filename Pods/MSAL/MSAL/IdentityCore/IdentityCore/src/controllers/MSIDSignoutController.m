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

#import "MSIDSignoutController.h"
#if MSID_ENABLE_SSO_EXTENSION
#import <AuthenticationServices/AuthenticationServices.h>
#import "MSIDSSOExtensionSignoutRequest.h"
#import "ASAuthorizationSingleSignOnProvider+MSIDExtensions.h"
#endif
#import "MSIDInteractiveRequestParameters.h"
#import "MSIDRequestParameters+Broker.h"
#import "MSIDOIDCSignoutRequest.h"

@interface MSIDSignoutController()

@property (nonatomic) MSIDInteractiveRequestParameters *parameters;
@property (nonatomic) BOOL shouldSignoutFromBrowser;
@property (nonatomic) MSIDOauth2Factory *factory;
@property (nonatomic) MSIDOIDCSignoutRequest *currentRequest;

@end

@implementation MSIDSignoutController

- (instancetype)initWithRequestParameters:(MSIDInteractiveRequestParameters *)parameters
                 shouldSignoutFromBrowser:(BOOL)shouldSignoutFromBrowser
                             oauthFactory:(MSIDOauth2Factory *)oauthFactory
                                    error:(NSError **)error
{
    if (!parameters || !oauthFactory)
    {
        if (error)
        {
            *error = MSIDCreateError(MSIDErrorDomain, MSIDErrorInvalidInternalParameter, @"Missing required parameter to execute signout request", nil, nil, nil, nil, nil, YES);
        }
        
        return nil;
    }
    
    self = [super init];
    
    if (self)
    {
        _parameters = parameters;
        _shouldSignoutFromBrowser = shouldSignoutFromBrowser;
        _factory = oauthFactory;
    }
    
    return self;
}

- (void)executeRequestWithCompletion:(MSIDSignoutRequestCompletionBlock)completionBlock
{
    if (!completionBlock) return;
    
    if (!self.shouldSignoutFromBrowser)
    {
        completionBlock(YES, nil);
        return;
    }
    
    self.currentRequest = [[MSIDOIDCSignoutRequest alloc] initWithRequestParameters:self.parameters oauthFactory:self.factory];
    
    [self.currentRequest executeRequestWithCompletion:^(BOOL success, NSError * _Nullable error) {
        
        if (!success)
        {
            MSID_LOG_WITH_CTX_PII(MSIDLogLevelError, self.parameters, @"Failed to perform local signout request with error %@", MSID_PII_LOG_MASKABLE(error));
        }
        
        self.currentRequest = nil;
        completionBlock(success, error);
    }];
}

@end
