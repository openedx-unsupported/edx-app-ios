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
#import "MSIDAuthorizeWebRequestConfiguration.h"
#import "MSIDWebOAuth2AuthCodeResponse.h"
#import "MSIDWebviewSession.h"
#import <WebKit/WebKit.h>
#import "MSIDSystemWebviewController.h"
#import "MSIDPkce.h"
#import "NSOrderedSet+MSIDExtensions.h"
#import "MSIDOAuth2EmbeddedWebviewController.h"
#import "MSIDInteractiveRequestParameters.h"
#import "MSIDAuthority.h"
#import "MSIDAccountIdentifier.h"
#import "MSIDOpenIdProviderMetadata.h"
#import "MSIDPromptType_Internal.h"
#import "MSIDClaimsRequest.h"
#import "MSIDSignoutWebRequestConfiguration.h"
#import "MSIDWebviewInteracting.h"
#import "MSIDSystemWebViewControllerFactory.h"
#import "MSIDInteractiveTokenRequestParameters.h"

@implementation MSIDWebviewFactory

#if !MSID_EXCLUDE_WEBKIT

#pragma mark - Webview creation

- (NSObject<MSIDWebviewInteracting> *)webViewWithConfiguration:(MSIDBaseWebRequestConfiguration *)configuration
                                             requestParameters:(MSIDInteractiveRequestParameters *)requestParameters
                                                       context:(id<MSIDRequestContext>)context
{
        MSIDWebviewType webviewType = [MSIDSystemWebViewControllerFactory availableWebViewTypeWithPreferredType:requestParameters.webviewType];
        
        BOOL useSession = YES;
        BOOL allowSafariViewController = NO;
        
        switch (webviewType)
        {
            case MSIDWebviewTypeWKWebView:
                return [self embeddedWebviewFromConfiguration:configuration
                                                customWebview:requestParameters.customWebview
                                                      context:context];
                
#if !MSID_EXCLUDE_SYSTEMWV
            case MSIDWebviewTypeAuthenticationSession:
                useSession = YES;
                allowSafariViewController = NO;
                break;
#if TARGET_OS_IPHONE
            case MSIDWebviewTypeSafariViewController:
                useSession = NO;
                allowSafariViewController = YES;
                break;
#endif
#endif
                
            default:
                break;
        }
    
    return [self systemWebviewFromConfiguration:configuration
                       useAuthenticationSession:useSession
                      allowSafariViewController:allowSafariViewController
                                        context:context];
}

- (NSObject<MSIDWebviewInteracting> *)embeddedWebviewFromConfiguration:(MSIDBaseWebRequestConfiguration *)configuration
                                                         customWebview:(WKWebView *)webview
                                                               context:(id<MSIDRequestContext>)context
{
    if (![NSThread isMainThread])
    {
        __block NSObject<MSIDWebviewInteracting> *session;
        dispatch_sync(dispatch_get_main_queue(), ^{
            session = [self embeddedWebviewFromConfiguration:configuration customWebview:webview context:context];
        });
        
        return session;
    }
    
    MSIDOAuth2EmbeddedWebviewController *embeddedWebviewController
    = [[MSIDOAuth2EmbeddedWebviewController alloc] initWithStartURL:configuration.startURL
                                                             endURL:[NSURL URLWithString:configuration.endRedirectUrl]
                                                            webview:webview
                                                      customHeaders:configuration.customHeaders
                                                     platfromParams:nil
                                                            context:context];
    
#if TARGET_OS_IPHONE
    embeddedWebviewController.parentController = configuration.parentController;
    embeddedWebviewController.presentationType = configuration.presentationType;
#endif

    return embeddedWebviewController;
}

#endif

#if !MSID_EXCLUDE_SYSTEMWV

