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

#import "FBSDKAppEvents.h"
#import "FBSDKAppEvents+Internal.h"

#import <UIKit/UIApplication.h>

#import "FBSDKAccessToken.h"
#import "FBSDKAppEventsState.h"
#import "FBSDKAppEventsStateManager.h"
#import "FBSDKAppEventsUtility.h"
#import "FBSDKConstants.h"
#import "FBSDKError.h"
#import "FBSDKGraphRequest+Internal.h"
#import "FBSDKInternalUtility.h"
#import "FBSDKLogger.h"
#import "FBSDKPaymentObserver.h"
#import "FBSDKServerConfiguration.h"
#import "FBSDKServerConfigurationManager.h"
#import "FBSDKSettings.h"
#import "FBSDKTimeSpentData.h"
#import "FBSDKUtility.h"

//
// Public event names
//

// General purpose
NSString *const FBSDKAppEventNameCompletedRegistration   = @"fb_mobile_complete_registration";
NSString *const FBSDKAppEventNameViewedContent           = @"fb_mobile_content_view";
NSString *const FBSDKAppEventNameSearched                = @"fb_mobile_search";
NSString *const FBSDKAppEventNameRated                   = @"fb_mobile_rate";
NSString *const FBSDKAppEventNameCompletedTutorial       = @"fb_mobile_tutorial_completion";
NSString *const FBSDKAppEventParameterLaunchSource          = @"fb_mobile_launch_source";

// Ecommerce related
NSString *const FBSDKAppEventNameAddedToCart             = @"fb_mobile_add_to_cart";
NSString *const FBSDKAppEventNameAddedToWishlist         = @"fb_mobile_add_to_wishlist";
NSString *const FBSDKAppEventNameInitiatedCheckout       = @"fb_mobile_initiated_checkout";
NSString *const FBSDKAppEventNameAddedPaymentInfo        = @"fb_mobile_add_payment_info";

// Gaming related
NSString *const FBSDKAppEventNameAchievedLevel           = @"fb_mobile_level_achieved";
NSString *const FBSDKAppEventNameUnlockedAchievement     = @"fb_mobile_achievement_unlocked";
NSString *const FBSDKAppEventNameSpentCredits            = @"fb_mobile_spent_credits";

//
// Public event parameter names
//

NSString *const FBSDKAppEventParameterNameCurrency               = @"fb_currency";
NSString *const FBSDKAppEventParameterNameRegistrationMethod     = @"fb_registration_method";
NSString *const FBSDKAppEventParameterNameContentType            = @"fb_content_type";
NSString *const FBSDKAppEventParameterNameContentID              = @"fb_content_id";
NSString *const FBSDKAppEventParameterNameSearchString           = @"fb_search_string";
NSString *const FBSDKAppEventParameterNameSuccess                = @"fb_success";
NSString *const FBSDKAppEventParameterNameMaxRatingValue         = @"fb_max_rating_value";
NSString *const FBSDKAppEventParameterNamePaymentInfoAvailable   = @"fb_payment_info_available";
NSString *const FBSDKAppEventParameterNameNumItems               = @"fb_num_items";
NSString *const FBSDKAppEventParameterNameLevel                  = @"fb_level";
NSString *const FBSDKAppEventParameterNameDescription            = @"fb_description";

//
// Public event parameter values
//

NSString *const FBSDKAppEventParameterValueNo                    = @"0";
NSString *const FBSDKAppEventParameterValueYes                   = @"1";

//
// Event names internal to this file
//
NSString *const FBSDKAppEventNamePurchased        = @"fb_mobile_purchase";

NSString *const FBSDKAppEventNameLoginViewUsage                   = @"fb_login_view_usage";
NSString *const FBSDKAppEventNameShareSheetLaunch                 = @"fb_share_sheet_launch";
NSString *const FBSDKAppEventNameShareSheetDismiss                = @"fb_share_sheet_dismiss";
NSString *const FBSDKAppEventNameShareTrayDidLaunch               = @"fb_share_tray_did_launch";
NSString *const FBSDKAppEventNameShareTrayDidSelectActivity       = @"fb_share_tray_did_select_activity";
NSString *const FBSDKAppEventNamePermissionsUILaunch              = @"fb_permissions_ui_launch";
NSString *const FBSDKAppEventNamePermissionsUIDismiss             = @"fb_permissions_ui_dismiss";
NSString *const FBSDKAppEventNameFBDialogsPresentShareDialog      = @"fb_dialogs_present_share";
NSString *const FBSDKAppEventNameFBDialogsPresentShareDialogPhoto = @"fb_dialogs_present_share_photo";
NSString *const FBSDKAppEventNameFBDialogsPresentShareDialogOG    = @"fb_dialogs_present_share_og";
NSString *const FBSDKAppEventNameFBDialogsPresentLikeDialogOG     = @"fb_dialogs_present_like_og";
NSString *const FBSDKAppEventNameFBDialogsPresentMessageDialog      = @"fb_dialogs_present_message";
NSString *const FBSDKAppEventNameFBDialogsPresentMessageDialogPhoto = @"fb_dialogs_present_message_photo";
NSString *const FBSDKAppEventNameFBDialogsPresentMessageDialogOG    = @"fb_dialogs_present_message_og";

NSString *const FBSDKAppEventNameFBDialogsNativeLoginDialogStart  = @"fb_dialogs_native_login_dialog_start";
NSString *const FBSDKAppEventsNativeLoginDialogStartTime          = @"fb_native_login_dialog_start_time";

NSString *const FBSDKAppEventNameFBDialogsNativeLoginDialogEnd    = @"fb_dialogs_native_login_dialog_end";
NSString *const FBSDKAppEventsNativeLoginDialogEndTime            = @"fb_native_login_dialog_end_time";

