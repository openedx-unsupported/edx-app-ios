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

#import "MSIDJsonObject.h"
#import "MSIDIdTokenClaims.h"
#import "MSIDAccountType.h"
#import "MSIDConfiguration.h"
#import "MSIDError.h"

@protocol MSIDRefreshableToken;
@class MSIDBaseToken;

@interface MSIDTokenResponse : MSIDJsonObject

// Default properties for an openid error response
@property (readonly) NSString *error;
@property (readonly) NSString *errorDescription;

// Default properties for a successful openid response
@property (readonly) NSInteger expiresIn;
@property (readonly) NSString *accessToken;
@property (readonly) NSString *tokenType;
@property (readonly) NSString *refreshToken;
@property (readonly) NSString *scope;
@property (readonly) NSString *state;
@property (readonly) NSString *idToken;

/* Derived properties */

// Error code based on oauth error response
@property (readonly) MSIDErrorCode oauthErrorCode;

// NSDate derived from expiresIn property and time received
@property (readonly) NSDate *expiryDate;

// Specifies if token in the token response is multi resource
@property (readonly) BOOL isMultiResource;

// Wrapper object around ID token
@property (readonly) MSIDIdTokenClaims *idTokenObj;

// Generic target of the access token, scope for base token response, resource for AAD v1
@property (readonly) NSString *target;

// Account type for an account generated from this response
@property (readonly) MSIDAccountType accountType;

// Additional properties that server sends
@property (readonly) NSDictionary *additionalServerInfo;

- (instancetype)initWithJSONDictionary:(NSDictionary *)json
                          refreshToken:(MSIDBaseToken<MSIDRefreshableToken> *)token
                                 error:(NSError * __autoreleasing *)error;

@end
