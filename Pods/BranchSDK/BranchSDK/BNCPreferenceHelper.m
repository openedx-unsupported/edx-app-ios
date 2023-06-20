//
//  BNCPreferenceHelper.m
//  Branch-SDK
//
//  Created by Alex Austin on 6/6/14.
//  Copyright (c) 2014 Branch Metrics. All rights reserved.
//

#import "BNCPreferenceHelper.h"
#import "BNCEncodingUtils.h"
#import "BNCConfig.h"
#import "Branch.h"
#import "BNCLog.h"
#import "BranchConstants.h"
#import "NSString+Branch.h"
#import "BNCSKAdNetwork.h"

static const NSTimeInterval DEFAULT_TIMEOUT = 5.5;
static const NSTimeInterval DEFAULT_RETRY_INTERVAL = 0;
static const NSInteger DEFAULT_RETRY_COUNT = 3;
static const NSTimeInterval DEFAULT_REFERRER_GBRAID_WINDOW = 2592000; // 30 days = 2,592,000 seconds

static NSString * const BRANCH_PREFS_FILE = @"BNCPreferences";

static NSString * const BRANCH_PREFS_KEY_APP_VERSION = @"bnc_app_version";
static NSString * const BRANCH_PREFS_KEY_LAST_RUN_BRANCH_KEY = @"bnc_last_run_branch_key";
static NSString * const BRANCH_PREFS_KEY_LAST_STRONG_MATCH_DATE = @"bnc_strong_match_created_date";

static NSString * const BRANCH_PREFS_KEY_RANDOMIZED_DEVICE_TOKEN = @"bnc_randomized_device_token";
static NSString * const BRANCH_PREFS_KEY_RANDOMIZED_BUNDLE_TOKEN = @"bnc_randomized_bundle_token";

static NSString * const BRANCH_PREFS_KEY_SESSION_ID = @"bnc_session_id";
static NSString * const BRANCH_PREFS_KEY_IDENTITY = @"bnc_identity";
static NSString * const BRANCH_PREFS_KEY_CHECKED_FACEBOOK_APP_LINKS = @"bnc_checked_fb_app_links";
static NSString * const BRANCH_PREFS_KEY_CHECKED_APPLE_SEARCH_ADS = @"bnc_checked_apple_search_ads";
static NSString * const BRANCH_PREFS_KEY_APPLE_SEARCH_ADS_INFO = @"bnc_apple_search_ads_info";
static NSString * const BRANCH_PREFS_KEY_LINK_CLICK_IDENTIFIER = @"bnc_link_click_identifier";
static NSString * const BRANCH_PREFS_KEY_SPOTLIGHT_IDENTIFIER = @"bnc_spotlight_identifier";
static NSString * const BRANCH_PREFS_KEY_UNIVERSAL_LINK_URL = @"bnc_universal_link_url";
static NSString * const BRANCH_PREFS_KEY_LOCAL_URL = @"bnc_local_url";
static NSString * const BRANCH_PREFS_KEY_INITIAL_REFERRER = @"bnc_initial_referrer";
static NSString * const BRANCH_PREFS_KEY_SESSION_PARAMS = @"bnc_session_params";
static NSString * const BRANCH_PREFS_KEY_INSTALL_PARAMS = @"bnc_install_params";
static NSString * const BRANCH_PREFS_KEY_USER_URL = @"bnc_user_url";

static NSString * const BRANCH_PREFS_KEY_BRANCH_VIEW_USAGE_CNT = @"bnc_branch_view_usage_cnt_";
static NSString * const BRANCH_PREFS_KEY_ANALYTICAL_DATA = @"bnc_branch_analytical_data";
static NSString * const BRANCH_PREFS_KEY_ANALYTICS_MANIFEST = @"bnc_branch_analytics_manifest";
static NSString * const BRANCH_PREFS_KEY_REFERRER_GBRAID = @"bnc_referrer_gbraid";
static NSString * const BRANCH_PREFS_KEY_REFERRER_GBRAID_WINDOW = @"bnc_referrer_gbraid_window";
static NSString * const BRANCH_PREFS_KEY_REFERRER_GBRAID_INIT_DATE = @"bnc_referrer_gbraid_init_date";
static NSString * const BRANCH_PREFS_KEY_SKAN_CURRENT_WINDOW = @"bnc_skan_current_window";
static NSString * const BRANCH_PREFS_KEY_FIRST_APP_LAUNCH_TIME = @"bnc_first_app_launch_time";
static NSString * const BRANCH_PREFS_KEY_SKAN_HIGHEST_CONV_VALUE_SENT = @"bnc_skan_send_highest_conv_value";
static NSString * const BRANCH_PREFS_KEY_SKAN_INVOKE_REGISTER_APP = @"bnc_invoke_register_app";

NSURL* /* _Nonnull */ BNCURLForBranchDirectory_Unthreaded(void);

@interface BNCPreferenceHelper () {
    NSOperationQueue *_persistPrefsQueue;
    NSString         *_lastSystemBuildVersion;
    NSString         *_browserUserAgentString;
    NSString         *_branchAPIURL;
    NSString         *_referringURL;
}

@property (strong, nonatomic) NSMutableDictionary *persistenceDict;
@property (strong, nonatomic) NSMutableDictionary *requestMetadataDictionary;
@property (strong, nonatomic) NSMutableDictionary *instrumentationDictionary;

@end

@implementation BNCPreferenceHelper

