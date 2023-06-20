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

#import "MSIDJsonSerializable.h"
#import "MSIDIdTokenClaims.h"
#import "MSIDAccountType.h"
#import "MSIDConfiguration.h"
#import "MSIDError.h"
#import "MSIDProviderType.h"

@protocol MSIDRefreshableToken;
@class MSIDBaseToken;

@interface MSIDTokenResponse : NSObject <MSIDJsonSerializable>

// Default properties for an openid error response
@property (nonatomic, nullable) NSString *error;
@property (nonatomic, nullable) NSString *errorDescription;
// Default properties for a successful openid response
@property (nonatomic) NSInteger expiresIn;
/*!
 expiresOn isn't part of the spec, but we use it when we need to serialize/deserialize token reponse to/from JSON,
 because it contains more precise time then expiresIn.
 */
@property (nonatomic) NSInteger expiresOn;
@property (nonatomic, nullable) NSString *accessToken;
// In AT Pop scenario, we need to pass back the tokenType and kid(req_conf)
@property (nonatomic, nullable) NSString *tokenType;
@property (nonatomic, nullable) NSString *requestConf;

@property (nonatomic, nullable) NSString *refreshToken;
@property (nonatomic, nullable) NSString *scope;
@property (nonatomic, nullable) NSString *state;
@property (nonatomic, nullable) NSString *idToken;
// Additional properties that server sends
@property (nonatomic, nullable) NSDictionary *additionalServerInfo;

// When SSO extension creates token response, this property will contain authenticator app version.
@property (nonatomic, nullable) NSString *clientAppVersion;

/* Derived properties */

// Error code based on oauth error response
@property (nonatomic, readonly) MSIDErrorCode oauthErrorCode;

// NSDate derived from expiresIn property and time received
@property (nonatomic, readonly, nullable) NSDate *expiryDate;

// Specifies if token in the token response is multi resource
@property (nonatomic, readonly) BOOL isMultiResource;

// Wrapper object around ID token
@property (nonatomic, readonly, nullable) MSIDIdTokenClaims *idTokenObj;

// Generic target of the access token, scope for base token response, resource for AAD v1
@property (nonatomic, readonly, nullable) NSString *target;

// Account type for an account generated from this response
@property (nonatomic, readonly) MSIDAccountType accountType;

@property (nonatomic, class, readonly) MSIDProviderType providerType;

- (nullable instancetype)initWithJSONDictionary:(nonnull NSDictionary *)json
                                   refreshToken:(nullable MSIDBaseToken<MSIDRefreshableToken> *)token
                                          error:(NSError * _Nullable __autoreleasing *_Nullable)error;

@end
