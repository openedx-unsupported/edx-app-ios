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

#import "MSIDAADWebviewFactory.h"
#import "MSIDWebviewConfiguration.h"
#import "NSOrderedSet+MSIDExtensions.h"
#import "MSIDWebWPJResponse.h"
#import "MSIDWebAADAuthResponse.h"
#import "MSIDDeviceId.h"
#import "MSIDAADOAuthEmbeddedWebviewController.h"
#import "MSIDWebviewSession.h"
#import "MSIDWebOpenBrowserResponse.h"
#import "MSIDInteractiveRequestParameters.h"
#import "MSIDAuthority.h"
#import "MSIDCBAWebAADAuthResponse.h"
#import "MSIDClaimsRequest+ClientCapabilities.h"

@implementation MSIDAADWebviewFactory

- (NSMutableDictionary<NSString *,NSString *> *)authorizationParametersFromConfiguration:(MSIDWebviewConfiguration *)configuration requestState:(NSString *)state
{
    NSMutableDictionary<NSString *, NSString *> *parameters = [super authorizationParametersFromConfiguration:configuration
                                                                                                 requestState:state];

    if (![NSString msidIsStringNilOrBlank:configuration.promptBehavior])
    {
        parameters[MSID_OAUTH2_PROMPT] = configuration.promptBehavior;
    }
    
    if (configuration.correlationId)
    {
        [parameters addEntriesFromDictionary:
         @{
           MSID_OAUTH2_CORRELATION_ID_REQUEST : @"true",
           MSID_OAUTH2_CORRELATION_ID_REQUEST_VALUE : [configuration.correlationId UUIDString]
           }];
    }
    
    parameters[@"haschrome"] = @"1";
    parameters[MSID_OAUTH2_CLAIMS] = configuration.claims;
    [parameters addEntriesFromDictionary:MSIDDeviceId.deviceId];
    
    if (configuration.instanceAware)
    {
        parameters[@"instance_aware"] = @"true";
    }

    return parameters;
}

#if !MSID_EXCLUDE_WEBKIT

- (MSIDWebviewSession *)embeddedWebviewSessionFromConfiguration:(MSIDWebviewConfiguration *)configuration customWebview:(WKWebView *)webview context:(id<MSIDRequestContext>)context
{
    if (![NSThread isMainThread])
    {
        __block MSIDWebviewSession *session;
        dispatch_sync(dispatch_get_main_queue(), ^{
            session = [self embeddedWebviewSessionFromConfiguration:configuration customWebview:webview context:context];
        });
        
        return session;
    }
    
    NSString *state = [self generateStateValue];
    NSURL *startURL = [self startURLFromConfiguration:configuration requestState:state];
    NSURL *redirectURL = [NSURL URLWithString:configuration.redirectUri];
    
    MSIDAADOAuthEmbeddedWebviewController *embeddedWebviewController
    = [[MSIDAADOAuthEmbeddedWebviewController alloc] initWithStartURL:startURL
                                                               endURL:redirectURL
                                                              webview:webview
                                                        customHeaders:configuration.customHeaders
                                                              context:context];
#if TARGET_OS_IPHONE
    embeddedWebviewController.parentController = configuration.parentController;
    embeddedWebviewController.presentationType = configuration.presentationType;
#endif
    
    MSIDWebviewSession *session = [[MSIDWebviewSession alloc] initWithWebviewController:embeddedWebviewController
                                                                                factory:self
                                                                           requestState:state
                                                                     ignoreInvalidState:configuration.ignoreInvalidState];
    return session;
}

#endif

- (MSIDWebviewResponse *)responseWithURL:(NSURL *)url
                            requestState:(NSString *)requestState
                      ignoreInvalidState:(BOOL)ignoreInvalidState
                                 context:(id<MSIDRequestContext>)context
                                   error:(NSError **)error
{
    // Try to create CBA response
#if AD_BROKER
    MSIDCBAWebAADAuthResponse *cbaResponse = [[MSIDCBAWebAADAuthResponse alloc] initWithURL:url context:context error:nil];
    if (cbaResponse) return cbaResponse;
#endif
    
    // Try to create a WPJ response
    MSIDWebWPJResponse *wpjResponse = [[MSIDWebWPJResponse alloc] initWithURL:url context:context error:nil];
    if (wpjResponse) return wpjResponse;
    
    // Try to create a browser reponse
    MSIDWebOpenBrowserResponse *browserResponse = [[MSIDWebOpenBrowserResponse alloc] initWithURL:url
                                                                                          context:context
                                                                                            error:nil];
    if (browserResponse) return browserResponse;
    
    // Try to acreate AAD Auth response
    MSIDWebAADAuthResponse *response = [[MSIDWebAADAuthResponse alloc] initWithURL:url
                                                                      requestState:requestState
                                                                ignoreInvalidState:ignoreInvalidState
                                                                           context:context
                                                                             error:error];
    
    return response;
}

- (MSIDWebviewConfiguration *)webViewConfigurationWithRequestParameters:(MSIDInteractiveRequestParameters *)parameters
{
    MSIDWebviewConfiguration *configuration = [super webViewConfigurationWithRequestParameters:parameters];

    if (!configuration)
    {
        return nil;
    }

    NSURL *authorizationEndpoint = configuration.authorizationEndpoint;
    NSURL *networkURL = [parameters.authority networkUrlWithContext:parameters];
    
    if (!authorizationEndpoint)
    {
        MSID_LOG_WITH_CTX(MSIDLogLevelError, parameters, @"Nil authorization endpoint provided");
        return nil;
    }

    NSURLComponents *authorizationComponents = [NSURLComponents componentsWithURL:authorizationEndpoint resolvingAgainstBaseURL:NO];
    authorizationComponents.host = networkURL.host;
    configuration.authorizationEndpoint = authorizationComponents.URL;
    
    
    MSIDClaimsRequest *claimsRequest = [MSIDClaimsRequest claimsRequestFromCapabilities:parameters.clientCapabilities
                                                                          claimsRequest:parameters.claimsRequest];
    NSString *claims = [[claimsRequest jsonDictionary] msidJSONSerializeWithContext:parameters];

    configuration.claims = claims;
    configuration.instanceAware = parameters.instanceAware;

    return configuration;
}


@end