@synthesize
            lastRunBranchKey = _lastRunBranchKey,
            appVersion = _appVersion,
            randomizedDeviceToken = _randomizedDeviceToken,
            sessionID = _sessionID,
            spotlightIdentifier = _spotlightIdentifier,
            randomizedBundleToken = _randomizedBundleToken,
            linkClickIdentifier = _linkClickIdentifier,
            userUrl = _userUrl,
            userIdentity = _userIdentity,
            sessionParams = _sessionParams,
            installParams = _installParams,
            universalLinkUrl = _universalLinkUrl,
            initialReferrer = _initialReferrer,
            localUrl = _localUrl,
            externalIntentURI = _externalIntentURI,
            isDebug = _isDebug,
            retryCount = _retryCount,
            retryInterval = _retryInterval,
            timeout = _timeout,
            lastStrongMatchDate = _lastStrongMatchDate,
            checkedFacebookAppLinks = _checkedFacebookAppLinks,
            checkedAppleSearchAdAttribution = _checkedAppleSearchAdAttribution,
            appleSearchAdDetails = _appleSearchAdDetails,
            requestMetadataDictionary = _requestMetadataDictionary,
            instrumentationDictionary = _instrumentationDictionary,
            referrerGBRAID = _referrerGBRAID,
            referrerGBRAIDValidityWindow = _referrerGBRAIDValidityWindow,
            skanCurrentWindow = _skanCurrentWindow,
            firstAppLaunchTime = _firstAppLaunchTime,
            highestConversionValueSent = _highestConversionValueSent;

+ (BNCPreferenceHelper *)sharedInstance {
    static BNCPreferenceHelper *preferenceHelper;
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        preferenceHelper = [[BNCPreferenceHelper alloc] init];
    });
    
    return preferenceHelper;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _timeout = DEFAULT_TIMEOUT;
        _retryCount = DEFAULT_RETRY_COUNT;
        _retryInterval = DEFAULT_RETRY_INTERVAL;
        _isDebug = NO;
        _persistPrefsQueue = [[NSOperationQueue alloc] init];
        _persistPrefsQueue.maxConcurrentOperationCount = 1;

        self.patternListURL = @"https://cdn.branch.io";
        self.disableAdNetworkCallouts = NO;
    }
    return self;
}

- (void) synchronize {
    [_persistPrefsQueue waitUntilAllOperationsAreFinished];
}

- (void) dealloc {
    [self synchronize];
}

#pragma mark - API methods

- (void) setBranchAPIURL:(NSString*)branchAPIURL_ {
    @synchronized (self) {
        _branchAPIURL = [branchAPIURL_ copy];
    }
}

- (NSString*) branchAPIURL {
    @synchronized (self) {
        if (!_branchAPIURL) {
            _branchAPIURL = [BNC_API_BASE_URL copy];
        }
        return _branchAPIURL;
    }
}

- (NSString *)getAPIBaseURL {
    @synchronized (self) {
        return [NSString stringWithFormat:@"%@/%@/", self.branchAPIURL, BNC_API_VERSION];
    }
}

- (NSString *)getAPIURL:(NSString *) endpoint {
    return [[self getAPIBaseURL] stringByAppendingString:endpoint];
}

- (NSString *)getEndpointFromURL:(NSString *)url {
    NSString *APIBase = self.branchAPIURL;
    if ([url hasPrefix:APIBase]) {
        NSUInteger index = APIBase.length;
        return [url substringFromIndex:index];
    }
    return @"";
}

#pragma mark - Preference Storage

- (NSString *)lastRunBranchKey {
    if (!_lastRunBranchKey) {
        _lastRunBranchKey = [self readStringFromDefaults:BRANCH_PREFS_KEY_LAST_RUN_BRANCH_KEY];
    }
    return _lastRunBranchKey;
}

- (void)setLastRunBranchKey:(NSString *)lastRunBranchKey {
    if (![_lastRunBranchKey isEqualToString:lastRunBranchKey]) {
        _lastRunBranchKey = lastRunBranchKey;
        [self writeObjectToDefaults:BRANCH_PREFS_KEY_LAST_RUN_BRANCH_KEY value:lastRunBranchKey];
    }
}

- (NSDate *)lastStrongMatchDate {
    if (!_lastStrongMatchDate) {
        _lastStrongMatchDate = (NSDate *)[self readObjectFromDefaults:BRANCH_PREFS_KEY_LAST_STRONG_MATCH_DATE];
    }
    return _lastStrongMatchDate;
}

- (void)setLastStrongMatchDate:(NSDate *)lastStrongMatchDate {
    if (lastStrongMatchDate == nil || ![_lastStrongMatchDate isEqualToDate:lastStrongMatchDate]) {
        _lastStrongMatchDate = lastStrongMatchDate;
        [self writeObjectToDefaults:BRANCH_PREFS_KEY_LAST_STRONG_MATCH_DATE value:lastStrongMatchDate];
    }
}

- (NSString *)appVersion {
    if (!_appVersion) {
        _appVersion = [self readStringFromDefaults:BRANCH_PREFS_KEY_APP_VERSION];
    }
    return _appVersion;
}

- (void)setAppVersion:(NSString *)appVersion {
    if (![_appVersion isEqualToString:appVersion]) {
        _appVersion = appVersion;
        [self writeObjectToDefaults:BRANCH_PREFS_KEY_APP_VERSION value:appVersion];
    }
}

- (NSString *)randomizedDeviceToken {
    if (!_randomizedDeviceToken) {
        NSString *tmp = [self readStringFromDefaults:BRANCH_PREFS_KEY_RANDOMIZED_DEVICE_TOKEN];
    
        // check deprecated location
        if (!tmp) {
            tmp = [self readStringFromDefaults:@"bnc_device_fingerprint_id"];
        }
        
        _randomizedDeviceToken = tmp;
    }
    
    return _randomizedDeviceToken;
}

