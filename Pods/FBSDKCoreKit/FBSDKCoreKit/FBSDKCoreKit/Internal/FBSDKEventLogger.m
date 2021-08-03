// Copyright (c) 2014-present, Facebook, Inc. All rights reserved.
//
// You are hereby granted a non-exclusive, worldwide, royalty-free license to use,
// copy, modify, and distribute this software in source code or binary form for use
// in connection with the web services and APIs provided by Facebook.
//
// As with any software that integrates with the Facebook platform, your use of
// this software is subject to the Facebook Developer Principles and Policies
// [http://developers.facebook.com/policy/]. This copyright notice shall be
// included in all copies or substantial portions of the software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
// FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
// COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
// IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
// CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

#import "FBSDKEventLogger.h"

#import "FBSDKAppEvents+Internal.h"

@class FBSDKAppEvents;

// A wrapper class for AppEvents to help change the semantics and decouple it from the types that use it
@implementation FBSDKEventLogger

- (void)logEvent:(NSString *)eventName
      parameters:(NSDictionary<NSString *, id> *)parameters
{
  [FBSDKAppEvents logEvent:eventName parameters:parameters];
}

- (void)logInternalEvent:(nonnull NSString *)eventName isImplicitlyLogged:(BOOL)isImplicitlyLogged
{
  [FBSDKAppEvents logInternalEvent:eventName isImplicitlyLogged:isImplicitlyLogged];
}

- (void)logInternalEvent:(NSString *)eventName
              parameters:(NSDictionary *)parameters
      isImplicitlyLogged:(BOOL)isImplicitlyLogged
{
  [FBSDKAppEvents logInternalEvent:eventName
                        parameters:parameters
                isImplicitlyLogged:isImplicitlyLogged];
}

- (void)logInternalEvent:(nonnull NSString *)eventName
              parameters:(nonnull NSDictionary *)parameters
      isImplicitlyLogged:(BOOL)isImplicitlyLogged
             accessToken:(id)accessToken
{
  [FBSDKAppEvents logInternalEvent:eventName
                        parameters:parameters
                isImplicitlyLogged:isImplicitlyLogged
                       accessToken:accessToken];
}

@end