- (NSObject<MSIDWebviewInteracting> *)systemWebviewFromConfiguration:(MSIDBaseWebRequestConfiguration *)configuration
                                            useAuthenticationSession:(BOOL)useAuthenticationSession
                                           allowSafariViewController:(BOOL)allowSafariViewController
                                                             context:(id<MSIDRequestContext>)context
{
    if (![NSThread isMainThread])
    {
        __block NSObject<MSIDWebviewInteracting> *session;
        dispatch_sync(dispatch_get_main_queue(), ^{
            session = [self systemWebviewFromConfiguration:configuration
                                  useAuthenticationSession:useAuthenticationSession
                                 allowSafariViewController:allowSafariViewController
                                                          context:context];
        });
        
        return session;
    }
    
    MSIDSystemWebviewController *systemWVC = [[MSIDSystemWebviewController alloc] initWithStartURL:configuration.startURL
                                                                                       redirectURI:configuration.endRedirectUrl
                                                                                  parentController:configuration.parentController
                                                                          useAuthenticationSession:useAuthenticationSession
                                                                         allowSafariViewController:allowSafariViewController
                                                                        ephemeralWebBrowserSession:configuration.prefersEphemeralWebBrowserSession
                                                                                           context:context];
    
#if TARGET_OS_IPHONE
    systemWVC.presentationType = configuration.presentationType;
#endif
    
    return systemWVC;
}
#endif

#pragma mark - Webview helpers

- (NSMutableDictionary<NSString *, NSString *> *)authorizationParametersFromRequestParameters:(MSIDInteractiveTokenRequestParameters *)parameters
                                                                                         pkce:(MSIDPkce *)pkce
                                                                                 requestState:(NSString *)state
{
    NSMutableDictionary<NSString *, NSString *> *result = [NSMutableDictionary new];

    result[MSID_OAUTH2_SCOPE] = parameters.allAuthorizeRequestScopes.msidToString;
    result[MSID_OAUTH2_CLIENT_ID] = parameters.clientId;
    result[MSID_OAUTH2_RESPONSE_TYPE] = MSID_OAUTH2_CODE;
    result[MSID_OAUTH2_REDIRECT_URI] = parameters.redirectUri;
    result[MSID_OAUTH2_LOGIN_HINT] = parameters.accountIdentifier.displayableId ?: parameters.loginHint;
    
    // Extra query params
    __auto_type allAuthorizeRequestExtraParameters = [parameters allAuthorizeRequestExtraParametersWithMetadata:YES];
    if (allAuthorizeRequestExtraParameters)
    {
        [result addEntriesFromDictionary:allAuthorizeRequestExtraParameters];
    }
    
    // PKCE
    if (pkce)
    {
        result[MSID_OAUTH2_CODE_CHALLENGE] = pkce.codeChallenge;
        result[MSID_OAUTH2_CODE_CHALLENGE_METHOD] = pkce.codeChallengeMethod;
    }

    // State
    result[MSID_OAUTH2_STATE] = state.msidBase64UrlEncode;
    
    NSString *claims = [[parameters.claimsRequest jsonDictionary] msidJSONSerializeWithContext:parameters];
    if (claims) result[MSID_OAUTH2_CLAIMS] = claims;
    
    NSString *promptParam = MSIDPromptParamFromType(parameters.promptType);
    if (![NSString msidIsStringNilOrBlank:promptParam]) result[MSID_OAUTH2_PROMPT] = promptParam;
    
    [result addEntriesFromDictionary:[self metadataFromRequestParameters:parameters]];
    
    return result;
}

- (NSMutableDictionary<NSString *, NSString *> *)logoutParametersFromRequestParameters:(MSIDInteractiveRequestParameters *)parameters
                                                                          requestState:(NSString *)state
{
    NSMutableDictionary<NSString *, NSString *> *result = [NSMutableDictionary new];
    result[MSID_OAUTH2_SIGNOUT_REDIRECT_URI] = parameters.redirectUri;
    result[MSID_OAUTH2_STATE] = state.msidBase64UrlEncode;
    [result addEntriesFromDictionary:[self metadataFromRequestParameters:parameters]];
    [result addEntriesFromDictionary:parameters.appRequestMetadata];
    return result;
}

- (NSDictionary<NSString *, NSString *> *)metadataFromRequestParameters:(__unused MSIDInteractiveRequestParameters *)parameters
{
    return nil;
}