- (void)setRandomizedDeviceToken:(NSString *)randomizedDeviceToken {
    if (randomizedDeviceToken == nil || ![_randomizedDeviceToken isEqualToString:randomizedDeviceToken]) {
        _randomizedDeviceToken = randomizedDeviceToken;
        [self writeObjectToDefaults:BRANCH_PREFS_KEY_RANDOMIZED_DEVICE_TOKEN value:randomizedDeviceToken];
    }
}

- (NSString *)sessionID {
    if (!_sessionID) {
        _sessionID = [self readStringFromDefaults:BRANCH_PREFS_KEY_SESSION_ID];
    }
    
    return _sessionID;
}

- (void)setSessionID:(NSString *)sessionID {
    if (sessionID == nil || ![_sessionID isEqualToString:sessionID]) {
        _sessionID = sessionID;
        [self writeObjectToDefaults:BRANCH_PREFS_KEY_SESSION_ID value:sessionID];
    }
}

- (NSString *)randomizedBundleToken {
    NSString *tmp = [self readStringFromDefaults:BRANCH_PREFS_KEY_RANDOMIZED_BUNDLE_TOKEN];
    
    // check deprecated location
    if (!tmp) {
        tmp = [self readStringFromDefaults:@"bnc_identity_id"];
    }
    
    return tmp;
}

- (void)setRandomizedBundleToken:(NSString *)randomizedBundleToken {
    [self writeObjectToDefaults:BRANCH_PREFS_KEY_RANDOMIZED_BUNDLE_TOKEN value:randomizedBundleToken];
}

- (NSString *)userIdentity {
    return [self readStringFromDefaults:BRANCH_PREFS_KEY_IDENTITY];
}

- (void)setUserIdentity:(NSString *)userIdentity {
    [self writeObjectToDefaults:BRANCH_PREFS_KEY_IDENTITY value:userIdentity];
}

- (NSString *)linkClickIdentifier {
    return [self readStringFromDefaults:BRANCH_PREFS_KEY_LINK_CLICK_IDENTIFIER];
}

- (void)setLinkClickIdentifier:(NSString *)linkClickIdentifier {
    [self writeObjectToDefaults:BRANCH_PREFS_KEY_LINK_CLICK_IDENTIFIER value:linkClickIdentifier];
}

- (NSString *)spotlightIdentifier {
    return [self readStringFromDefaults:BRANCH_PREFS_KEY_SPOTLIGHT_IDENTIFIER];
}

- (void)setSpotlightIdentifier:(NSString *)spotlightIdentifier {
    [self writeObjectToDefaults:BRANCH_PREFS_KEY_SPOTLIGHT_IDENTIFIER value:spotlightIdentifier];
}

- (NSString *)externalIntentURI {
    @synchronized(self) {
        if (!_externalIntentURI) {
            _externalIntentURI = [self readStringFromDefaults:BRANCH_REQUEST_KEY_EXTERNAL_INTENT_URI];
        }
        return _externalIntentURI;
    }
}

- (void)setExternalIntentURI:(NSString *)externalIntentURI {
    @synchronized(self) {
        if (externalIntentURI == nil || ![_externalIntentURI isEqualToString:externalIntentURI]) {
            _externalIntentURI = externalIntentURI;
            [self writeObjectToDefaults:BRANCH_REQUEST_KEY_EXTERNAL_INTENT_URI value:externalIntentURI];
        }
    }
}

- (NSString*) referringURL {
    @synchronized (self) {
        if (!_referringURL) _referringURL = [self readStringFromDefaults:@"referringURL"];
        return _referringURL;
    }
}

- (void) setReferringURL:(NSString *)referringURL {
    @synchronized (self) {
        _referringURL = [referringURL copy];
        [self writeObjectToDefaults:@"referringURL" value:_referringURL];
    }
}

- (NSString *)universalLinkUrl {
    return [self readStringFromDefaults:BRANCH_PREFS_KEY_UNIVERSAL_LINK_URL];
}

- (void)setUniversalLinkUrl:(NSString *)universalLinkUrl {
    [self writeObjectToDefaults:BRANCH_PREFS_KEY_UNIVERSAL_LINK_URL value:universalLinkUrl];
}

- (NSString *)localUrl {
    return [self readStringFromDefaults:BRANCH_PREFS_KEY_LOCAL_URL];
}

- (void)setLocalUrl:(NSString *)localURL {
    [self writeObjectToDefaults:BRANCH_PREFS_KEY_LOCAL_URL value:localURL];
}

- (NSString *)initialReferrer {
    return [self readStringFromDefaults:BRANCH_REQUEST_KEY_INITIAL_REFERRER];
}

- (void)setInitialReferrer:(NSString *)initialReferrer {
    [self writeObjectToDefaults:BRANCH_REQUEST_KEY_INITIAL_REFERRER value:initialReferrer];
}
- (NSString *)sessionParams {
    @synchronized (self) {
        if (!_sessionParams) {
            _sessionParams = [self readStringFromDefaults:BRANCH_PREFS_KEY_SESSION_PARAMS];
        }
        return _sessionParams;
    }
}

- (void)setSessionParams:(NSString *)sessionParams {
    @synchronized (self) {
        if (sessionParams == nil || ![_sessionParams isEqualToString:sessionParams]) {
            _sessionParams = sessionParams;
            [self writeObjectToDefaults:BRANCH_PREFS_KEY_SESSION_PARAMS value:sessionParams];
        }
    }
}