NSString *const FBSDKAppEventNameFBDialogsWebLoginCompleted       = @"fb_dialogs_web_login_dialog_complete";
NSString *const FBSDKAppEventsWebLoginE2E                         = @"fb_web_login_e2e";

NSString *const FBSDKAppEventNameFBSessionAuthStart               = @"fb_mobile_login_start";
NSString *const FBSDKAppEventNameFBSessionAuthEnd                 = @"fb_mobile_login_complete";
NSString *const FBSDKAppEventNameFBSessionAuthMethodStart         = @"fb_mobile_login_method_start";
NSString *const FBSDKAppEventNameFBSessionAuthMethodEnd           = @"fb_mobile_login_method_complete";

NSString *const FBSDKAppEventNameFBSDKLikeButtonImpression        = @"fb_like_button_impression";
NSString *const FBSDKAppEventNameFBSDKLoginButtonImpression       = @"fb_login_button_impression";
NSString *const FBSDKAppEventNameFBSDKSendButtonImpression        = @"fb_send_button_impression";
NSString *const FBSDKAppEventNameFBSDKShareButtonImpression       = @"fb_share_button_impression";

NSString *const FBSDKAppEventNameFBSDKSmartLoginService      = @"fb_smart_login_service";

NSString *const FBSDKAppEventNameFBSDKLikeButtonDidTap  = @"fb_like_button_did_tap";
NSString *const FBSDKAppEventNameFBSDKLoginButtonDidTap  = @"fb_login_button_did_tap";
NSString *const FBSDKAppEventNameFBSDKSendButtonDidTap  = @"fb_send_button_did_tap";
NSString *const FBSDKAppEventNameFBSDKShareButtonDidTap  = @"fb_share_button_did_tap";

NSString *const FBSDKAppEventNameFBSDKLikeControlDidDisable          = @"fb_like_control_did_disable";
NSString *const FBSDKAppEventNameFBSDKLikeControlDidLike             = @"fb_like_control_did_like";
NSString *const FBSDKAppEventNameFBSDKLikeControlDidPresentDialog    = @"fb_like_control_did_present_dialog";
NSString *const FBSDKAppEventNameFBSDKLikeControlDidTap              = @"fb_like_control_did_tap";
NSString *const FBSDKAppEventNameFBSDKLikeControlDidUnlike           = @"fb_like_control_did_unlike";
NSString *const FBSDKAppEventNameFBSDKLikeControlError               = @"fb_like_control_error";
NSString *const FBSDKAppEventNameFBSDKLikeControlImpression          = @"fb_like_control_impression";
NSString *const FBSDKAppEventNameFBSDKLikeControlNetworkUnavailable  = @"fb_like_control_network_unavailable";

NSString *const FBSDLAppEventNameFBSDKEventShareDialogResult =              @"fb_dialog_share_result";
NSString *const FBSDKAppEventNameFBSDKEventMessengerShareDialogResult =     @"fb_messenger_dialog_share_result";
NSString *const FBSDKAppEventNameFBSDKEventAppInviteShareDialogResult =     @"fb_app_invite_dialog_share_result";

NSString *const FBSDKAppEventNameFBSDKEventShareDialogShow =            @"fb_dialog_share_show";
NSString *const FBSDKAppEventNameFBSDKEventMessengerShareDialogShow =   @"fb_messenger_dialog_share_show";
NSString *const FBSDKAppEventNameFBSDKEventAppInviteShareDialogShow =   @"fb_app_invite_share_show";

NSString *const FBSDKAppEventNameFBSessionFASLoginDialogResult = @"fb_mobile_login_fas_dialog_result";

// Event Parameters internal to this file
NSString *const FBSDKAppEventParameterDialogOutcome               = @"fb_dialog_outcome";
NSString *const FBSDKAppEventParameterDialogErrorMessage          = @"fb_dialog_outcome_error_message";
NSString *const FBSDKAppEventParameterDialogMode                  = @"fb_dialog_mode";
NSString *const FBSDKAppEventParameterDialogShareContentType      = @"fb_dialog_share_content_type";
NSString *const FBSDKAppEventParameterShareTrayActivityName       = @"fb_share_tray_activity";
NSString *const FBSDKAppEventParameterShareTrayResult             = @"fb_share_tray_result";
NSString *const FBSDKAppEventParameterLogTime = @"_logTime";
NSString *const FBSDKAppEventParameterEventName = @"_eventName";
NSString *const FBSDKAppEventParameterImplicitlyLogged = @"_implicitlyLogged";

// Event parameter values internal to this file
NSString *const FBSDKAppEventsDialogOutcomeValue_Completed = @"Completed";
NSString *const FBSDKAppEventsDialogOutcomeValue_Cancelled = @"Cancelled";
NSString *const FBSDKAppEventsDialogOutcomeValue_Failed    = @"Failed";

NSString *const FBSDKAppEventsDialogShareModeAutomatic      = @"Automatic";
NSString *const FBSDKAppEventsDialogShareModeBrowser        = @"Browser";
NSString *const FBSDKAppEventsDialogShareModeNative         = @"Native";
NSString *const FBSDKAppEventsDialogShareModeShareSheet     = @"ShareSheet";
NSString *const FBSDKAppEventsDialogShareModeWeb            = @"Web";
NSString *const FBSDKAppEventsDialogShareModeFeedBrowser    = @"FeedBrowser";
NSString *const FBSDKAppEventsDialogShareModeFeedWeb        = @"FeedWeb";
NSString *const FBSDKAppEventsDialogShareModeUnknown        = @"Unknown";

