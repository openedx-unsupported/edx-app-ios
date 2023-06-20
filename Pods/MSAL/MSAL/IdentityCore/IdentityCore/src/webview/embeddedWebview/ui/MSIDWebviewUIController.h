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

#if !MSID_EXCLUDE_WEBKIT

#import <Foundation/Foundation.h>
#import <WebKit/WebKit.h>
#import "MSIDWebViewPlatformParams.h"
#import "MSIDWorkPlaceJoinConstants.h"

@interface MSIDWebviewUIController :
#if TARGET_OS_IPHONE
UIViewController
#else
NSWindowController
#endif
{
    BOOL _complete;
}

@property (nonatomic) WKWebView *webView;
@property (nonatomic) id<MSIDRequestContext> context;
@property (nonatomic) BOOL loading;
@property (nonatomic) BOOL complete;
@property (nonatomic, readonly) MSIDWebViewPlatformParams *platformParams;
#if TARGET_OS_IPHONE
@property (nonatomic, weak) UIViewController *parentController;
@property (nonatomic) UIModalPresentationStyle presentationType;
@property (nonatomic, readonly) BOOL presentInParentController;
#endif

+ (WKWebViewConfiguration *)defaultWKWebviewConfiguration;

- (id)initWithContext:(id<MSIDRequestContext>)context;

- (id)initWithContext:(id<MSIDRequestContext>)context
       platformParams:(MSIDWebViewPlatformParams *)platformParams;

- (BOOL)loadView:(NSError **)error;
- (void)presentView;
- (void)dismissWebview:(void (^)(void))completion;
- (void)showLoadingIndicator;
- (void)dismissLoadingIndicator;
- (void)cancel;
- (void)userCancel;

@end

#endif