#pragma mark - Webview response parsing
- (MSIDWebviewResponse *)oAuthResponseWithURL:(NSURL *)url
                            requestState:(NSString *)requestState
                      ignoreInvalidState:(BOOL)ignoreInvalidState
                                 context:(id<MSIDRequestContext>)context
                                   error:(NSError **)error
{
    //  return base response
    NSError *responseCreationError = nil;
    MSIDWebOAuth2AuthCodeResponse *response = [[MSIDWebOAuth2AuthCodeResponse alloc] initWithURL:url
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

- (MSIDAuthorizeWebRequestConfiguration *)authorizeWebRequestConfigurationWithRequestParameters:(MSIDInteractiveTokenRequestParameters *)parameters
{
    NSURL *authorizeEndpoint = parameters.authority.metadata.authorizationEndpoint;
    
    if (!parameters || !authorizeEndpoint)
    {
        return nil;
    }
    
    MSIDPkce *pkce = parameters.enablePkce ? [MSIDPkce new] : nil;
        
    NSString *oauthState = [self generateStateValue];
    NSDictionary *authorizeQuery = [self authorizationParametersFromRequestParameters:parameters pkce:pkce requestState:oauthState];
    NSURL *startURL = [self startURLWithEndpoint:authorizeEndpoint authority:parameters.authority query:authorizeQuery context:parameters];
    
    MSIDAuthorizeWebRequestConfiguration *configuration = [[MSIDAuthorizeWebRequestConfiguration alloc] initWithStartURL:startURL
                                                                                  endRedirectUri:parameters.redirectUri
                                                                                            pkce:pkce
                                                                                           state:oauthState
                                                                              ignoreInvalidState:NO];
    configuration.customHeaders = parameters.customWebviewHeaders;
    configuration.parentController = parameters.parentViewController;
    configuration.prefersEphemeralWebBrowserSession = parameters.prefersEphemeralWebBrowserSession;
    
#if TARGET_OS_IPHONE
    configuration.presentationType = parameters.presentationType;
#endif

    return configuration;
}

- (MSIDSignoutWebRequestConfiguration *)logoutWebRequestConfigurationWithRequestParameters:(MSIDInteractiveRequestParameters *)parameters
{
    NSURL *logoutEndpoint = parameters.authority.metadata.endSessionEndpoint;
    
    if (!parameters || !logoutEndpoint)
    {
        return nil;
    }
    
    NSString *oauthState = [self generateStateValue];
    NSDictionary *logoutQuery = [self logoutParametersFromRequestParameters:parameters requestState:oauthState];
    NSURL *startURL = [self startURLWithEndpoint:logoutEndpoint authority:parameters.authority query:logoutQuery context:parameters];
    
    MSIDSignoutWebRequestConfiguration *configuration = [[MSIDSignoutWebRequestConfiguration alloc] initWithStartURL:startURL
                                                                                                      endRedirectUri:parameters.redirectUri
                                                                                                               state:oauthState
                                                                                                  ignoreInvalidState:NO];
    
    configuration.customHeaders = parameters.customWebviewHeaders;
    configuration.parentController = parameters.parentViewController;
    configuration.prefersEphemeralWebBrowserSession = parameters.prefersEphemeralWebBrowserSession;
    
#if TARGET_OS_IPHONE
    configuration.presentationType = parameters.presentationType;
#endif
    
    return configuration;
}

#pragma mark - Helpers

- (NSURL *)startURLWithEndpoint:(NSURL *)endpoint
                      authority:(MSIDAuthority *)authority
                          query:(NSDictionary *)query
                        context:(id<MSIDRequestContext>)context
{
    if (!endpoint) return nil;
    
    NSURLComponents *urlComponents = [NSURLComponents componentsWithURL:endpoint resolvingAgainstBaseURL:NO];

    urlComponents.percentEncodedQuery = [query msidURLEncode];
    
    NSURL *networkURL = [authority networkUrlWithContext:context];
    if (networkURL) urlComponents.host = networkURL.host;
    
    return urlComponents.URL;
}

@end