NSString *const FBSDKAppEventsDialogShareContentTypeOpenGraph       = @"OpenGraph";
NSString *const FBSDKAppEventsDialogShareContentTypeStatus          = @"Status";
NSString *const FBSDKAppEventsDialogShareContentTypePhoto           = @"Photo";
NSString *const FBSDKAppEventsDialogShareContentTypeVideo           = @"Video";
NSString *const FBSDKAppEventsDialogShareContentTypeUnknown         = @"Unknown";

NSString *const FBSDKAppEventsLoggingResultNotification = @"com.facebook.sdk:FBSDKAppEventsLoggingResultNotification";

NSString *const FBSDKAppEventsOverrideAppIDBundleKey = @"FacebookLoggingOverrideAppID";

//
// Push Notifications
// Activities Endpoint Parameter
static NSString *const FBSDKActivitesParameterPushDeviceToken = @"device_token";
// Event Name
static NSString *const FBSDKAppEventNamePushOpened = @"fb_mobile_push_opened";
// Event Parameter
static NSString *const FBSDKAppEventParameterPushCampaign = @"fb_push_campaign";
static NSString *const FBSDKAppEventParameterPushAction = @"fb_push_action";
// Payload Keys
static NSString *const FBSDKAppEventsPushPayloadKey = @"fb_push_payload";
static NSString *const FBSDKAppEventsPushPayloadCampaignKey = @"campaign";

#define NUM_LOG_EVENTS_TO_TRY_TO_FLUSH_AFTER 100
#define FLUSH_PERIOD_IN_SECONDS 15
#define APP_SUPPORTS_ATTRIBUTION_ID_RECHECK_PERIOD 60 * 60 * 24
#define USER_ID_USER_DEFAULTS_KEY @"com.facebook.sdk.appevents.userid"

static NSString *g_overrideAppID = nil;

@interface FBSDKAppEvents ()

@property (nonatomic, readwrite) FBSDKAppEventsFlushBehavior flushBehavior;
//for testing only.
@property (nonatomic, assign) BOOL disableTimer;

@property (nonatomic, copy) NSString *pushNotificationsDeviceTokenString;

@end

@implementation FBSDKAppEvents
{
  BOOL _explicitEventsLoggedYet;
  NSTimer *_flushTimer;
  NSTimer *_attributionIDRecheckTimer;
  FBSDKServerConfiguration *_serverConfiguration;
  FBSDKAppEventsState *_appEventsState;
  NSString *_userID;
}

#pragma mark - Object Lifecycle

+ (void)initialize
{
  if (self == [FBSDKAppEvents class]) {
    g_overrideAppID = [[[NSBundle mainBundle] objectForInfoDictionaryKey:FBSDKAppEventsOverrideAppIDBundleKey] copy];
  }
}

- (FBSDKAppEvents *)init
{
  self = [super init];
  if (self) {
    _flushBehavior = FBSDKAppEventsFlushBehaviorAuto;
    _flushTimer = [NSTimer timerWithTimeInterval:FLUSH_PERIOD_IN_SECONDS
                                          target:self
                                        selector:@selector(flushTimerFired:)
                                        userInfo:nil
                                         repeats:YES];
    _attributionIDRecheckTimer = [NSTimer timerWithTimeInterval:APP_SUPPORTS_ATTRIBUTION_ID_RECHECK_PERIOD
                                                         target:self
                                                       selector:@selector(appSettingsFetchStateResetTimerFired:)
                                                       userInfo:nil
                                                        repeats:YES];
    [[NSRunLoop mainRunLoop] addTimer:_flushTimer forMode:NSDefaultRunLoopMode];
    [[NSRunLoop mainRunLoop] addTimer:_attributionIDRecheckTimer forMode:NSDefaultRunLoopMode];
    [[NSNotificationCenter defaultCenter]
     addObserver:self
     selector:@selector(applicationMovingFromActiveStateOrTerminating)
     name:UIApplicationWillResignActiveNotification
     object:NULL];

    [[NSNotificationCenter defaultCenter]
     addObserver:self
     selector:@selector(applicationMovingFromActiveStateOrTerminating)
     name:UIApplicationWillTerminateNotification
     object:NULL];

    [[NSNotificationCenter defaultCenter]
     addObserver:self
     selector:@selector(applicationDidBecomeActive)
     name:UIApplicationDidBecomeActiveNotification
     object:NULL];

    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    _userID = [defaults stringForKey:USER_ID_USER_DEFAULTS_KEY];
  }

  return self;
}

- (void)dealloc
{
  [[NSNotificationCenter defaultCenter] removeObserver:self];
  // technically these timers retain self so there's a cycle but
  // we're a singleton anyway.
  [_flushTimer invalidate];
  [_attributionIDRecheckTimer invalidate];
}

#pragma mark - Public Methods

+ (void)logEvent:(NSString *)eventName
{
  [FBSDKAppEvents logEvent:eventName
                parameters:nil];
}

+ (void)logEvent:(NSString *)eventName
      valueToSum:(double)valueToSum
{
  [FBSDKAppEvents logEvent:eventName
                valueToSum:valueToSum
                parameters:nil];
}

+ (void)logEvent:(NSString *)eventName
      parameters:(NSDictionary *)parameters
{
  [FBSDKAppEvents logEvent:eventName
                valueToSum:nil
                parameters:parameters
               accessToken:nil];
}

+ (void)logEvent:(NSString *)eventName
      valueToSum:(double)valueToSum
      parameters:(NSDictionary *)parameters
{
  [FBSDKAppEvents logEvent:eventName
                valueToSum:[NSNumber numberWithDouble:valueToSum]
                parameters:parameters
               accessToken:nil];
}