- (NSString *)installParams {
    @synchronized(self) {
        if (!_installParams) {
            id installParamsFromCache = [self readStringFromDefaults:BRANCH_PREFS_KEY_INSTALL_PARAMS];
            if ([installParamsFromCache isKindOfClass:[NSString class]]) {
                _installParams = [self readStringFromDefaults:BRANCH_PREFS_KEY_INSTALL_PARAMS];
            }
            else if ([installParamsFromCache isKindOfClass:[NSDictionary class]]) {
                [self writeObjectToDefaults:BRANCH_PREFS_KEY_INSTALL_PARAMS value:nil];
            }
        }
        return _installParams;
    }
}

- (void)setInstallParams:(NSString *)installParams {
    @synchronized(self) {
        if ([installParams isKindOfClass:[NSDictionary class]]) {
            _installParams = [BNCEncodingUtils encodeDictionaryToJsonString:(NSDictionary *)installParams];
            [self writeObjectToDefaults:BRANCH_PREFS_KEY_INSTALL_PARAMS value:_installParams];
            return;
        }
        if (installParams == nil || ![_installParams isEqualToString:installParams]) {
            _installParams = installParams;
            [self writeObjectToDefaults:BRANCH_PREFS_KEY_INSTALL_PARAMS value:installParams];
        }
    }
}

- (void) setAppleSearchAdDetails:(NSDictionary*)details {
    if (details == nil || [details isKindOfClass:[NSDictionary class]]) {
        _appleSearchAdDetails = details;
        [self writeObjectToDefaults:BRANCH_PREFS_KEY_APPLE_SEARCH_ADS_INFO value:details];
    }
}

- (NSDictionary*) appleSearchAdDetails {
    if (!_appleSearchAdDetails) {
        _appleSearchAdDetails = (NSDictionary *) [self readObjectFromDefaults:BRANCH_PREFS_KEY_APPLE_SEARCH_ADS_INFO];
    }
    return [_appleSearchAdDetails isKindOfClass:[NSDictionary class]] ? _appleSearchAdDetails : nil;
}

- (void) setAppleSearchAdNeedsSend:(BOOL)appleSearchAdNeedsSend {
    [self writeBoolToDefaults:@"_appleSearchAdNeedsSend" value:appleSearchAdNeedsSend];
}

- (BOOL) appleSearchAdNeedsSend {
    return [self readBoolFromDefaults:@"_appleSearchAdNeedsSend"];
}

- (void)setAppleAttributionTokenChecked:(BOOL)appleAttributionTokenChecked {
    [self writeBoolToDefaults:@"_appleAttributionTokenChecked" value:appleAttributionTokenChecked];
}

- (BOOL)appleAttributionTokenChecked {
    return [self readBoolFromDefaults:@"_appleAttributionTokenChecked"];
}

- (void)setHasOptedInBefore:(BOOL)hasOptedInBefore {
    [self writeBoolToDefaults:@"_hasOptedInBefore" value:hasOptedInBefore];
}

- (BOOL)hasOptedInBefore {
    return [self readBoolFromDefaults:@"_hasOptedInBefore"];
}

- (void)setHasCalledHandleATTAuthorizationStatus:(BOOL)hasCalledHandleATTAuthorizationStatus {
    [self writeBoolToDefaults:@"_hasCalledHandleATTAuthorizationStatus" value:hasCalledHandleATTAuthorizationStatus];
}

- (BOOL)hasCalledHandleATTAuthorizationStatus {
    return [self readBoolFromDefaults:@"_hasCalledHandleATTAuthorizationStatus"];
}

- (NSString*) lastSystemBuildVersion {
    if (!_lastSystemBuildVersion) {
        _lastSystemBuildVersion = [self readStringFromDefaults:@"_lastSystemBuildVersion"];
    }
    return _lastSystemBuildVersion;
}

- (void) setLastSystemBuildVersion:(NSString *)lastSystemBuildVersion {
    if (![_lastSystemBuildVersion isEqualToString:lastSystemBuildVersion]) {
        _lastSystemBuildVersion = lastSystemBuildVersion;
        [self writeObjectToDefaults:@"_lastSystemBuildVersion" value:_lastSystemBuildVersion];
    }
}

- (NSString*) browserUserAgentString {
    if (!_browserUserAgentString) {
        _browserUserAgentString = [self readStringFromDefaults:@"_browserUserAgentString"];
    }
    return _browserUserAgentString;
}

- (void) setBrowserUserAgentString:(NSString *)browserUserAgentString {
    if (![_browserUserAgentString isEqualToString:browserUserAgentString]) {
        _browserUserAgentString = browserUserAgentString;
        [self writeObjectToDefaults:@"_browserUserAgentString" value:_browserUserAgentString];
    }
}

- (NSString *)userUrl {
    if (!_userUrl) {
        _userUrl = [self readStringFromDefaults:BRANCH_PREFS_KEY_USER_URL];
    }
    
    return _userUrl;
}

- (void)setUserUrl:(NSString *)userUrl {
    if (![_userUrl isEqualToString:userUrl]) {
        _userUrl = userUrl;
        [self writeObjectToDefaults:BRANCH_PREFS_KEY_USER_URL value:userUrl];
    }
}

