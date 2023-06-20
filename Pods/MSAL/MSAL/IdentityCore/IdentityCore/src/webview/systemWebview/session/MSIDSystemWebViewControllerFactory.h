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
#import "MSIDWebviewInteracting.h"
#import "MSIDConstants.h"

#if !MSID_EXCLUDE_WEBKIT

NS_ASSUME_NONNULL_BEGIN

@interface MSIDSystemWebViewControllerFactory : NSObject

+ (MSIDWebviewType)availableWebViewTypeWithPreferredType:(MSIDWebviewType)preferredType;

+ (nullable id<MSIDWebviewInteracting>)authSessionWithParentController:(MSIDViewController *)parentController
                                                              startURL:(NSURL *)startURL
                                                        callbackScheme:(NSString *)callbackURLScheme
                                                    useEmpheralSession:(BOOL)useEmpheralSession
                                                               context:(id<MSIDRequestContext>)context;

#if TARGET_OS_IPHONE

+ (id<MSIDWebviewInteracting>)systemWebviewControllerWithParentController:(MSIDViewController *)parentController
                                                                 startURL:(NSURL *)startURL
                                                           callbackScheme:(NSString *)callbackURLScheme
                                                       useEmpheralSession:(BOOL)useEmpheralSession
                                                         presentationType:(UIModalPresentationStyle)presentationType
                                                                  context:(id<MSIDRequestContext>)context;

#endif

@end

NS_ASSUME_NONNULL_END

#endif