+ (void)logEvent:(NSString *)eventName
      valueToSum:(NSNumber *)valueToSum
      parameters:(NSDictionary *)parameters
     accessToken:(FBSDKAccessToken *)accessToken
{
  [[FBSDKAppEvents singleton] instanceLogEvent:eventName
                                    valueToSum:valueToSum
                                    parameters:parameters
                            isImplicitlyLogged:NO
                                   accessToken:accessToken];
}

+ (void)logPurchase:(double)purchaseAmount
           currency:(NSString *)currency
{
  [FBSDKAppEvents logPurchase:purchaseAmount
                     currency:currency
                   parameters:nil];
}

+ (void)logPurchase:(double)purchaseAmount
           currency:(NSString *)currency
         parameters:(NSDictionary *)parameters
{
  [FBSDKAppEvents logPurchase:purchaseAmount
                     currency:currency
                   parameters:parameters
                  accessToken:nil];
}

+ (void)logPurchase:(double)purchaseAmount
           currency:(NSString *)currency
         parameters:(NSDictionary *)parameters
        accessToken:(FBSDKAccessToken *)accessToken
{

  // A purchase event is just a regular logged event with a given event name
  // and treating the currency value as going into the parameters dictionary.
  NSDictionary *newParameters;
  if (!parameters) {
    newParameters = @{ FBSDKAppEventParameterNameCurrency : currency };
  } else {
    newParameters = [NSMutableDictionary dictionaryWithDictionary:parameters];
    [newParameters setValue:currency forKey:FBSDKAppEventParameterNameCurrency];
  }

  [FBSDKAppEvents logEvent:FBSDKAppEventNamePurchased
                valueToSum:[NSNumber numberWithDouble:purchaseAmount]
                parameters:newParameters
               accessToken:accessToken];

  // Unless the behavior is set to only allow explicit flushing, we go ahead and flush, since purchase events
  // are relatively rare and relatively high value and worth getting across on wire right away.
  if ([FBSDKAppEvents flushBehavior] != FBSDKAppEventsFlushBehaviorExplicitOnly) {
    [[FBSDKAppEvents singleton] flushForReason:FBSDKAppEventsFlushReasonEagerlyFlushingEvent];
  }
}

/*
 * Push Notifications Logging
 */

+ (void)logPushNotificationOpen:(NSDictionary *)payload
{
  [self logPushNotificationOpen:payload action:nil];
}

+ (void)logPushNotificationOpen:(NSDictionary *)payload action:(NSString *)action
{
  NSDictionary *facebookPayload = payload[FBSDKAppEventsPushPayloadKey];
  if (!facebookPayload) {
    return;
  }
  NSString *campaign = facebookPayload[FBSDKAppEventsPushPayloadCampaignKey];
  if (campaign.length == 0) {
    [FBSDKLogger singleShotLogEntry:FBSDKLoggingBehaviorDeveloperErrors
                           logEntry:@"Malformed payload specified for logging a push notification open."];
    return;
  }

  NSMutableDictionary *parameters = [NSMutableDictionary dictionaryWithObject:campaign forKey:FBSDKAppEventParameterPushCampaign];
  if (action) {
    parameters[FBSDKAppEventParameterPushAction] = action;
  }
  [self logEvent:FBSDKAppEventNamePushOpened parameters:parameters];
}

+ (void)activateApp
{
  [FBSDKAppEventsUtility ensureOnMainThread:NSStringFromSelector(_cmd) className:NSStringFromClass(self)];

  // Fetch app settings and register for transaction notifications only if app supports implicit purchase
  // events
  FBSDKAppEvents *instance = [FBSDKAppEvents singleton];
  [instance publishInstall];
  [instance fetchServerConfiguration:NULL];

  // Restore time spent data, indicating that we're being called from "activateApp", which will,
  // when appropriate, result in logging an "activated app" and "deactivated app" (for the
  // previous session) App Event.
  [FBSDKTimeSpentData restore:YES];
}

+ (void)setPushNotificationsDeviceToken:(NSData *)deviceToken
{
  [FBSDKAppEvents singleton].pushNotificationsDeviceTokenString = [FBSDKInternalUtility hexadecimalStringFromData:deviceToken];
}

+ (FBSDKAppEventsFlushBehavior)flushBehavior
{
  return [FBSDKAppEvents singleton].flushBehavior;
}

+ (void)setFlushBehavior:(FBSDKAppEventsFlushBehavior)flushBehavior
{
  [FBSDKAppEvents singleton].flushBehavior = flushBehavior;
}

+ (NSString *)loggingOverrideAppID
{
  return g_overrideAppID;
}

+ (void)setLoggingOverrideAppID:(NSString *)appID
{
  if (![g_overrideAppID isEqualToString:appID]) {
    FBSDKConditionalLog(![FBSDKAppEvents singleton]->_explicitEventsLoggedYet,
                        FBSDKLoggingBehaviorDeveloperErrors,
                        @"[FBSDKAppEvents setLoggingOverrideAppID:] should only be called prior to any events being logged.");
    g_overrideAppID = appID;
  }
}

+ (void)flush
{
  [[FBSDKAppEvents singleton] flushForReason:FBSDKAppEventsFlushReasonExplicit];
}

+ (void)setUserID:(NSString *)userID
{
  if ([[[self class] singleton]->_userID isEqualToString:userID]) {
    return;
  }
  [[self class] singleton]->_userID = userID;
  NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
  [defaults setObject:userID forKey:USER_ID_USER_DEFAULTS_KEY];
  [defaults synchronize];
}

+ (NSString *)userID
{
  return [[self class] singleton]->_userID;
}

