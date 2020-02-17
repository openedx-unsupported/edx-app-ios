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

#import <UIKit/UIKit.h>
#import "MSIDAppExtensionUtil.h"
#import "UIApplication+MSIDExtensions.h"

@implementation UIApplication ( internal )

+ (UIViewController *)msidCurrentViewController:(UIViewController *)parentController
{
    if (parentController)
    {
        return [self msidCurrentViewControllerWithRootViewController:parentController];
    }
    
    if ([MSIDAppExtensionUtil isExecutingInAppExtension]) return nil;
    
#if !TARGET_OS_MACCATALYST
    __auto_type controller = [self msidCurrentViewControllerWithRootViewController:[MSIDAppExtensionUtil sharedApplication].keyWindow.rootViewController];
    return controller;
#else
    
    for (UIWindow *window in [MSIDAppExtensionUtil sharedApplication].windows)
    {
        if (window.isKeyWindow)
        {
            return [self msidCurrentViewControllerWithRootViewController:window.rootViewController];
        }
    }
    
    MSID_LOG_WITH_CTX(MSIDLogLevelError, nil, @"Couldn't find key window");
    return nil;
#endif
}

+ (UIViewController*)msidCurrentViewControllerWithRootViewController:(UIViewController *)rootViewController
{
    if ([rootViewController isKindOfClass:[UITabBarController class]])
    {
        UITabBarController *tabBarController = (UITabBarController*)rootViewController;
        return [self msidCurrentViewControllerWithRootViewController:tabBarController.selectedViewController];
    }
    else if ([rootViewController isKindOfClass:[UINavigationController class]])
    {
        UINavigationController *navigationController = (UINavigationController*)rootViewController;
        return [self msidCurrentViewControllerWithRootViewController:navigationController.visibleViewController];
    }
    else if (rootViewController.presentedViewController)
    {
        UIViewController *presentedViewController = rootViewController.presentedViewController;
        return [self msidCurrentViewControllerWithRootViewController:presentedViewController];
    }
    else
    {
        return rootViewController;
    }
}

@end
