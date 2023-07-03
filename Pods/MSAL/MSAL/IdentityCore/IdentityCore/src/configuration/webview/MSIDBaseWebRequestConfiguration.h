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
#import "MSIDConstants.h"

#if TARGET_OS_IPHONE
#import <UIKit/UIKit.h>
#endif

NS_ASSUME_NONNULL_BEGIN

@class MSIDWebviewResponse;
@class MSIDWebviewFactory;

@interface MSIDBaseWebRequestConfiguration : NSObject

@property (nonatomic) NSURL *startURL;
@property (nonatomic) NSString *endRedirectUrl;

// Embedded webview
@property (nonatomic, readwrite) NSDictionary<NSString *, NSString *> *customHeaders;

@property (nonatomic, weak) MSIDViewController *parentController;
@property (nonatomic) BOOL prefersEphemeralWebBrowserSession;

#if TARGET_OS_IPHONE
@property (nonatomic, readwrite) UIModalPresentationStyle presentationType;
#endif

@property (nonatomic, readonly) NSString *state;

// State verification
// Set this to YES to have the request continue even at state verification failure.
// Set this to NO if request should stop at state verification failure.
// By default, this is set to NO.
@property (nonatomic, readonly) BOOL ignoreInvalidState;

- (instancetype)initWithStartURL:(NSURL *)startURL
                  endRedirectUri:(NSString *)endRedirectUri
                           state:(NSString *)state
              ignoreInvalidState:(BOOL)ignoreInvalidState;


- (nullable MSIDWebviewResponse *)responseWithResultURL:(NSURL *)url
                                                factory:(MSIDWebviewFactory *)factory
                                                context:(nullable id<MSIDRequestContext>)context
                                                  error:(NSError * _Nullable * _Nullable)error;

@end

NS_ASSUME_NONNULL_END
