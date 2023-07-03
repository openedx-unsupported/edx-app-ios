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
#import "MSIDBaseRequestController.h"
#import "MSIDTokenRequestProviding.h"
#import "MSIDRequestControlling.h"

@class MSIDInteractiveTokenRequestParameters;
@class MSIDBrokerResponseHandler;
@class MSIDBrokerInvocationOptions;

@interface MSIDBrokerInteractiveController : MSIDBaseRequestController <MSIDRequestControlling>

@property (class, strong, readonly, nullable) MSIDBrokerInteractiveController *currentBrokerController;
@property (nonatomic, nullable) NSArray<NSString *> *sdkBrokerCapabilities;
@property (nonatomic, readonly, nullable) MSIDInteractiveTokenRequestParameters *interactiveParameters;

- (nullable instancetype)initWithInteractiveRequestParameters:(nonnull MSIDInteractiveTokenRequestParameters *)parameters
                                         tokenRequestProvider:(nonnull id<MSIDTokenRequestProviding>)tokenRequestProvider
                                           fallbackController:(nullable id<MSIDRequestControlling>)fallbackController
                                                        error:(NSError * _Nullable * _Nullable)error;

- (nullable instancetype)initWithInteractiveRequestParameters:(nonnull MSIDInteractiveTokenRequestParameters *)parameters
                                         tokenRequestProvider:(nonnull id<MSIDTokenRequestProviding>)tokenRequestProvider
                                            brokerInstallLink:(nonnull NSURL *)brokerInstallLink
                                                        error:(NSError * _Nullable * _Nullable)error;

+ (BOOL)completeAcquireToken:(nullable NSURL *)resultURL
           sourceApplication:(nullable NSString *)sourceApplication
       brokerResponseHandler:(nonnull MSIDBrokerResponseHandler *)responseHandler;

+ (BOOL)canPerformRequest:(nonnull MSIDInteractiveTokenRequestParameters *)requestParameters;

@end
