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

#if SWIFT_PACKAGE
 #import "FBSDKSettings.h"
#else
 #import <FBSDKCoreKit/FBSDKSettings.h>
#endif

#import "FBSDKCoreKit+Internal.h"

#define DATA_PROCESSING_OPTIONS         @"data_processing_options"
#define DATA_PROCESSING_OPTIONS_COUNTRY @"data_processing_options_country"
#define DATA_PROCESSING_OPTIONS_STATE   @"data_processing_options_state"

@protocol FBSDKTokenCaching;
@protocol FBSDKDataPersisting;
@protocol FBSDKAppEventsConfigurationProviding;
@protocol FBSDKInfoDictionaryProviding;
@protocol FBSDKEventLogging;

@interface FBSDKSettings (Internal)

@property (class, nullable, nonatomic, readonly, copy) NSString *graphAPIDebugParamValue;

// used by Unity.
@property (class, nullable, nonatomic, copy) NSString *userAgentSuffix;

@property (class, nonnull, readonly) FBSDKSettings *sharedSettings;
@property (nonatomic) BOOL shouldUseTokenOptimizations;

+ (void)configureWithStore:(nonnull id<FBSDKDataPersisting>)store
appEventsConfigurationProvider:(nonnull Class<FBSDKAppEventsConfigurationProviding>)provider
    infoDictionaryProvider:(nonnull id<FBSDKInfoDictionaryProviding>)infoDictionaryProvider
               eventLogger:(nonnull id<FBSDKEventLogging>)eventLogger
NS_SWIFT_NAME(configure(store:appEventsConfigurationProvider:infoDictionaryProvider:eventLogger:));

+ (nullable NSObject<FBSDKTokenCaching> *)tokenCache;

+ (void)setTokenCache:(nullable NSObject<FBSDKTokenCaching> *)tokenCache;

+ (FBSDKAdvertisingTrackingStatus)advertisingTrackingStatus;

+ (void)setAdvertiserTrackingStatus:(FBSDKAdvertisingTrackingStatus)status;

+ (nullable NSDictionary<NSString *, id> *)dataProcessingOptions;

+ (BOOL)isDataProcessingRestricted;

+ (void)recordInstall;

+ (void)recordSetAdvertiserTrackingEnabled;

+ (BOOL)isEventDelayTimerExpired;

+ (BOOL)isSetATETimeExceedsInstallTime;

+ (NSDate *_Nullable)getInstallTimestamp;

+ (NSDate *_Nullable)getSetAdvertiserTrackingEnabledTimestamp;

+ (void)logWarnings;

+ (void)logIfSDKSettingsChanged;

@end