+ (void)updateUserProperties:(NSDictionary *)properties handler:(FBSDKGraphRequestHandler)handler
{
  NSString *userID = [[self class] userID];

  if (userID.length == 0) {
    [FBSDKLogger singleShotLogEntry:FBSDKLoggingBehaviorDeveloperErrors logEntry:@"Missing [FBSDKAppEvents userID] for [FBSDKAppEvents updateUserProperties:]"];
    NSError *error = [FBSDKError requiredArgumentErrorWithName:@"userID" message:@"Missing [FBSDKAppEvents userID] for [FBSDKAppEvents updateUserProperties:]"];
    if (handler) {
      handler(nil, nil, error);
    }
    return;
  }
  NSMutableDictionary *dataDictionary = [NSMutableDictionary dictionaryWithCapacity:3];
  dataDictionary[@"user_unique_id"] = [FBSDKAppEvents userID];
  [FBSDKInternalUtility dictionary:dataDictionary setObject:[FBSDKAppEventsUtility advertiserID] forKey:@"advertiser_id"];
  [FBSDKInternalUtility dictionary:dataDictionary setObject:properties forKey:@"custom_data"];

  NSError *error;
  __block NSError *invalidObjectError;
  NSString *dataJSONString = [FBSDKInternalUtility JSONStringForObject:@[dataDictionary] error:&error invalidObjectHandler:^id(id object, BOOL *stop) {
    *stop = YES;
    invalidObjectError = [FBSDKError unknownErrorWithMessage:@"The values in the properties dictionary must be NSStrings or NSNumbers"];
    return nil;
  }];
  if (!error) {
    error = invalidObjectError;
  }
  if (error) {
    [FBSDKLogger singleShotLogEntry:FBSDKLoggingBehaviorDeveloperErrors logEntry:@"Failed to serialize properties for [FBSDKAppEvents updateUserProperties:]"];
    if (handler) {
      handler(nil, nil, error);
    }
    return;
  }
  NSDictionary *params = @{ @"data" : dataJSONString };
  FBSDKGraphRequest *request = [[FBSDKGraphRequest alloc] initWithGraphPath:[NSString stringWithFormat:@"%@/user_properties", [FBSDKSettings appID]]
                                                                 parameters:params
                                                                tokenString:[FBSDKAccessToken currentAccessToken].tokenString
                                                                 HTTPMethod:@"POST"
                                                                      flags:FBSDKGraphRequestFlagDisableErrorRecovery |
                                                                            FBSDKGraphRequestFlagDoNotInvalidateTokenOnError |
                                                                            FBSDKGraphRequestFlagSkipClientToken
                                ];
  [request startWithCompletionHandler:handler];
}

#pragma mark - Internal Methods

+ (void)logImplicitEvent:(NSString *)eventName
              valueToSum:(NSNumber *)valueToSum
              parameters:(NSDictionary *)parameters
             accessToken:(FBSDKAccessToken *)accessToken
{
  [[FBSDKAppEvents singleton] instanceLogEvent:eventName
                                    valueToSum:valueToSum
                                    parameters:parameters
                            isImplicitlyLogged:YES
                                   accessToken:accessToken];
}

+ (FBSDKAppEvents *)singleton
{
  static dispatch_once_t pred;
  static FBSDKAppEvents *shared = nil;

  dispatch_once(&pred, ^{
      shared = [[FBSDKAppEvents alloc] init];
    });
  return shared;
}

- (void)flushForReason:(FBSDKAppEventsFlushReason)flushReason
{
  // Always flush asynchronously, even on main thread, for two reasons:
  // - most consistent code path for all threads.
  // - allow locks being held by caller to be released prior to actual flushing work being done.
  @synchronized (self) {
    if (!_appEventsState) {
      return;
    }
    FBSDKAppEventsState *copy = [_appEventsState copy];
    _appEventsState = [[FBSDKAppEventsState alloc] initWithToken:copy.tokenString
                                                           appID:copy.appID];
    dispatch_async(dispatch_get_main_queue(), ^{
      [self flushOnMainQueue:copy forReason:flushReason];
    });
  }
}

#pragma mark - Private Methods
- (NSString *)appID
{
  return [FBSDKAppEvents loggingOverrideAppID] ?: [FBSDKSettings appID];
}

- (void)publishInstall
{
  NSString *appID = [self appID];
  NSString *lastAttributionPingString = [NSString stringWithFormat:@"com.facebook.sdk:lastAttributionPing%@", appID];
  NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
  if ([defaults objectForKey:lastAttributionPingString]) {
    return;
  }
  [self fetchServerConfiguration:^{
    NSDictionary *params = [FBSDKAppEventsUtility activityParametersDictionaryForEvent:@"MOBILE_APP_INSTALL"
                                                                    implicitEventsOnly:NO
                                                             shouldAccessAdvertisingID:_serverConfiguration.isAdvertisingIDEnabled];
    NSString *path = [NSString stringWithFormat:@"%@/activities", appID];
    FBSDKGraphRequest *request = [[FBSDKGraphRequest alloc] initWithGraphPath:path
                                                         parameters:params
                                                        tokenString:nil
                                                         HTTPMethod:@"POST"
                                                              flags:FBSDKGraphRequestFlagDoNotInvalidateTokenOnError | FBSDKGraphRequestFlagDisableErrorRecovery];
    [request startWithCompletionHandler:^(FBSDKGraphRequestConnection *connection, id result, NSError *error) {
      if (!error) {
        [defaults setObject:[NSDate date] forKey:lastAttributionPingString];
        NSString *lastInstallResponseKey = [NSString stringWithFormat:@"com.facebook.sdk:lastInstallResponse%@", appID];
        [defaults setObject:result forKey:lastInstallResponseKey];
        [defaults synchronize];
      }
    }];
  }];
}