- (NSMutableString*) sanitizedMutableBaseURL:(NSString*)baseUrl_ {
    NSMutableString *baseUrl = [baseUrl_ mutableCopy];
    if (self.trackingDisabled) {
        NSString *id_string = [NSString stringWithFormat:@"%%24randomized_bundle_token=%@", self.randomizedBundleToken];
        NSRange range = [baseUrl rangeOfString:id_string];
        if (range.location != NSNotFound) [baseUrl replaceCharactersInRange:range withString:@""];
    } else
    if ([baseUrl hasSuffix:@"&"] || [baseUrl hasSuffix:@"?"]) {
    } else
    if ([baseUrl containsString:@"?"]) {
        [baseUrl appendString:@"&"];
    }
    else {
        [baseUrl appendString:@"?"];
    }
    return baseUrl;
}

- (BOOL)checkedAppleSearchAdAttribution {
    _checkedAppleSearchAdAttribution = [self readBoolFromDefaults:BRANCH_PREFS_KEY_CHECKED_APPLE_SEARCH_ADS];
    return _checkedAppleSearchAdAttribution;
}

- (void)setCheckedAppleSearchAdAttribution:(BOOL)checked {
    _checkedAppleSearchAdAttribution = checked;
    [self writeBoolToDefaults:BRANCH_PREFS_KEY_CHECKED_APPLE_SEARCH_ADS value:checked];
}


- (BOOL)checkedFacebookAppLinks {
    _checkedFacebookAppLinks = [self readBoolFromDefaults:BRANCH_PREFS_KEY_CHECKED_FACEBOOK_APP_LINKS];
    return _checkedFacebookAppLinks;
}

- (void)setCheckedFacebookAppLinks:(BOOL)checked {
    _checkedFacebookAppLinks = checked;
    [self writeBoolToDefaults:BRANCH_PREFS_KEY_CHECKED_FACEBOOK_APP_LINKS value:checked];
}

- (NSMutableDictionary *)requestMetadataDictionary {
    if (!_requestMetadataDictionary) {
        _requestMetadataDictionary = [NSMutableDictionary dictionary];
    }
    return _requestMetadataDictionary;
}

- (void)setRequestMetadataKey:(NSString *)key value:(NSObject *)value {
    if (!key) {
        return;
    }
    if ([self.requestMetadataDictionary objectForKey:key] && !value) {
        [self.requestMetadataDictionary removeObjectForKey:key];
    }
    else if (value) {
        [self.requestMetadataDictionary setObject:value forKey:key];
    }
}

- (NSDictionary *)instrumentationParameters {
    @synchronized (self) {
        if (_instrumentationDictionary.count == 0) {
            return nil; // this avoids the .count check in prepareParamDict
        }
        return [[NSDictionary alloc] initWithDictionary:_instrumentationDictionary];
    }
}

- (NSMutableDictionary *)instrumentationDictionary {
    @synchronized (self) {
        if (!_instrumentationDictionary) {
            _instrumentationDictionary = [NSMutableDictionary dictionary];
        }
        return _instrumentationDictionary;
    }
}

- (void)addInstrumentationDictionaryKey:(NSString *)key value:(NSString *)value {
    @synchronized (self) {
        if (key && value) {
            [self.instrumentationDictionary setObject:value forKey:key];
        }
    }
}

- (void)clearInstrumentationDictionary {
    @synchronized (self) {
        [_instrumentationDictionary removeAllObjects];
    }
}

- (BOOL) limitFacebookTracking {
    @synchronized (self) {
        return [self readBoolFromDefaults:@"_limitFacebookTracking"];
    }
}

- (void) setLimitFacebookTracking:(BOOL)limitFacebookTracking {
    @synchronized (self) {
        [self writeBoolToDefaults:@"_limitFacebookTracking" value:limitFacebookTracking];
    }
}

- (NSDate*) previousAppBuildDate {
    @synchronized (self) {
        NSDate *date = (NSDate*) [self readObjectFromDefaults:@"_previousAppBuildDate"];
        if ([date isKindOfClass:[NSDate class]]) return date;
        return nil;
    }
}

- (void) setPreviousAppBuildDate:(NSDate*)date {
    @synchronized (self) {
        if (date == nil || [date isKindOfClass:[NSDate class]])
            [self writeObjectToDefaults:@"_previousAppBuildDate" value:date];
    }
}

- (NSArray<NSString*>*) savedURLPatternList {
    @synchronized(self) {
        id a = [self readObjectFromDefaults:@"URLPatternList"];
        if ([a isKindOfClass:NSArray.class]) return a;
        return nil;
    }
}

- (void) setSavedURLPatternList:(NSArray<NSString *> *)URLPatternList {
    @synchronized(self) {
        [self writeObjectToDefaults:@"URLPatternList" value:URLPatternList];
    }
}

- (NSInteger) savedURLPatternListVersion {
    @synchronized(self) {
        return [self readIntegerFromDefaults:@"URLPatternListVersion"];
    }
}

- (void) setSavedURLPatternListVersion:(NSInteger)URLPatternListVersion {
    @synchronized(self) {
        [self writeIntegerToDefaults:@"URLPatternListVersion" value:URLPatternListVersion];
    }
}

- (BOOL) dropURLOpen {
    @synchronized(self) {
        return [self readBoolFromDefaults:@"dropURLOpen"];
    }
}

- (void) setDropURLOpen:(BOOL)value {
    @synchronized(self) {
        [self writeBoolToDefaults:@"dropURLOpen" value:value];
    }
}


- (BOOL) trackingDisabled {
    @synchronized(self) {
        NSNumber *b = (id) [self readObjectFromDefaults:@"trackingDisabled"];
        if ([b isKindOfClass:NSNumber.class]) return [b boolValue];
        return false;
    }
}

