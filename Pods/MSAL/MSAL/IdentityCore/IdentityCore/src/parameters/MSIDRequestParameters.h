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
#import "MSIDRequestContext.h"
#import "MSIDCacheAccessor.h"
#import "MSIDConstants.h"

@class MSIDAuthority;
@class MSIDAccountIdentifier;
@class MSIDOauth2Factory;
@class MSIDTokenResponseValidator;
@class MSIDConfiguration;
@class MSIDClaimsRequest;
@class MSIDAuthenticationScheme;
#if !EXCLUDE_FROM_MSALCPP
@class MSIDCurrentRequestTelemetry;
#endif

@interface MSIDRequestParameters : NSObject <NSCopying, MSIDRequestContext>

@property (nonatomic) MSIDAuthority *authority;
@property (nonatomic) MSIDAuthenticationScheme *authScheme;
/*
 Authority provided by the developer. It could be different from the `authority` property.
 */
@property (nonatomic) MSIDAuthority *providedAuthority;
@property (nonatomic) MSIDAuthority *cloudAuthority;
@property (nonatomic) NSString *redirectUri;
@property (nonatomic) NSString *clientId;
@property (nonatomic) NSString *target;
@property (nonatomic) NSString *oidcScope;
@property (nonatomic) MSIDAccountIdentifier *accountIdentifier;
@property (nonatomic) BOOL validateAuthority;
// Additional body parameters that will be appended to all token requests
@property (nonatomic) NSDictionary *extraTokenRequestParameters;
// Additional URL query parameters that will be added to both token and authorize requests
@property (nonatomic) NSDictionary *extraURLQueryParameters;
@property (nonatomic) NSUInteger tokenExpirationBuffer;
@property (nonatomic) BOOL extendedLifetimeEnabled;
@property (nonatomic) BOOL instanceAware;
@property (nonatomic) NSString *intuneApplicationIdentifier;
@property (nonatomic) MSIDRequestType requestType;
#if !EXCLUDE_FROM_MSALCPP
@property (nonatomic) MSIDCurrentRequestTelemetry *currentRequestTelemetry;
#endif
#pragma mark MSIDRequestContext properties
@property (nonatomic) NSUUID *correlationId;
@property (nonatomic) NSString *logComponent;
@property (nonatomic) NSString *telemetryRequestId;
@property (nonatomic) NSDictionary *appRequestMetadata;
@property (nonatomic) NSString *telemetryApiId;

#pragma mark Conditional access
@property (nonatomic) MSIDClaimsRequest *claimsRequest;
@property (nonatomic) NSArray *clientCapabilities;

#pragma mark Configuration
// TODO: today we have both configuration and request params
// In future we should think about either combining them or reconsiling configuration pieces in configuration to stop duplicating
// This will be done separately
@property (nonatomic) MSIDConfiguration *msidConfiguration;

#pragma mark - Cache
@property (nonatomic) NSString *keychainAccessGroup;

- (NSURL *)tokenEndpoint;

#pragma mark Methods
- (void)setCloudAuthorityWithCloudHostName:(NSString *)cloudHostName;
- (NSString *)allTokenRequestScopes;

- (BOOL)validateParametersWithError:(NSError **)error;

- (void)updateAppRequestMetadata:(NSString *)homeAccountId;

#pragma mark - Init
- (instancetype)initWithAuthority:(MSIDAuthority *)authority
                       authScheme:(MSIDAuthenticationScheme *)authScheme
                      redirectUri:(NSString *)redirectUri
                         clientId:(NSString *)clientId
                           scopes:(NSOrderedSet<NSString *> *)scopes
                       oidcScopes:(NSOrderedSet<NSString *> *)oidScopes
                    correlationId:(NSUUID *)correlationId
                   telemetryApiId:(NSString *)telemetryApiId
              intuneAppIdentifier:(NSString *)intuneApplicationIdentifier
                      requestType:(MSIDRequestType)requestType
                            error:(NSError **)error;

@end