// app events can use a server configuration up to 24 hours old to minimize network traffic.
- (void)fetchServerConfiguration:(void (^)(void))callback
{
  if (_serverConfiguration == nil) {
    [FBSDKServerConfigurationManager loadServerConfigurationWithCompletionBlock:^(FBSDKServerConfiguration *serverConfiguration, NSError *error) {
      _serverConfiguration = serverConfiguration;

      if (_serverConfiguration.implicitPurchaseLoggingEnabled) {
        [FBSDKPaymentObserver startObservingTransactions];
      } else {
        [FBSDKPaymentObserver stopObservingTransactions];
      }
      if (callback) {
        callback();
      }
    }];
    return;
  }
  if (callback) {
    callback();
  }
}

- (void)instanceLogEvent:(NSString *)eventName
              valueToSum:(NSNumber *)valueToSum
              parameters:(NSDictionary *)parameters
      isImplicitlyLogged:(BOOL)isImplicitlyLogged
             accessToken:(FBSDKAccessToken *)accessToken
{
  if (isImplicitlyLogged && _serverConfiguration && !_serverConfiguration.isImplicitLoggingSupported) {
    return;
  }

  if (!isImplicitlyLogged && !_explicitEventsLoggedYet) {
    _explicitEventsLoggedYet = YES;
  }

  __block BOOL failed = NO;

  if (![FBSDKAppEventsUtility validateIdentifier:eventName]) {
    failed = YES;
  }

  // Make sure parameter dictionary is well formed.  Log and exit if not.
  [parameters enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
      if (![key isKindOfClass:[NSString class]]) {
        [FBSDKAppEventsUtility logAndNotify:[NSString stringWithFormat:@"The keys in the parameters must be NSStrings, '%@' is not.", key]];
        failed = YES;
      }
      if (![FBSDKAppEventsUtility validateIdentifier:key]) {
        failed = YES;
      }
      if (![obj isKindOfClass:[NSString class]] && ![obj isKindOfClass:[NSNumber class]]) {
        [FBSDKAppEventsUtility logAndNotify:[NSString stringWithFormat:@"The values in the parameters dictionary must be NSStrings or NSNumbers, '%@' is not.", obj]];
        failed = YES;
      }
    }
   ];

  if (failed) {
    return;
  }

  NSMutableDictionary *eventDictionary = [NSMutableDictionary dictionaryWithDictionary:parameters];
  eventDictionary[FBSDKAppEventParameterEventName] = eventName;
  if (!eventDictionary[FBSDKAppEventParameterLogTime]) {
    eventDictionary[FBSDKAppEventParameterLogTime] = @([FBSDKAppEventsUtility unixTimeNow]);
  }
  [FBSDKInternalUtility dictionary:eventDictionary setObject:valueToSum forKey:@"_valueToSum"];
  if (isImplicitlyLogged) {
    eventDictionary[FBSDKAppEventParameterImplicitlyLogged] = @"1";
  }
  [FBSDKInternalUtility dictionary:eventDictionary setObject:_userID forKey:@"_app_user_id"];

  NSString *currentViewControllerName;
  if ([NSThread isMainThread]) {
    // We only collect the view controller when on the main thread, as the behavior off
    // the main thread is unpredictable.  Besides, UI state for off-main-thread computations
    // isn't really relevant anyhow.
    UIViewController *vc = [UIApplication sharedApplication].keyWindow.rootViewController.presentedViewController;
    if (vc) {
      currentViewControllerName = [[vc class] description];
    } else {
      currentViewControllerName = @"no_ui";
    }
  } else {
    currentViewControllerName = @"off_thread";
  }
  eventDictionary[@"_ui"] = currentViewControllerName;

  NSString *tokenString = [FBSDKAppEventsUtility tokenStringToUseFor:accessToken];
  NSString *appID = [self appID];

  @synchronized (self) {
    if (!_appEventsState) {
      _appEventsState = [[FBSDKAppEventsState alloc] initWithToken:tokenString appID:appID];
    } else if (![_appEventsState isCompatibleWithTokenString:tokenString appID:appID]) {
      if (self.flushBehavior == FBSDKAppEventsFlushBehaviorExplicitOnly) {
        [FBSDKAppEventsStateManager persistAppEventsData:_appEventsState];
      } else {
        [self flushForReason:FBSDKAppEventsFlushReasonSessionChange];
      }
      _appEventsState = [[FBSDKAppEventsState alloc] initWithToken:tokenString appID:appID];
    }

    [_appEventsState addEvent:eventDictionary isImplicit:isImplicitlyLogged];
    if (!isImplicitlyLogged) {
      [FBSDKLogger singleShotLogEntry:FBSDKLoggingBehaviorAppEvents
                         formatString:@"FBSDKAppEvents: Recording event @ %ld: %@",
       [FBSDKAppEventsUtility unixTimeNow],
       eventDictionary];
    }

    [self checkPersistedEvents];

    if (_appEventsState.events.count > NUM_LOG_EVENTS_TO_TRY_TO_FLUSH_AFTER &&
        self.flushBehavior != FBSDKAppEventsFlushBehaviorExplicitOnly) {
      [self flushForReason:FBSDKAppEventsFlushReasonEventThreshold];
    }
  }
}

