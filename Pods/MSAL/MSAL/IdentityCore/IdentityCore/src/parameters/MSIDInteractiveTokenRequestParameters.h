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

#import "MSIDInteractiveRequestParameters.h"

NS_ASSUME_NONNULL_BEGIN

@interface MSIDInteractiveTokenRequestParameters : MSIDInteractiveRequestParameters

@property (nonatomic) MSIDUIBehaviorType uiBehaviorType;
@property (nonatomic) NSString *loginHint;
@property (nonatomic) NSString *extraScopesToConsent;
@property (nonatomic) MSIDPromptType promptType;
@property (nonatomic) BOOL shouldValidateResultAccount;
// Additional request parameters that will only be appended to authorize requests in addition to extraURLQueryParameters from parent class
@property (nonatomic) NSDictionary *extraAuthorizeURLQueryParameters;
@property (nonatomic) BOOL enablePkce;
@property (nonatomic) MSIDBrokerInvocationOptions *brokerInvocationOptions;

- (NSOrderedSet *)allAuthorizeRequestScopes;
- (NSDictionary *)allAuthorizeRequestExtraParameters DEPRECATED_MSG_ATTRIBUTE("Use -allAuthorizeRequestExtraParametersWithMetadata: instead");
- (NSDictionary *)allAuthorizeRequestExtraParametersWithMetadata:(BOOL)includeMetadata;

// Initialize parameters with extra scopes, and interactive request type
- (instancetype)initWithAuthority:(MSIDAuthority *)authority
                       authScheme:(MSIDAuthenticationScheme *)authScheme
                      redirectUri:(NSString *)redirectUri
                         clientId:(NSString *)clientId
                           scopes:(nullable NSOrderedSet<NSString *> *)scopes
                       oidcScopes:(nullable NSOrderedSet<NSString *> *)oidScopes
             extraScopesToConsent:(nullable NSOrderedSet<NSString *> *)extraScopesToConsent
                    correlationId:(nullable NSUUID *)correlationId
                   telemetryApiId:(nullable NSString *)telemetryApiId
                    brokerOptions:(nullable MSIDBrokerInvocationOptions *)brokerOptions
                      requestType:(MSIDRequestType)requestType
              intuneAppIdentifier:(nullable NSString *)intuneApplicationIdentifier
                            error:(NSError * _Nullable * _Nullable)error;

@end

NS_ASSUME_NONNULL_END