- (void) setTrackingDisabled:(BOOL)disabled {
    @synchronized(self) {
        NSNumber *b = [NSNumber numberWithBool:disabled];
        [self writeObjectToDefaults:@"trackingDisabled" value:b];
        if (disabled) [self clearTrackingInformation];
    }
}

- (BOOL)sendCloseRequests {
    @synchronized(self) {
        NSNumber *b = (id) [self readObjectFromDefaults:@"sendCloseRequests"];
        if ([b isKindOfClass:NSNumber.class]) return [b boolValue];
        
        // by default, we do not send close events
        return NO;
    }
}

- (void)setSendCloseRequests:(BOOL)disabled {
    @synchronized(self) {
        [self writeObjectToDefaults:@"sendCloseRequests" value:@(disabled)];
    }
}

- (NSString *) referrerGBRAID {
    @synchronized(self) {
        if (!_referrerGBRAID) {
            _referrerGBRAID = [self readStringFromDefaults:BRANCH_PREFS_KEY_REFERRER_GBRAID];
        }
        return _referrerGBRAID;
    }
}

- (void) setReferrerGBRAID:(NSString *)referrerGBRAID {
    if (![_referrerGBRAID isEqualToString:referrerGBRAID]) {
        _referrerGBRAID = referrerGBRAID;
        [self writeObjectToDefaults:BRANCH_PREFS_KEY_REFERRER_GBRAID value:referrerGBRAID];
        self.referrerGBRAIDInitDate = [NSDate date];
    }
}

- (NSTimeInterval) referrerGBRAIDValidityWindow {
    @synchronized (self) {
        _referrerGBRAIDValidityWindow = [self readDoubleFromDefaults:BRANCH_PREFS_KEY_REFERRER_GBRAID_WINDOW];
        if (_referrerGBRAIDValidityWindow == NSNotFound) {
            _referrerGBRAIDValidityWindow = DEFAULT_REFERRER_GBRAID_WINDOW;
        }
        return _referrerGBRAIDValidityWindow;
    }
}

- (void) setReferrerGBRAIDValidityWindow:(NSTimeInterval)validityWindow {
    @synchronized (self) {
        [self writeObjectToDefaults:BRANCH_PREFS_KEY_REFERRER_GBRAID_WINDOW value:@(validityWindow)];
    }
}

- (NSDate*) referrerGBRAIDInitDate {
    @synchronized (self) {
        NSDate* initdate = (NSDate*)[self readObjectFromDefaults:BRANCH_PREFS_KEY_REFERRER_GBRAID_INIT_DATE];
        if ([initdate isKindOfClass:[NSDate class]]) return initdate;
        return nil;
    }
}

- (void)setReferrerGBRAIDInitDate:(NSDate *)initDate {
    @synchronized (self) {
        [self writeObjectToDefaults:BRANCH_PREFS_KEY_REFERRER_GBRAID_INIT_DATE value:initDate];
    }
}

- (NSInteger) skanCurrentWindow {
    @synchronized (self) {
        _skanCurrentWindow = [self readIntegerFromDefaults:BRANCH_PREFS_KEY_SKAN_CURRENT_WINDOW];
        if(_skanCurrentWindow == NSNotFound)
            return BranchSkanWindowInvalid;
        return _skanCurrentWindow;
    }
}

- (void) setSkanCurrentWindow:(NSInteger) window {
    @synchronized (self) {
        [self writeIntegerToDefaults:BRANCH_PREFS_KEY_SKAN_CURRENT_WINDOW value:window];
    }
}


- (NSDate *) firstAppLaunchTime {
    @synchronized (self) {
        if(!_firstAppLaunchTime) {
            _firstAppLaunchTime = (NSDate *)[self readObjectFromDefaults:BRANCH_PREFS_KEY_FIRST_APP_LAUNCH_TIME];
        }
        return _firstAppLaunchTime;
    }
}

- (void) setFirstAppLaunchTime:(NSDate *) launchTime {
    @synchronized (self) {
        _firstAppLaunchTime = launchTime;
        [self writeObjectToDefaults:BRANCH_PREFS_KEY_FIRST_APP_LAUNCH_TIME value:launchTime];
    }
}

- (NSInteger) highestConversionValueSent {
    @synchronized (self) {
        _highestConversionValueSent = [self readIntegerFromDefaults:BRANCH_PREFS_KEY_SKAN_HIGHEST_CONV_VALUE_SENT];
        if(_highestConversionValueSent == NSNotFound)
            return 0;
        return _highestConversionValueSent;
    }
}

- (void) setHighestConversionValueSent:(NSInteger)value {
    @synchronized (self) {
        [self writeIntegerToDefaults:BRANCH_PREFS_KEY_SKAN_HIGHEST_CONV_VALUE_SENT value:value];
    }
}

- (BOOL) invokeRegisterApp {
    @synchronized (self) {
        NSNumber *b = (id) [self readObjectFromDefaults:BRANCH_PREFS_KEY_SKAN_INVOKE_REGISTER_APP];
        if ([b isKindOfClass:NSNumber.class]) return [b boolValue];
        return false;
    }
}

- (void) setInvokeRegisterApp:(BOOL)invoke {
    @synchronized(self) {
        NSNumber *b = [NSNumber numberWithBool:invoke];
        [self writeObjectToDefaults:BRANCH_PREFS_KEY_SKAN_INVOKE_REGISTER_APP value:b];
    }
}