// this fetches persisted event states.
// for those matching the currently tracked events, add it.
// otherwise, either flush (if not explicitonly behavior) or persist them back.
- (void)checkPersistedEvents
{
  NSArray *existingEventsStates = [FBSDKAppEventsStateManager retrievePersistedAppEventsStates];
  if (existingEventsStates.count == 0) {
    return;
  }
  FBSDKAppEventsState *matchingEventsPreviouslySaved = nil;
  // reduce lock time by creating a new FBSDKAppEventsState to collect matching persisted events.
  @synchronized(self) {
    if (_appEventsState) {
      matchingEventsPreviouslySaved = [[FBSDKAppEventsState alloc] initWithToken:_appEventsState.tokenString
                                                  appID:_appEventsState.appID];
    }
  }
  for (FBSDKAppEventsState *saved in existingEventsStates) {
    if ([saved isCompatibleWithAppEventsState:matchingEventsPreviouslySaved]) {
      [matchingEventsPreviouslySaved addEventsFromAppEventState:saved];
    } else {
      if (self.flushBehavior == FBSDKAppEventsFlushBehaviorExplicitOnly) {
        [FBSDKAppEventsStateManager persistAppEventsData:saved];
      } else {
        dispatch_async(dispatch_get_main_queue(), ^{
          [self flushOnMainQueue:saved forReason:FBSDKAppEventsFlushReasonPersistedEvents];
        });
      }
    }
  }
  if (matchingEventsPreviouslySaved.events.count > 0) {
    @synchronized(self) {
      if ([_appEventsState isCompatibleWithAppEventsState:matchingEventsPreviouslySaved]) {
        [_appEventsState addEventsFromAppEventState:matchingEventsPreviouslySaved];
      }
    }
  }
}

- (void)flushOnMainQueue:(FBSDKAppEventsState *)appEventsState
               forReason:(FBSDKAppEventsFlushReason)reason
{
  if (appEventsState.events.count == 0) {
    return;
  }
  [FBSDKAppEventsUtility ensureOnMainThread:NSStringFromSelector(_cmd) className:NSStringFromClass([self class])];

  [self fetchServerConfiguration:^(void) {
    NSString *JSONString = [appEventsState JSONStringForEvents:_serverConfiguration.implicitLoggingEnabled];
    NSData *encodedEvents = [JSONString dataUsingEncoding:NSUTF8StringEncoding];
    if (!encodedEvents) {
      [FBSDKLogger singleShotLogEntry:FBSDKLoggingBehaviorAppEvents
                             logEntry:@"FBSDKAppEvents: Flushing skipped - no events after removing implicitly logged ones.\n"];
      return;
    }
    NSMutableDictionary *postParameters = [FBSDKAppEventsUtility
                                           activityParametersDictionaryForEvent:@"CUSTOM_APP_EVENTS"
                                           implicitEventsOnly:appEventsState.areAllEventsImplicit
                                           shouldAccessAdvertisingID:_serverConfiguration.advertisingIDEnabled];
    postParameters[@"custom_events_file"] = encodedEvents;
    if (appEventsState.numSkipped > 0) {
      postParameters[@"num_skipped_events"] = [NSString stringWithFormat:@"%lu", (unsigned long)appEventsState.numSkipped];
    }
    if (self.pushNotificationsDeviceTokenString) {
      postParameters[FBSDKActivitesParameterPushDeviceToken] = self.pushNotificationsDeviceTokenString;
    }

    NSString *loggingEntry = nil;
    if ([[FBSDKSettings loggingBehavior] containsObject:FBSDKLoggingBehaviorAppEvents]) {
      NSData *prettyJSONData = [NSJSONSerialization dataWithJSONObject:appEventsState.events
                                                               options:NSJSONWritingPrettyPrinted
                                                                 error:NULL];
      NSString *prettyPrintedJsonEvents = [[NSString alloc] initWithData:prettyJSONData
                                                                encoding:NSUTF8StringEncoding];
      // Remove this param -- just an encoding of the events which we pretty print later.
      NSMutableDictionary *paramsForPrinting = [postParameters mutableCopy];
      [paramsForPrinting removeObjectForKey:@"custom_events_file"];

      loggingEntry = [NSString stringWithFormat:@"FBSDKAppEvents: Flushed @ %ld, %lu events due to '%@' - %@\nEvents: %@",
                      [FBSDKAppEventsUtility unixTimeNow],
                      (unsigned long)appEventsState.events.count,
                      [FBSDKAppEventsUtility flushReasonToString:reason],
                      paramsForPrinting,
                      prettyPrintedJsonEvents];
    }

    FBSDKGraphRequest *request = [[FBSDKGraphRequest alloc] initWithGraphPath:[NSString stringWithFormat:@"%@/activities", appEventsState.appID]
                                                         parameters:postParameters
                                                        tokenString:appEventsState.tokenString
                                                         HTTPMethod:@"POST"
                                                              flags:FBSDKGraphRequestFlagDoNotInvalidateTokenOnError | FBSDKGraphRequestFlagDisableErrorRecovery];

    [request startWithCompletionHandler:^(FBSDKGraphRequestConnection *connection, id result, NSError *error) {
      [self handleActivitiesPostCompletion:error
                              loggingEntry:loggingEntry
                            appEventsState:(FBSDKAppEventsState *)appEventsState];
    }];

  }];
}

