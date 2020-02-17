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

/// Collection of utilities to execute methods normally marked as non-application-extension safe. This allows us to produce a single framework that can be marked as application-extension-safe while still exercising capabilites when linked against a main app executable.
@interface MSIDAppExtensionUtil : NSObject

/// Determine whether or not the host app is an application extension based on the main bundle path
+ (BOOL)isExecutingInAppExtension;
/// Application extension safe replacement for `[UIApplication sharedApplication]`. The caller should make sure `isExecutingInAppExtension == NO` before calling this method.
+ (nullable UIApplication *)sharedApplication;
/// Application extension safe replacement for `[[UIApplication sharedApplication] openURL:]`. The caller should make sure `isExecutingInAppExtension == NO` before calling this method.
+ (void)sharedApplicationOpenURL:(nonnull NSURL *)url;

/// Application extension safe replacement for `[[UIApplication sharedApplication] openURL:options:completionHandler:]`. The caller should make sure `isExecutingInAppExtension == NO` before calling this method.
+ (void)sharedApplicationOpenURL:(nonnull NSURL *)url
                         options:(nullable NSDictionary<UIApplicationOpenExternalURLOptionsKey, id> *)options
               completionHandler:(void (^ __nullable)(BOOL success))completionHandler;

@end
