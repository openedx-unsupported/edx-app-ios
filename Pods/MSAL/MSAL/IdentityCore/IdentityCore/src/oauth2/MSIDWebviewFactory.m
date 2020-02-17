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

#import "MSIDWebviewFactory.h"
#import "MSIDWebviewConfiguration.h"
#import "MSIDWebOAuth2Response.h"
#import "MSIDWebviewSession.h"
#import <WebKit/WebKit.h>
#if TARGET_OS_IPHONE
#import "MSIDSystemWebviewController.h"
#endif
#import "MSIDPkce.h"
#import "NSOrderedSet+MSIDExtensions.h"
#import "MSIDOAuth2EmbeddedWebviewController.h"
#import "MSIDInteractiveRequestParameters.h"
#import "MSIDAuthority.h"
#import "MSIDAccountIdentifier.h"
#import "MSIDOpenIdProviderMetadata.h"
#import "MSIDPromptType_Internal.h"
#import "MSIDClaimsRequest.h"

@implementation MSIDWebviewFactory

#if !MSID_EXCLUDE_WEBKIT

#pragma mark - Webview creation

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
    
    MSIDOAuth2EmbeddedWebviewController *embeddedWebviewController
    = [[MSIDOAuth2EmbeddedWebviewController alloc] initWithStartURL:startURL
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

#if TARGET_OS_IPHONE && !MSID_EXCLUDE_SYSTEMWV

- (MSIDWebviewSession *)systemWebviewSessionFromConfiguration:(MSIDWebviewConfiguration *)configuration
                                     useAuthenticationSession:(BOOL)useAuthenticationSession
                                    allowSafariViewController:(BOOL)allowSafariViewController
                                                      context:(id<MSIDRequestContext>)context
{
    if (![NSThread isMainThread])
    {
        __block MSIDWebviewSession *session;
        dispatch_sync(dispatch_get_main_queue(), ^{
            session = [self systemWebviewSessionFromConfiguration:configuration
                                         useAuthenticationSession:useAuthenticationSession
                                        allowSafariViewController:allowSafariViewController
                                                          context:context];
        });
        
        return session;
    }
    
    NSString *state = [self generateStateValue];
    NSURL *startURL = [self startURLFromConfiguration:configuration requestState:state];
    MSIDSystemWebviewController *systemWVC = [[MSIDSystemWebviewController alloc] initWithStartURL:startURL
                                                                                       redirectURI:configuration.redirectUri
                                                                                  parentController:configuration.parentController
                                                                                  presentationType:configuration.presentationType
                                                                          useAuthenticationSession:useAuthenticationSession
                                                                         allowSafariViewController:allowSafariViewController
                                                                        ephemeralWebBrowserSession:configuration.prefersEphemeralWebBrowserSession
                                                                                           context:context];
    
    MSIDWebviewSession *session = [[MSIDWebviewSession alloc] initWithWebviewController:systemWVC
                                                                                factory:self
                                                                           requestState:state
                                                                     ignoreInvalidState:configuration.ignoreInvalidState];
    return session;
}
#endif

#pragma mark - Webview helpers

- (NSMutableDictionary<NSString *, NSString *> *)authorizationParametersFromConfiguration:(MSIDWebviewConfiguration *)configuration
                                                                             requestState:(NSString *)state
{
    NSMutableDictionary<NSString *, NSString *> *parameters = [NSMutableDictionary new];

    parameters[MSID_OAUTH2_SCOPE] = configuration.scopes.msidToString;
    parameters[MSID_OAUTH2_CLIENT_ID] = configuration.clientId;
    parameters[MSID_OAUTH2_RESPONSE_TYPE] = MSID_OAUTH2_CODE;
    parameters[MSID_OAUTH2_REDIRECT_URI] = configuration.redirectUri;
    parameters[MSID_OAUTH2_LOGIN_HINT] = configuration.loginHint;
    
    // Extra query params
    if (configuration.extraQueryParameters)
    {
        [parameters addEntriesFromDictionary:configuration.extraQueryParameters];
    }
    
    // PKCE
    if (configuration.pkce)
    {
        parameters[MSID_OAUTH2_CODE_CHALLENGE] = configuration.pkce.codeChallenge;
        parameters[MSID_OAUTH2_CODE_CHALLENGE_METHOD] = configuration.pkce.codeChallengeMethod;
    }

    // State
    parameters[MSID_OAUTH2_STATE] = state.msidBase64UrlEncode;
    
    return parameters;
}

- (NSURL *)startURLFromConfiguration:(MSIDWebviewConfiguration *)configuration requestState:(NSString *)state
{
    if (!configuration) return nil;
    if (configuration.explicitStartURL) return configuration.explicitStartURL;
    
    if (!configuration.authorizationEndpoint) return nil;
    
    NSURLComponents *urlComponents = [NSURLComponents componentsWithURL:configuration.authorizationEndpoint resolvingAgainstBaseURL:NO];
    NSDictionary *parameters = [self authorizationParametersFromConfiguration:configuration requestState:state];
    
    urlComponents.percentEncodedQuery = [parameters msidURLEncode];
    
    return urlComponents.URL;
}

#pragma mark - Webview response parsing
- (MSIDWebviewResponse *)responseWithURL:(NSURL *)url
                            requestState:(NSString *)requestState
                      ignoreInvalidState:(BOOL)ignoreInvalidState
                                 context:(id<MSIDRequestContext>)context
                                   error:(NSError **)error
{
    //  return base response
    NSError *responseCreationError = nil;
    MSIDWebOAuth2Response *response = [[MSIDWebOAuth2Response alloc] initWithURL:url
                                                                    requestState:requestState
                                                              ignoreInvalidState:ignoreInvalidState
                                                                         context:context
                                                                           error:&responseCreationError];
    if (responseCreationError)
    {
        if (error)  *error = responseCreationError;
        return nil;
    }
    
    return response;
}

- (NSString *)generateStateValue
{
    return [[NSUUID UUID] UUIDString];
}

- (MSIDWebviewConfiguration *)webViewConfigurationWithRequestParameters:(MSIDInteractiveRequestParameters *)parameters
{
    MSIDWebviewConfiguration *configuration = [[MSIDWebviewConfiguration alloc] initWithAuthorizationEndpoint:parameters.authority.metadata.authorizationEndpoint
                                                                                                  redirectUri:parameters.redirectUri
                                                                                                     clientId:parameters.clientId resource:nil
                                                                                                       scopes:parameters.allAuthorizeRequestScopes
                                                                                                correlationId:parameters.correlationId
                                                                                                   enablePkce:parameters.enablePkce];

    NSString *promptParam = MSIDPromptParamFromType(parameters.promptType);
    configuration.promptBehavior = promptParam;
    configuration.loginHint = parameters.accountIdentifier.displayableId ?: parameters.loginHint;
    configuration.extraQueryParameters = parameters.allAuthorizeRequestExtraParameters;
    configuration.customHeaders = parameters.customWebviewHeaders;
#if TARGET_OS_IPHONE
    configuration.parentController = parameters.parentViewController;
    configuration.presentationType = parameters.presentationType;
    if (@available(iOS 13.0, *))
    {
        configuration.prefersEphemeralWebBrowserSession = parameters.prefersEphemeralWebBrowserSession;
    }
#endif

    NSString *claims = [[parameters.claimsRequest jsonDictionary] msidJSONSerializeWithContext:parameters];

    if (![NSString msidIsStringNilOrBlank:claims])
    {
        configuration.claims = claims;
    }

    return configuration;
}

@end