- (void)handleActivitiesPostCompletion:(NSError *)error
                          loggingEntry:(NSString *)loggingEntry
                        appEventsState:(FBSDKAppEventsState *)appEventsState
{
  typedef NS_ENUM(NSUInteger, FBSDKAppEventsFlushResult) {
    FlushResultSuccess,
    FlushResultServerError,
    FlushResultNoConnectivity
  };

  [FBSDKAppEventsUtility ensureOnMainThread:NSStringFromSelector(_cmd) className:NSStringFromClass([self class])];

  FBSDKAppEventsFlushResult flushResult = FlushResultSuccess;
  if (error) {
    NSInteger errorCode = [error.userInfo[FBSDKGraphRequestErrorHTTPStatusCodeKey] integerValue];

    // We interpret a 400 coming back from FBRequestConnection as a server error due to improper data being
    // sent down.  Otherwise we assume no connectivity, or another condition where we could treat it as no connectivity.
    flushResult = errorCode == 400 ? FlushResultServerError : FlushResultNoConnectivity;
  }

  if (flushResult == FlushResultServerError) {
    // Only log events that developer can do something with (i.e., if parameters are incorrect).
    //  as opposed to cases where the token is bad.
    if ([error.userInfo[FBSDKGraphRequestErrorCategoryKey] unsignedIntegerValue] == FBSDKGraphRequestErrorCategoryOther) {
      NSString *message = [NSString stringWithFormat:@"Failed to send AppEvents: %@", error];
      [FBSDKAppEventsUtility logAndNotify:message allowLogAsDeveloperError:!appEventsState.areAllEventsImplicit];
    }
  } else if (flushResult == FlushResultNoConnectivity) {
    @synchronized(self) {
      if ([appEventsState isCompatibleWithAppEventsState:_appEventsState]) {
        [_appEventsState addEventsFromAppEventState:appEventsState];
      } else {
        // flush failed due to connectivity. Persist to be tried again later.
        [FBSDKAppEventsStateManager persistAppEventsData:appEventsState];
      }
    }
  }

  NSString *resultString = @"<unknown>";
  switch (flushResult) {
    case FlushResultSuccess:
      resultString = @"Success";
      break;

    case FlushResultNoConnectivity:
      resultString = @"No Connectivity";
      break;

    case FlushResultServerError:
      resultString = [NSString stringWithFormat:@"Server Error - %@", [error description]];
      break;
  }

  [FBSDKLogger singleShotLogEntry:FBSDKLoggingBehaviorAppEvents
                     formatString:@"%@\nFlush Result : %@", loggingEntry, resultString];
}

- (void)flushTimerFired:(id)arg
{
  [FBSDKAppEventsUtility ensureOnMainThread:NSStringFromSelector(_cmd) className:NSStringFromClass([self class])];
  if (self.flushBehavior != FBSDKAppEventsFlushBehaviorExplicitOnly && !self.disableTimer) {
    [self flushForReason:FBSDKAppEventsFlushReasonTimer];
  }
}

- (void)appSettingsFetchStateResetTimerFired:(id)arg
{
  _serverConfiguration = nil;
}

- (void)applicationDidBecomeActive
{
  [FBSDKAppEventsUtility ensureOnMainThread:NSStringFromSelector(_cmd) className:NSStringFromClass([self class])];

  [self checkPersistedEvents];

  // Restore time spent data, indicating that we're not being called from "activateApp".
  [FBSDKTimeSpentData restore:NO];
}

- (void)applicationMovingFromActiveStateOrTerminating
{
  // When moving from active state, we don't have time to wait for the result of a flush, so
  // just persist events to storage, and we'll process them at the next activation.
  FBSDKAppEventsState *copy = nil;
  @synchronized (self) {
    copy = [_appEventsState copy];
    _appEventsState = nil;
  }
  if (copy) {
    [FBSDKAppEventsStateManager persistAppEventsData:copy];
  }
  [FBSDKTimeSpentData suspend];
}

#pragma mark - Custom Audience

+ (FBSDKGraphRequest *)requestForCustomAudienceThirdPartyIDWithAccessToken:(FBSDKAccessToken *)accessToken
{
  accessToken = accessToken ?: [FBSDKAccessToken currentAccessToken];
  // Rules for how we use the attribution ID / advertiser ID for an 'custom_audience_third_party_id' Graph API request
  // 1) if the OS tells us that the user has Limited Ad Tracking, then just don't send, and return a nil in the token.
  // 2) if the app has set 'limitEventAndDataUsage', this effectively implies that app-initiated ad targeting shouldn't happen,
  //    so use that data here to return nil as well.
  // 3) if we have a user session token, then no need to send attribution ID / advertiser ID back as the udid parameter
  // 4) otherwise, send back the udid parameter.

  if ([FBSDKAppEventsUtility advertisingTrackingStatus] == FBSDKAdvertisingTrackingDisallowed || [FBSDKSettings limitEventAndDataUsage]) {
    return nil;
  }

  NSString *tokenString = [FBSDKAppEventsUtility tokenStringToUseFor:accessToken];
  NSString *udid = nil;
  if (!accessToken) {
    // We don't have a logged in user, so we need some form of udid representation.  Prefer advertiser ID if
    // available, and back off to attribution ID if not.  Note that this function only makes sense to be
    // called in the context of advertising.
    udid = [FBSDKAppEventsUtility advertiserID];
    if (!udid) {
      udid = [FBSDKAppEventsUtility attributionID];
    }

    if (!udid) {
      // No udid, and no user token.  No point in making the request.
      return nil;
    }
  }

  NSDictionary *parameters = nil;
  if (udid) {
    parameters = @{ @"udid" : udid };
  }

  NSString *graphPath = [NSString stringWithFormat:@"%@/custom_audience_third_party_id", [[self singleton] appID]];
  FBSDKGraphRequest *request = [[FBSDKGraphRequest alloc] initWithGraphPath:graphPath
                                                       parameters:parameters
                                                      tokenString:tokenString
                                                       HTTPMethod:nil
                                                            flags:FBSDKGraphRequestFlagDoNotInvalidateTokenOnError | FBSDKGraphRequestFlagDisableErrorRecovery];

  return request;
}

@end
