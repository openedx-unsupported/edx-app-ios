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

#import "MSIDRequestParameters.h"
#import "MSIDConstants.h"
#import "MSIDBrokerInvocationOptions.h"

@class WKWebView;
#if TARGET_OS_IPHONE
@class UIViewController;
#endif

@interface MSIDInteractiveRequestParameters : MSIDRequestParameters

@property (nonatomic) MSIDInteractiveRequestType requestType;
@property (nonatomic) MSIDUIBehaviorType uiBehaviorType;
@property (nonatomic) NSString *loginHint;
@property (nonatomic) MSIDWebviewType webviewType;
@property (nonatomic) WKWebView *customWebview;
@property (readwrite) NSMutableDictionary<NSString *, NSString *> *customWebviewHeaders;
@property (readwrite, nonatomic) BOOL shouldValidateResultAccount;
#if TARGET_OS_IPHONE
@property (nonatomic) UIViewController *parentViewController;
@property (nonatomic) UIModalPresentationStyle presentationType;
@property (nonatomic) BOOL prefersEphemeralWebBrowserSession API_AVAILABLE(ios(13.0));
#endif
@property (nonatomic) NSString *extraScopesToConsent;
@property (nonatomic) MSIDPromptType promptType;
// Additional request parameters that will only be appended to authorize requests in addition to extraURLQueryParameters from parent class
@property (nonatomic) NSDictionary *extraAuthorizeURLQueryParameters;
@property (nonatomic) NSString *telemetryWebviewType;
@property (nonatomic) MSIDBrokerInvocationOptions *brokerInvocationOptions;
@property (nonatomic) BOOL enablePkce;

- (NSOrderedSet *)allAuthorizeRequestScopes;
- (NSDictionary *)allAuthorizeRequestExtraParameters;

// Initialize parameters with extra scopes, and interactive request type
- (instancetype)initWithAuthority:(MSIDAuthority *)authority
                      redirectUri:(NSString *)redirectUri
                         clientId:(NSString *)clientId
                           scopes:(NSOrderedSet<NSString *> *)scopes
                       oidcScopes:(NSOrderedSet<NSString *> *)oidScopes
             extraScopesToConsent:(NSOrderedSet<NSString *> *)extraScopesToConsent
                    correlationId:(NSUUID *)correlationId
                   telemetryApiId:(NSString *)telemetryApiId
                    brokerOptions:(MSIDBrokerInvocationOptions *)brokerOptions
                      requestType:(MSIDInteractiveRequestType)requestType
              intuneAppIdentifier:(NSString *)intuneApplicationIdentifier
                            error:(NSError **)error;

@end
