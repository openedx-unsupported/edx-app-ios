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
#import "MSIDOIDCSignoutRequest.h"

#if MSID_ENABLE_SSO_EXTENSION

NS_ASSUME_NONNULL_BEGIN

API_AVAILABLE(ios(13.0), macos(10.15))
@interface MSIDSSOExtensionSignoutRequest : MSIDOIDCSignoutRequest

@property (nonatomic, readonly) BOOL shouldSignoutFromBrowser;
@property (nonatomic, readonly) BOOL clearSSOExtensionCookies;
@property (nonatomic, readonly) BOOL shouldWipeAccount;

- (nullable instancetype)initWithRequestParameters:(MSIDInteractiveRequestParameters *)parameters
                          shouldSignoutFromBrowser:(BOOL)shouldSignoutFromBrowser
                                 shouldWipeAccount:(BOOL)shouldWipeAccount
                          clearSSOExtensionCookies:(BOOL)clearSSOExtensionCookies
                     shouldWipeCacheForAllAccounts:(BOOL)shouldWipeCacheForAllAccounts
                                      oauthFactory:(MSIDOauth2Factory *)oauthFactory;

@end

NS_ASSUME_NONNULL_END
#endif
