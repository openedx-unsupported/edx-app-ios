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
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.  

#import "MSIDSSOExtensionGetDataBaseRequest.h"

#if MSID_ENABLE_SSO_EXTENSION

@class MSIDRequestParameters;
@class MSIDAccountIdentifier;

NS_ASSUME_NONNULL_BEGIN

API_AVAILABLE(ios(13.0), macos(10.15))
@interface MSIDSSOExtensionGetSsoCookiesRequest: MSIDSSOExtensionGetDataBaseRequest

@property (nonatomic, readonly) MSIDAccountIdentifier *accountIdentifier;
@property (nonatomic, readonly) NSString *ssoUrl;
@property (nonatomic, readonly) NSUUID *correlationId;
@property (nonatomic, readonly) NSString *types;

/**
 This is to init get sso cookies request
 @param requestParameters the MSIDRequestParameters
 @param headerTypes an array of type of header the request is looking for, please refers to MSIDHeaderType
 @param accountIdentifier MSIDAccountIdentifier, it is optional
 @param ssoUrl NSString, this is required, and will be used to filter out Prts
 @param correlationId NSUUID, Passed from upper layer for end to end trace
 @param error NSErrorr possible errors during the request
 @returns instance of MSIDSSOExtensionGetSsoCookiesRequest
 */
- (nullable instancetype)initWithRequestParameters:(MSIDRequestParameters *)requestParameters
                                       headerTypes:(NSArray<NSNumber *>*)headerTypes
                                 accountIdentifier:(nullable MSIDAccountIdentifier *)accountIdentifier
                                            ssoUrl:(NSString *)ssoUrl
                                     correlationId:(nullable NSUUID *)correlationId
                                             error:(NSError * _Nullable * _Nullable)error;

- (void)executeRequestWithCompletion:(nonnull MSIDGetSsoCookiesRequestCompletionBlock)completionBlock;

@end

NS_ASSUME_NONNULL_END
#endif
