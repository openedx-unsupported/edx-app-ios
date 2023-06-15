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

#import "MSIDOIDCSignoutRequest.h"
#import "MSIDInteractiveRequestParameters.h"
#import "MSIDAuthority.h"
#import "MSIDAccountIdentifier.h"
#import "MSIDSignoutWebRequestConfiguration.h"
#import "MSIDOauth2Factory.h"
#import "MSIDWebviewFactory.h"
#import "MSIDWebviewAuthorization.h"
#import "MSIDMainThreadUtil.h"

@interface MSIDOIDCSignoutRequest()

@property (nonatomic, nonnull) MSIDInteractiveRequestParameters *requestParameters;
@property (nonatomic, nonnull) MSIDOauth2Factory *oauthFactory;

@end

@implementation MSIDOIDCSignoutRequest

#pragma mark - Init

- (nullable instancetype)initWithRequestParameters:(nonnull MSIDInteractiveRequestParameters *)parameters
                                      oauthFactory:(nonnull MSIDOauth2Factory *)oauthFactory
{
    self = [super init];
    
    if (self)
    {
        _requestParameters = parameters;
        _oauthFactory = oauthFactory;
    }
    
    return self;
}

#pragma mark - Execute

- (void)executeRequestWithCompletion:(nonnull MSIDSignoutRequestCompletionBlock)completionBlock
{
    NSString *upn = self.requestParameters.accountIdentifier.displayableId;

    [self.requestParameters.authority resolveAndValidate:self.requestParameters.validateAuthority
                                       userPrincipalName:upn
                                                 context:self.requestParameters
                                         completionBlock:^(__unused NSURL *openIdConfigurationEndpoint,
                                         __unused BOOL validated, NSError *localError)
     {
         if (localError)
         {
             completionBlock(NO, localError);
             return;
         }

         [self.requestParameters.authority loadOpenIdMetadataWithContext:self.requestParameters
                                                         completionBlock:^(__unused MSIDOpenIdProviderMetadata *metadata, NSError *loadError)
          {
             if (loadError)
             {
                 completionBlock(NO, loadError);
                 return;
             }
             
             [MSIDMainThreadUtil executeOnMainThreadIfNeeded:^{
                 [self executeRequestWithCompletionImpl:completionBlock];
             }];
             
         }];
     }];
}

- (void)executeRequestWithCompletionImpl:(nonnull MSIDSignoutRequestCompletionBlock)completionBlock
{
    MSIDSignoutWebRequestConfiguration *configuration = [self.oauthFactory.webviewFactory logoutWebRequestConfigurationWithRequestParameters:self.requestParameters];
    
    NSObject<MSIDWebviewInteracting> *webView = [self.oauthFactory.webviewFactory webViewWithConfiguration:configuration
                                                                                         requestParameters:self.requestParameters
                                                                                                   context:self.requestParameters];
    
    if (!webView)
    {
        NSError *error = MSIDCreateError(MSIDErrorDomain, MSIDErrorInternal, @"Unexpected error. Didn't find any supported web browsers", nil, nil, nil, nil, nil, YES);
        if (completionBlock) completionBlock(NO, error);
        return;
    }
    
    [MSIDWebviewAuthorization startSessionWithWebView:webView
                                        oauth2Factory:self.oauthFactory
                                        configuration:configuration
                                              context:self.requestParameters
                                    completionHandler:^(MSIDWebviewResponse *response, NSError *error)
    {
        if (error && !([error.domain isEqualToString:MSIDErrorDomain] && error.code == MSIDErrorUserCancel))
        {
            MSID_LOG_WITH_CTX_PII(MSIDLogLevelError, self.requestParameters, @"Encountered an error in logout request handling %@", MSID_PII_LOG_MASKABLE(error));
            if (completionBlock) completionBlock(NO, error);
            return;
        }
        
        MSID_LOG_WITH_CTX_PII(MSIDLogLevelInfo, self.requestParameters, @"Completed logout request successfully with response %@", MSID_EUII_ONLY_LOG_MASKABLE(response));
        if (completionBlock) completionBlock(YES, nil);
    }];
}

@end
