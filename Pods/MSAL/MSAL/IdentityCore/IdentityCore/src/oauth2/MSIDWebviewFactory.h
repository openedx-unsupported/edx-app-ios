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

#import <Foundation/Foundation.h>

@protocol MSIDRequestContext;
@class MSIDAuthorizeWebRequestConfiguration;
@class MSIDWebviewResponse;
@class MSIDWebviewSession;
@class WKWebView;
@class MSIDInteractiveRequestParameters;
@protocol MSIDWebviewInteracting;
@class MSIDSignoutWebRequestConfiguration;
@class MSIDBaseWebRequestConfiguration;
@class MSIDPkce;
@class MSIDInteractiveTokenRequestParameters;

@interface MSIDWebviewFactory : NSObject

#if !MSID_EXCLUDE_WEBKIT

- (NSObject<MSIDWebviewInteracting> *)webViewWithConfiguration:(MSIDBaseWebRequestConfiguration *)configuration
                                             requestParameters:(MSIDInteractiveRequestParameters *)requestParameters
                                                       context:(id<MSIDRequestContext>)context;

- (NSObject<MSIDWebviewInteracting> *)embeddedWebviewFromConfiguration:(MSIDBaseWebRequestConfiguration *)configuration
                                                         customWebview:(WKWebView *)webview
                                                               context:(id<MSIDRequestContext>)context;

#endif

#if !MSID_EXCLUDE_SYSTEMWV
- (NSObject<MSIDWebviewInteracting> *)systemWebviewFromConfiguration:(MSIDBaseWebRequestConfiguration *)configuration
                                            useAuthenticationSession:(BOOL)useAuthenticationSession
                                           allowSafariViewController:(BOOL)allowSafariViewController
                                                             context:(id<MSIDRequestContext>)context;
#endif

// Webview related
- (NSMutableDictionary<NSString *, NSString *> *)authorizationParametersFromRequestParameters:(MSIDInteractiveTokenRequestParameters *)parameters
                                                                                         pkce:(MSIDPkce *)pkce
                                                                                 requestState:(NSString *)state;

- (NSMutableDictionary<NSString *, NSString *> *)logoutParametersFromRequestParameters:(MSIDInteractiveRequestParameters *)parameters
                                                                          requestState:(NSString *)state;

- (NSDictionary<NSString *, NSString *> *)metadataFromRequestParameters:(MSIDInteractiveRequestParameters *)parameters;

// Create a corresponding response from URL.
//   If this different per authorization setup (i.e./ v1 vs v2), implement it in subclasses.
- (MSIDWebviewResponse *)oAuthResponseWithURL:(NSURL *)url
                                 requestState:(NSString *)requestState
                           ignoreInvalidState:(BOOL)ignoreInvalidState
                                      context:(id<MSIDRequestContext>)context
                                        error:(NSError **)error;

// Helper for generating state for state verification
- (NSString *)generateStateValue;

- (MSIDAuthorizeWebRequestConfiguration *)authorizeWebRequestConfigurationWithRequestParameters:(MSIDInteractiveTokenRequestParameters *)parameters;

- (MSIDSignoutWebRequestConfiguration *)logoutWebRequestConfigurationWithRequestParameters:(MSIDInteractiveRequestParameters *)parameters;

@end
