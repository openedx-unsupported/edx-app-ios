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

#ifdef BUCK
 #import <FBSDKCoreKit_Basics/FBSDKBasicUtility.h>
 #import <FBSDKCoreKit_Basics/FBSDKCrashHandler.h>
 #import <FBSDKCoreKit_Basics/FBSDKCrashHandler+CrashHandlerProtocol.h>
 #import <FBSDKCoreKit_Basics/FBSDKCrashHandlerProtocol.h>
 #import <FBSDKCoreKit_Basics/FBSDKCrashObserving.h>
 #import <FBSDKCoreKit_Basics/FBSDKFileDataExtracting.h>
 #import  <FBSDKCoreKit_Basics/FBSDKFileManaging.h>
 #import <FBSDKCoreKit_Basics/FBSDKInfoDictionaryProviding.h>
 #import <FBSDKCoreKit_Basics/FBSDKJSONValue.h>
 #import <FBSDKCoreKit_Basics/FBSDKLibAnalyzer.h>
 #import <FBSDKCoreKit_Basics/FBSDKSafeCast.h>
 #import <FBSDKCoreKit_Basics/FBSDKSessionProviding.h>
 #import <FBSDKCoreKit_Basics/FBSDKTypeUtility.h>
 #import <FBSDKCoreKit_Basics/FBSDKURLSession.h>
 #import <FBSDKCoreKit_Basics/FBSDKURLSessionTask.h>
 #import <FBSDKCoreKit_Basics/FBSDKUserDataStore.h>
 #import <FBSDKCoreKit_Basics/NSBundle+InfoDictionaryProviding.h>
#else
 #import "FBSDKBasicUtility.h"
 #import "FBSDKCrashHandler.h"
 #import "FBSDKCrashHandler+CrashHandlerProtocol.h"
 #import "FBSDKCrashHandlerProtocol.h"
 #import "FBSDKCrashObserving.h"
 #import "FBSDKFileDataExtracting.h"
 #import "FBSDKFileManaging.h"
 #import "FBSDKInfoDictionaryProviding.h"
 #import "FBSDKJSONValue.h"
 #import "FBSDKLibAnalyzer.h"
 #import "FBSDKSafeCast.h"
 #import "FBSDKSessionProviding.h"
 #import "FBSDKTypeUtility.h"
 #import "FBSDKURLSession.h"
 #import "FBSDKURLSessionTask.h"
 #import "FBSDKUserDataStore.h"
 #import "NSBundle+InfoDictionaryProviding.h"
#endif
