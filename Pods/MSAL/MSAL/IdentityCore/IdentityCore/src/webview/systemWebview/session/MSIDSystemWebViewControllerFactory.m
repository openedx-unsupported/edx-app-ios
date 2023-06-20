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

#import "MSIDSystemWebViewControllerFactory.h"
#import "MSIDASWebAuthenticationSessionHandler.h"
#import "MSIDConstants.h"
#if TARGET_OS_IPHONE && !TARGET_OS_MACCATALYST
#import "MSIDSFAuthenticationSessionHandler.h"
#endif

#if TARGET_OS_IPHONE
#import "MSIDSafariViewController.h"
#endif

@implementation MSIDSystemWebViewControllerFactory

+ (MSIDWebviewType)availableWebViewTypeWithPreferredType:(MSIDWebviewType)preferredType
{
    if (preferredType != MSIDWebviewTypeDefault)
    {
        return preferredType;
    }
    
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 120000 || __MAC_OS_X_VERSION_MAX_ALLOWED >= 101500
        
    if (@available(iOS 12.0, macOS 10.15, *))
    {
        return MSIDWebviewTypeAuthenticationSession;
    }
#endif
        
#if TARGET_OS_IPHONE && !TARGET_OS_MACCATALYST
        
    if (@available(iOS 11.0, *))
    {
        return MSIDWebviewTypeAuthenticationSession;
    }
        
#endif
    
#if TARGET_OS_IPHONE
    return MSIDWebviewTypeSafariViewController;
#endif
    
    return MSIDWebviewTypeWKWebView;
}

+ (id<MSIDWebviewInteracting>)authSessionWithParentController:(__unused MSIDViewController *)parentController
                                                     startURL:(__unused NSURL *)startURL
                                               callbackScheme:(__unused NSString *)callbackURLScheme
                                           useEmpheralSession:(__unused BOOL)useEmpheralSession
                                                      context:(__unused id<MSIDRequestContext>)context
{
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 120000 || __MAC_OS_X_VERSION_MAX_ALLOWED >= 101500
    
    if (@available(iOS 12.0, macOS 10.15, *))
    {
        return [[MSIDASWebAuthenticationSessionHandler alloc] initWithParentController:parentController
                                                                              startURL:startURL
                                                                        callbackScheme:callbackURLScheme
                                                                    useEmpheralSession:useEmpheralSession];
    }
#endif
    
#if TARGET_OS_IPHONE && !TARGET_OS_MACCATALYST
    
    if (@available(iOS 11.0, *))
    {
        return [[MSIDSFAuthenticationSessionHandler alloc] initWithStartURL:startURL callbackScheme:callbackURLScheme];
    }
    
#endif
    
    return nil;
}

#if TARGET_OS_IPHONE
+ (id<MSIDWebviewInteracting>)systemWebviewControllerWithParentController:(MSIDViewController *)parentController
                                                                 startURL:(NSURL *)startURL
                                                           callbackScheme:(NSString *)callbackURLScheme
                                                       useEmpheralSession:(BOOL)useEmpheralSession
                                                         presentationType:(UIModalPresentationStyle)presentationType
                                                                  context:(id<MSIDRequestContext>)context
{
    id<MSIDWebviewInteracting> authSession = [self authSessionWithParentController:parentController
                                                                          startURL:startURL
                                                                    callbackScheme:callbackURLScheme
                                                                useEmpheralSession:useEmpheralSession
                                                                           context:context];
    
    if (authSession)
    {
        return authSession;
    }
    
    return [[MSIDSafariViewController alloc] initWithURL:startURL
                                        parentController:parentController
                                        presentationType:presentationType
                                                 context:context];
}

#endif

@end

#endif
