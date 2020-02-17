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

#import "MSIDAppExtensionUtil.h"
#import "MSIDMainThreadUtil.h"

@implementation MSIDAppExtensionUtil

+ (BOOL)isExecutingInAppExtension
{
    NSString *mainBundlePath = [[NSBundle mainBundle] bundlePath];
    
    if (mainBundlePath.length == 0)
    {
        MSID_LOG_WITH_CTX(MSIDLogLevelError, nil, @"Expected `[[NSBundle mainBundle] bundlePath]` to be non-nil. Defaulting to non-application-extension safe API.");
        
        return NO;
    }
    
    return [mainBundlePath hasSuffix:@"appex"];
}

#pragma mark - UIApplication

+ (UIApplication*)sharedApplication
{
    if ([self isExecutingInAppExtension])
    {
        // The caller should do this check but we will double check to fail safely
        return nil;
    }
    
    return [UIApplication performSelector:NSSelectorFromString(@"sharedApplication")];
}

+ (void)sharedApplicationOpenURL:(NSURL*)url
{
    if ([self isExecutingInAppExtension])
    {
        // The caller should do this check but we will double check to fail safely
        return;
    }
    
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    
    [MSIDMainThreadUtil executeOnMainThreadIfNeeded:^{
        [[self sharedApplication] performSelector:NSSelectorFromString(@"openURL:") withObject:url];
    }];
#pragma clang diagnostic pop
}

+ (void)sharedApplicationOpenURL:(NSURL *)url
                         options:(NSDictionary<UIApplicationOpenExternalURLOptionsKey, id> *)options
               completionHandler:(void (^ __nullable)(BOOL success))completionHandler
{
    if ([self isExecutingInAppExtension])
    {
        // The caller should do this check but we will double check to fail safely
        return;
    }
    
    [MSIDMainThreadUtil executeOnMainThreadIfNeeded:^{
        
        SEL openURLSelector = @selector(openURL:options:completionHandler:);
        UIApplication *application = [self sharedApplication];
        id (*safeOpenURL)(id, SEL, id, id, id) = (void *)[application methodForSelector:openURLSelector];
        
        safeOpenURL(application, openURLSelector, url, options, completionHandler);
    }];
}

@end
