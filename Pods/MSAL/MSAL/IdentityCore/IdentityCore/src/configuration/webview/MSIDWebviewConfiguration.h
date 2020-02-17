//------------------------------------------------------------------------------
//
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
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.
//
//------------------------------------------------------------------------------

#import <Foundation/Foundation.h>

#if TARGET_OS_IPHONE
#import <UIKit/UIKit.h>
#endif

@class MSIDPkce;

@interface MSIDWebviewConfiguration : NSObject

// Common
@property (readwrite) NSURL *authorizationEndpoint;
@property (readwrite) NSString *redirectUri;
@property (readwrite) NSString *clientId;
@property (readwrite) NSString *resource;
@property (readwrite) NSOrderedSet<NSString *> *scopes;
@property (readwrite) NSUUID *correlationId;

@property (readwrite) NSDictionary<NSString *, NSString *> *extraQueryParameters;
@property (readwrite) NSString *promptBehavior;
@property (readwrite) NSString *claims;
@property (readwrite) BOOL instanceAware;

// Embedded webview
@property (readwrite) NSMutableDictionary<NSString *, NSString *> *customHeaders;

// PKCE Support
@property (readonly) MSIDPkce *pkce;

// State verification
// Set this to YES to have the request continue even at state verification failure.
// Set this to NO if request should stop at state verification failure.
// By default, this is set to NO.
@property (readwrite) BOOL ignoreInvalidState;

// User information
@property (readwrite) NSString *loginHint;
@property (readwrite) NSString *utid;
@property (readwrite) NSString *uid;

// Priority start URL
@property (readwrite) NSURL *explicitStartURL;

#if TARGET_OS_IPHONE
@property (weak) UIViewController *parentController;
@property (readwrite) UIModalPresentationStyle presentationType;
@property (nonatomic) BOOL prefersEphemeralWebBrowserSession;
#endif

- (instancetype)initWithAuthorizationEndpoint:(NSURL *)authorizationEndpoint
                                  redirectUri:(NSString *)redirectUri
                                     clientId:(NSString *)clientId
                                     resource:(NSString *)resource
                                       scopes:(NSOrderedSet<NSString *> *)scopes
                                correlationId:(NSUUID *)correlationId
                                   enablePkce:(BOOL)enablePkce;

@end