- (void) clearTrackingInformation {
    @synchronized(self) {
        /*
         // Don't clear these
         self.randomizedDeviceToken = nil;
         self.randomizedBundleToken = nil;
         */
        self.sessionID = nil;
        self.linkClickIdentifier = nil;
        self.spotlightIdentifier = nil;
        self.referringURL = nil;
        self.universalLinkUrl = nil;
        self.initialReferrer = nil;
        self.installParams = nil;
        self.appleSearchAdDetails = nil;
        self.appleSearchAdNeedsSend = NO;
        self.sessionParams = nil;
        self.externalIntentURI = nil;
        self.savedAnalyticsData = nil;
        self.previousAppBuildDate = nil;
        self.requestMetadataDictionary = nil;
        self.lastStrongMatchDate = nil;
        self.userIdentity = nil;
    }
}

#pragma mark - Count Storage

- (void)saveBranchAnalyticsData:(NSDictionary *)analyticsData {
    if (_sessionID) {
        if (!_savedAnalyticsData) {
            _savedAnalyticsData = [self getBranchAnalyticsData];
        }
        NSMutableArray *viewDataArray = [_savedAnalyticsData objectForKey:_sessionID];
        if (!viewDataArray) {
            viewDataArray = [[NSMutableArray alloc] init];
            [_savedAnalyticsData setObject:viewDataArray forKey:_sessionID];
        }
        [viewDataArray addObject:analyticsData];
        [self writeObjectToDefaults:BRANCH_PREFS_KEY_ANALYTICAL_DATA value:_savedAnalyticsData];
    }
}

- (void)clearBranchAnalyticsData {
    [self writeObjectToDefaults:BRANCH_PREFS_KEY_ANALYTICAL_DATA value:nil];
    _savedAnalyticsData = nil;
}

- (NSMutableDictionary *)getBranchAnalyticsData {
    NSMutableDictionary *analyticsDataObj = _savedAnalyticsData;
    if (!analyticsDataObj) {
        analyticsDataObj = (NSMutableDictionary *)[self readObjectFromDefaults:BRANCH_PREFS_KEY_ANALYTICAL_DATA];
        if (!analyticsDataObj) {
            analyticsDataObj = [[NSMutableDictionary alloc] init];
        }
    }
    return analyticsDataObj;
}

- (void)saveContentAnalyticsManifest:(NSDictionary *)cdManifest {
    [self writeObjectToDefaults:BRANCH_PREFS_KEY_ANALYTICS_MANIFEST value:cdManifest];
}

- (NSDictionary *)getContentAnalyticsManifest {
    return (NSDictionary *)[self readObjectFromDefaults:BRANCH_PREFS_KEY_ANALYTICS_MANIFEST];
}

#pragma mark - Writing To Persistence

- (void)writeIntegerToDefaults:(NSString *)key value:(NSInteger)value {
    [self writeObjectToDefaults:key value:@(value)];
}

- (void)writeBoolToDefaults:(NSString *)key value:(BOOL)value {
    [self writeObjectToDefaults:key value:@(value)];
}

- (void)writeObjectToDefaults:(NSString *)key value:(NSObject *)value {
    @synchronized (self) {
        if (value) {
            self.persistenceDict[key] = value;
        }
        else {
            [self.persistenceDict removeObjectForKey:key];
        }
        [self persistPrefsToDisk];
    }
}

- (void)persistPrefsToDisk {
    @synchronized (self) {
        if (!self.persistenceDict) return;

        NSData *data = [self serializePrefDict:self.persistenceDict];
        if (!data) return;
        
        NSURL *prefsURL = [self.class.URLForPrefsFile copy];
        NSBlockOperation *newPersistOp = [NSBlockOperation blockOperationWithBlock:^ {
            NSError *error = nil;
            [data writeToURL:prefsURL options:NSDataWritingAtomic error:&error];
            if (error) {
                BNCLogWarning([NSString stringWithFormat:@"Failed to persist preferences: %@.", error]);
            }
        }];
        [_persistPrefsQueue addOperation:newPersistOp];
    }
}

- (NSData *)serializePrefDict:(NSMutableDictionary *)dict {
    if (dict == nil) return nil;
    
    NSData *data = nil;
    @try {
        if (@available(iOS 11.0, tvOS 11.0, *)) {
            data = [NSKeyedArchiver archivedDataWithRootObject:dict requiringSecureCoding:YES error:NULL];
        } else {
            #if __IPHONE_OS_VERSION_MIN_REQUIRED < 12000
            data = [NSKeyedArchiver archivedDataWithRootObject:dict];
            #endif
        }
    } @catch (id exception) {
        BNCLogWarning([NSString stringWithFormat:@"Exception serializing preferences dict: %@.", exception]);
    }
    return data;
}

+ (void) clearAll {
    NSURL *prefsURL = [self.URLForPrefsFile copy];
    if (prefsURL) [[NSFileManager defaultManager] removeItemAtURL:prefsURL error:nil];
}

#pragma mark - Reading From Persistence

- (NSMutableDictionary *)persistenceDict {
    @synchronized(self) {
        if (!_persistenceDict) {
            _persistenceDict = [self deserializePrefDictFromData:[self loadPrefData]];
        }
        return _persistenceDict;
    }
}

- (NSData *)loadPrefData {
    NSData *data = nil;
    @try {
        NSError *error = nil;
        data = [NSData dataWithContentsOfURL:self.class.URLForPrefsFile options:0 error:&error];
        if (error || !data) {
            BNCLogWarning(@"Failed to load preferences from storage.");
        }
    } @catch (NSException *) {
        BNCLogWarning(@"Failed to load preferences from storage.");
    }
    return data;
}

