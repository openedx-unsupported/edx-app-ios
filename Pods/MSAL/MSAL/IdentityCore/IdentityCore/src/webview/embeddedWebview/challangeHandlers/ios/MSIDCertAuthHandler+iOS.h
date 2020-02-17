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

#ifndef MSIDCertAuthHandler_iOS_h
#define MSIDCertAuthHandler_iOS_h

#import "MSIDCertAuthHandler.h"

@interface MSIDCertAuthHandler (iOS)

#if TARGET_OS_IPHONE && !MSID_EXCLUDE_SYSTEMWV

+ (void)setRedirectUriPrefix:(NSString *)prefix
                   forScheme:(NSString *)scheme;

// These are for cert auth challenge for iOS
+ (void)setCustomActivities:(NSArray<UIActivity *> *)activities;
+ (BOOL)completeCertAuthChallenge:(NSURL *)endUrl error:(NSError *)error;

#endif

@end
#endif /* MSIDCertAuthHandler_mac_h */
