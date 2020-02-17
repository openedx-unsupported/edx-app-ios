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
#if TARGET_OS_IPHONE && !MSID_EXCLUDE_SYSTEMWV

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "MSIDSystemWebviewController.h"
#import "MSIDURLResponseHandling.h"

@interface MSIDAuthenticationSession : NSObject<MSIDWebviewInteracting, MSIDURLResponseHandling>

- (instancetype)initWithURL:(NSURL *)url
          callbackURLScheme:(NSString *)callbackURLScheme
                    context:(id<MSIDRequestContext>)context;

- (instancetype)initWithURL:(NSURL *)url
          callbackURLScheme:(NSString *)callbackURLScheme
           parentController:(UIViewController *)parentController
 ephemeralWebBrowserSession:(BOOL)prefersEphemeralWebBrowserSession
                    context:(id<MSIDRequestContext>)context API_AVAILABLE(ios(13.0));

@property (readonly) NSURL *startURL;
@property (readonly) NSURL *redirectURL;

@property (weak, nonatomic, readonly) UIViewController *parentController API_AVAILABLE(ios(13.0));
@property (nonatomic) BOOL prefersEphemeralWebBrowserSession API_AVAILABLE(ios(13.0));

@end
#endif