- (NSMutableDictionary *)deserializePrefDictFromData:(NSData *)data {
    NSDictionary *dict = nil;
    if (data) {
        if (@available(iOS 11.0, tvOS 11.0, *)) {
            NSError *error = nil;
            NSSet *classes = [[NSMutableSet alloc] initWithArray:@[ NSNumber.class, NSString.class, NSDate.class, NSArray.class, NSDictionary.class ]];

            dict = [NSKeyedUnarchiver unarchivedObjectOfClasses:classes fromData:data error:&error];
            if (error) {
                BNCLogWarning(@"Failed to load preferences from storage.");
            }

        } else {
        #if __IPHONE_OS_VERSION_MIN_REQUIRED < 12000
            dict = [NSKeyedUnarchiver unarchiveObjectWithData:data];
        #endif
        }
    }
    
    // NSKeyedUnarchiver returns an NSDictionary, convert to NSMutableDictionary
    if (dict && [dict isKindOfClass:[NSDictionary class]]) {
        return [dict mutableCopy];
    } else {
        return [[NSMutableDictionary alloc] init];
    }
}

- (NSObject *)readObjectFromDefaults:(NSString *)key {
    @synchronized(self) {
        NSObject *obj = self.persistenceDict[key];
        return obj;
    }
}

- (NSString *)readStringFromDefaults:(NSString *)key {
    @synchronized(self) {
        id str = self.persistenceDict[key];
        
        // protect against NSNumber
        if ([str isKindOfClass:[NSNumber class]]) {
            str = [str stringValue];
        }
        
        // protect against anything else
        if (![str isKindOfClass:[NSString class]]) {
            str = nil;
        }
        
        return str;
    }
}

- (BOOL)readBoolFromDefaults:(NSString *)key {
    @synchronized(self) {
        BOOL boo = NO;

        NSNumber *boolean = self.persistenceDict[key];
        if ([boolean respondsToSelector:@selector(boolValue)]) {
            boo = [boolean boolValue];
        }
        
        return boo;
    }
}

- (NSInteger)readIntegerFromDefaults:(NSString *)key {
    @synchronized(self) {
        NSNumber *number = self.persistenceDict[key];
        if (number != nil && [number respondsToSelector:@selector(integerValue)]) {
            return [number integerValue];
        }
        return NSNotFound;
    }
}

- (double)readDoubleFromDefaults:(NSString *)key {
    @synchronized(self) {
        NSNumber *number = self.persistenceDict[key];
        if (number != nil && [number respondsToSelector:@selector(doubleValue)]){
            return [number doubleValue];
        }
        return NSNotFound;
    }
}

#pragma mark - Preferences File URL

+ (NSURL* _Nonnull) URLForPrefsFile {
    NSURL *URL = BNCURLForBranchDirectory();
    URL = [URL URLByAppendingPathComponent:BRANCH_PREFS_FILE isDirectory:NO];
    return URL;
}

@end

#pragma mark - BNCURLForBranchDirectory

NSURL* _Null_unspecified BNCCreateDirectoryForBranchURLWithSearchPath_Unthreaded(NSSearchPathDirectory directory) {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSArray *URLs = [fileManager URLsForDirectory:directory inDomains:NSUserDomainMask | NSLocalDomainMask];

    for (NSURL *URL in URLs) {
        NSError *error = nil;
        NSURL *branchURL = [[NSURL alloc] initWithString:@"io.branch" relativeToURL:URL];
        BOOL success =
            [fileManager
                createDirectoryAtURL:branchURL
                withIntermediateDirectories:YES
                attributes:nil
                error:&error];
        if (success) {
            return branchURL;
        } else  {
            // BNCLog is dependent on BNCCreateDirectoryForBranchURLWithSearchPath_Unthreaded and cannot be used to log errors from it.
            NSLog(@"CreateBranchURL failed: %@ URL: %@.", error, branchURL);
        }
    }
    return nil;
}

NSURL* _Nonnull BNCURLForBranchDirectory_Unthreaded() {
    #if TARGET_OS_TV
    // tvOS only allows the caches or temp directory
    NSArray *kSearchDirectories = @[
        @(NSCachesDirectory)
    ];
    #else
    NSArray *kSearchDirectories = @[
        @(NSApplicationSupportDirectory),
        @(NSLibraryDirectory),
        @(NSCachesDirectory),
        @(NSDocumentDirectory),
    ];
    #endif
    
    for (NSNumber *directory in kSearchDirectories) {
        NSSearchPathDirectory directoryValue = [directory unsignedLongValue];
        NSURL *URL = BNCCreateDirectoryForBranchURLWithSearchPath_Unthreaded(directoryValue);
        if (URL) return URL;
    }

    //  Worst case backup plan.  This does NOT work on tvOS.
    NSString *path = [@"~/Library/io.branch" stringByExpandingTildeInPath];
    NSURL *branchURL = [NSURL fileURLWithPath:path isDirectory:YES];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSError *error = nil;
    BOOL success =
        [fileManager
            createDirectoryAtURL:branchURL
            withIntermediateDirectories:YES
            attributes:nil
            error:&error];
    if (!success) {
        // BNCLog is dependent on BNCURLForBranchDirectory_Unthreaded and cannot be used to log errors from it.
        NSLog(@"Worst case CreateBranchURL error was: %@ URL: %@.", error, branchURL);
    }
    return branchURL;
}

NSURL* _Nonnull BNCURLForBranchDirectory() {
    static NSURL *urlForBranchDirectory = nil;
    static dispatch_once_t onceToken = 0;
    dispatch_once(&onceToken, ^ {
        urlForBranchDirectory = BNCURLForBranchDirectory_Unthreaded();
    });
    return urlForBranchDirectory;
}
