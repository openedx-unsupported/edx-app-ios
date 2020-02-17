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
#import "MSIDWebviewConfiguration.h"
#import "MSIDOauth2Factory.h"
#import "MSIDWebOAuth2Response.h"
#import "MSIDWebviewSession.h"
#import "MSIDAADV1Oauth2Factory.h"
#import "MSIDAADV2Oauth2Factory.h"

@class WKWebView;

typedef void (^MSIDWebviewAuthCompletionHandler)(MSIDWebviewResponse *response, NSError *error);

@interface MSIDWebviewAuthorization : NSObject

#if !MSID_EXCLUDE_WEBKIT

+ (void)startEmbeddedWebviewAuthWithConfiguration:(MSIDWebviewConfiguration *)configuration
                                    oauth2Factory:(MSIDOauth2Factory *)oauth2Factory
                                          context:(id<MSIDRequestContext>)context
                                completionHandler:(MSIDWebviewAuthCompletionHandler)completionHandler;

+ (void)startEmbeddedWebviewAuthWithConfiguration:(MSIDWebviewConfiguration *)configuration
                                    oauth2Factory:(MSIDOauth2Factory *)oauth2Factory
                                          webview:(WKWebView *)webview
                                          context:(id<MSIDRequestContext>)context
                                completionHandler:(MSIDWebviewAuthCompletionHandler)completionHandler;

#endif

#if TARGET_OS_IPHONE && !MSID_EXCLUDE_SYSTEMWV

// SFAuthenticationSession/ASWebAuthenticationSession is only available on iOS 11 and up.
//
// useAuthentication:YES allowSafariViewController:NO
//    > try SFAuthenticationSession/ASWebAuthenticationSession, if not availble, error out.
// useAuthentication:YES allowSafariViewController:YES
//    > try SFAuthenticationSession/ASWebAuthenticationSession, if not availble, use SFSafariViewController.
// useAuthentication:NO allowSafariViewController:YES
//    > do not use SFAuthenticationSession/ASWebAuthenticationSession, and always use SFSafariViewControler
+ (void)startSystemWebviewAuthWithConfiguration:(MSIDWebviewConfiguration *)configuration
                                  oauth2Factory:(MSIDOauth2Factory *)oauth2Factory
                       useAuthenticationSession:(BOOL)useAuthenticationSession
                      allowSafariViewController:(BOOL)allowSafariViewController
                                        context:(id<MSIDRequestContext>)context
                              completionHandler:(MSIDWebviewAuthCompletionHandler)completionHandler;
#endif

#if TARGET_OS_IPHONE && !MSID_EXCLUDE_SYSTEMWV
// This is for system webview auth session on iOS 10 - Thus, a SafariViewController
+ (BOOL)handleURLResponseForSystemWebviewController:(NSURL *)url;
#endif

#if !MSID_EXCLUDE_WEBKIT

+ (BOOL)setCurrentSession:(MSIDWebviewSession *)session;
+ (void)cancelCurrentSession;

// This can be utilized for having a custom webview controller, and for testing.
+ (void)startSession:(MSIDWebviewSession *)session
             context:(id<MSIDRequestContext>)context
   completionHandler:(MSIDWebviewAuthCompletionHandler)completionHandler;

@property (class, readonly) MSIDWebviewSession *currentSession;

#endif

@end



