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

#import <StoreKit/StoreKit.h>
#import <UIKit/UIApplication.h>

#import <objc/runtime.h>

#import "FBSDKAEMReporter.h"
#import "FBSDKAccessToken.h"
#import "FBSDKAppEventsAtePublisher.h"
#import "FBSDKAppEventsConfiguration.h"
#import "FBSDKAppEventsConfigurationProviding.h"
#import "FBSDKAppEventsDeviceInfo.h"
#import "FBSDKAppEventsState.h"
#import "FBSDKAppEventsStateManager.h"
#import "FBSDKAppEventsUtility.h"
#import "FBSDKApplicationDelegate+Internal.h"
#import "FBSDKCodelessIndexer.h"
#import "FBSDKConstants.h"
#import "FBSDKCoreKitBasicsImport.h"
#import "FBSDKDataPersisting.h"
#import "FBSDKDynamicFrameworkLoader.h"
#import "FBSDKError.h"
#import "FBSDKEventDeactivationManager.h"
#import "FBSDKFeatureChecking.h"
#import "FBSDKGateKeeperManaging.h"
#import "FBSDKGraphRequestProtocol.h"
#import "FBSDKGraphRequestProviding.h"
#import "FBSDKInternalUtility.h"
#import "FBSDKLogger.h"
#import "FBSDKLogging.h"
#import "FBSDKMetadataIndexer.h"
#import "FBSDKPaymentObserving.h"
#import "FBSDKRestrictiveDataFilterManager.h"
#import "FBSDKSKAdNetworkReporter.h"
#import "FBSDKServerConfiguration.h"
#import "FBSDKServerConfigurationProviding.h"
#import "FBSDKSettingsProtocol.h"
#import "FBSDKTimeSpentData.h"
#import "FBSDKUtility.h"

#if !TARGET_OS_TV

 #import "FBSDKEventBindingManager.h"
 #import "FBSDKEventProcessing.h"
 #import "FBSDKHybridAppEventsScriptMessageHandler.h"
 #import "FBSDKIntegrityManager.h"

#endif

//
// Public event names
//

// General purpose
FBSDKAppEventName FBSDKAppEventNameCompletedRegistration = @"fb_mobile_complete_registration";
FBSDKAppEventName FBSDKAppEventNameViewedContent = @"fb_mobile_content_view";
FBSDKAppEventName FBSDKAppEventNameSearched = @"fb_mobile_search";
FBSDKAppEventName FBSDKAppEventNameRated = @"fb_mobile_rate";
FBSDKAppEventName FBSDKAppEventNameCompletedTutorial = @"fb_mobile_tutorial_completion";
FBSDKAppEventName FBSDKAppEventNameContact = @"Contact";
FBSDKAppEventName FBSDKAppEventNameCustomizeProduct = @"CustomizeProduct";
FBSDKAppEventName FBSDKAppEventNameDonate = @"Donate";
FBSDKAppEventName FBSDKAppEventNameFindLocation = @"FindLocation";
FBSDKAppEventName FBSDKAppEventNameSchedule = @"Schedule";
FBSDKAppEventName FBSDKAppEventNameStartTrial = @"StartTrial";
FBSDKAppEventName FBSDKAppEventNameSubmitApplication = @"SubmitApplication";
FBSDKAppEventName FBSDKAppEventNameSubscribe = @"Subscribe";
FBSDKAppEventName FBSDKAppEventNameSubscriptionHeartbeat = @"SubscriptionHeartbeat";
FBSDKAppEventName FBSDKAppEventNameAdImpression = @"AdImpression";
FBSDKAppEventName FBSDKAppEventNameAdClick = @"AdClick";

// Ecommerce related
FBSDKAppEventName FBSDKAppEventNameAddedToCart = @"fb_mobile_add_to_cart";
FBSDKAppEventName FBSDKAppEventNameAddedToWishlist = @"fb_mobile_add_to_wishlist";
FBSDKAppEventName FBSDKAppEventNameInitiatedCheckout = @"fb_mobile_initiated_checkout";
FBSDKAppEventName FBSDKAppEventNameAddedPaymentInfo = @"fb_mobile_add_payment_info";
FBSDKAppEventName FBSDKAppEventNameProductCatalogUpdate = @"fb_mobile_catalog_update";
FBSDKAppEventName FBSDKAppEventNamePurchased = @"fb_mobile_purchase";

// Gaming related
FBSDKAppEventName FBSDKAppEventNameAchievedLevel = @"fb_mobile_level_achieved";
FBSDKAppEventName FBSDKAppEventNameUnlockedAchievement = @"fb_mobile_achievement_unlocked";
FBSDKAppEventName FBSDKAppEventNameSpentCredits = @"fb_mobile_spent_credits";

//
// Public event parameter names
//

FBSDKAppEventParameterName FBSDKAppEventParameterNameCurrency = @"fb_currency";
FBSDKAppEventParameterName FBSDKAppEventParameterNameRegistrationMethod = @"fb_registration_method";
FBSDKAppEventParameterName FBSDKAppEventParameterNameContentType = @"fb_content_type";
FBSDKAppEventParameterName FBSDKAppEventParameterNameContent = @"fb_content";
FBSDKAppEventParameterName FBSDKAppEventParameterNameContentID = @"fb_content_id";
FBSDKAppEventParameterName FBSDKAppEventParameterNameSearchString = @"fb_search_string";
FBSDKAppEventParameterName FBSDKAppEventParameterNameSuccess = @"fb_success";
FBSDKAppEventParameterName FBSDKAppEventParameterNameMaxRatingValue = @"fb_max_rating_value";
FBSDKAppEventParameterName FBSDKAppEventParameterNamePaymentInfoAvailable = @"fb_payment_info_available";
FBSDKAppEventParameterName FBSDKAppEventParameterNameNumItems = @"fb_num_items";
FBSDKAppEventParameterName FBSDKAppEventParameterNameLevel = @"fb_level";
FBSDKAppEventParameterName FBSDKAppEventParameterNameDescription = @"fb_description";
FBSDKAppEventParameterName FBSDKAppEventParameterLaunchSource = @"fb_mobile_launch_source";
FBSDKAppEventParameterName FBSDKAppEventParameterNameAdType = @"ad_type";
FBSDKAppEventParameterName FBSDKAppEventParameterNameOrderID = @"fb_order_id";

//
// Public event parameter names for DPA Catalog
//

FBSDKAppEventParameterProduct FBSDKAppEventParameterProductCustomLabel0 = @"fb_product_custom_label_0";
FBSDKAppEventParameterProduct FBSDKAppEventParameterProductCustomLabel1 = @"fb_product_custom_label_1";
FBSDKAppEventParameterProduct FBSDKAppEventParameterProductCustomLabel2 = @"fb_product_custom_label_2";
FBSDKAppEventParameterProduct FBSDKAppEventParameterProductCustomLabel3 = @"fb_product_custom_label_3";
FBSDKAppEventParameterProduct FBSDKAppEventParameterProductCustomLabel4 = @"fb_product_custom_label_4";
FBSDKAppEventParameterProduct FBSDKAppEventParameterProductCategory = @"fb_product_category";
FBSDKAppEventParameterProduct FBSDKAppEventParameterProductAppLinkIOSUrl = @"fb_product_applink_ios_url";
FBSDKAppEventParameterProduct FBSDKAppEventParameterProductAppLinkIOSAppStoreID = @"fb_product_applink_ios_app_store_id";
FBSDKAppEventParameterProduct FBSDKAppEventParameterProductAppLinkIOSAppName = @"fb_product_applink_ios_app_name";
FBSDKAppEventParameterProduct FBSDKAppEventParameterProductAppLinkIPhoneUrl = @"fb_product_applink_iphone_url";
FBSDKAppEventParameterProduct FBSDKAppEventParameterProductAppLinkIPhoneAppStoreID = @"fb_product_applink_iphone_app_store_id";
FBSDKAppEventParameterProduct FBSDKAppEventParameterProductAppLinkIPhoneAppName = @"fb_product_applink_iphone_app_name";
FBSDKAppEventParameterProduct FBSDKAppEventParameterProductAppLinkIPadUrl = @"fb_product_applink_ipad_url";
FBSDKAppEventParameterProduct FBSDKAppEventParameterProductAppLinkIPadAppStoreID = @"fb_product_applink_ipad_app_store_id";
FBSDKAppEventParameterProduct FBSDKAppEventParameterProductAppLinkIPadAppName = @"fb_product_applink_ipad_app_name";
FBSDKAppEventParameterProduct FBSDKAppEventParameterProductAppLinkAndroidUrl = @"fb_product_applink_android_url";
FBSDKAppEventParameterProduct FBSDKAppEventParameterProductAppLinkAndroidPackage = @"fb_product_applink_android_package";
FBSDKAppEventParameterProduct FBSDKAppEventParameterProductAppLinkAndroidAppName = @"fb_product_applink_android_app_name";
FBSDKAppEventParameterProduct FBSDKAppEventParameterProductAppLinkWindowsPhoneUrl = @"fb_product_applink_windows_phone_url";
FBSDKAppEventParameterProduct FBSDKAppEventParameterProductAppLinkWindowsPhoneAppID = @"fb_product_applink_windows_phone_app_id";
FBSDKAppEventParameterProduct FBSDKAppEventParameterProductAppLinkWindowsPhoneAppName = @"fb_product_applink_windows_phone_app_name";

//
// Public event parameter values
//

FBSDKAppEventParameterValue FBSDKAppEventParameterValueNo = @"0";
FBSDKAppEventParameterValue FBSDKAppEventParameterValueYes = @"1";

//
// Event names internal to this file
//
FBSDKAppEventName FBSDKAppEventNameLoginViewUsage = @"fb_login_view_usage";
FBSDKAppEventName FBSDKAppEventNameShareSheetLaunch = @"fb_share_sheet_launch";
FBSDKAppEventName FBSDKAppEventNameShareSheetDismiss = @"fb_share_sheet_dismiss";
FBSDKAppEventName FBSDKAppEventNameShareTrayDidLaunch = @"fb_share_tray_did_launch";
FBSDKAppEventName FBSDKAppEventNameShareTrayDidSelectActivity = @"fb_share_tray_did_select_activity";
FBSDKAppEventName FBSDKAppEventNamePermissionsUILaunch = @"fb_permissions_ui_launch";
FBSDKAppEventName FBSDKAppEventNamePermissionsUIDismiss = @"fb_permissions_ui_dismiss";
FBSDKAppEventName FBSDKAppEventNameFBDialogsPresentShareDialog = @"fb_dialogs_present_share";
FBSDKAppEventName FBSDKAppEventNameFBDialogsPresentShareDialogPhoto = @"fb_dialogs_present_share_photo";
FBSDKAppEventName FBSDKAppEventNameFBDialogsPresentShareDialogOG = @"fb_dialogs_present_share_og";
FBSDKAppEventName FBSDKAppEventNameFBDialogsPresentLikeDialogOG = @"fb_dialogs_present_like_og";
FBSDKAppEventName FBSDKAppEventNameFBDialogsPresentMessageDialog = @"fb_dialogs_present_message";
FBSDKAppEventName FBSDKAppEventNameFBDialogsPresentMessageDialogPhoto = @"fb_dialogs_present_message_photo";

FBSDKAppEventName FBSDKAppEventNameFBDialogsNativeLoginDialogStart = @"fb_dialogs_native_login_dialog_start";
NSString *const FBSDKAppEventsNativeLoginDialogStartTime = @"fb_native_login_dialog_start_time";

FBSDKAppEventName FBSDKAppEventNameFBDialogsNativeLoginDialogEnd = @"fb_dialogs_native_login_dialog_end";
NSString *const FBSDKAppEventsNativeLoginDialogEndTime = @"fb_native_login_dialog_end_time";

FBSDKAppEventName FBSDKAppEventNameFBDialogsWebLoginCompleted = @"fb_dialogs_web_login_dialog_complete";
NSString *const FBSDKAppEventsWebLoginE2E = @"fb_web_login_e2e";

FBSDKAppEventName FBSDKAppEventNameFBSessionAuthStart = @"fb_mobile_login_start";
FBSDKAppEventName FBSDKAppEventNameFBSessionAuthEnd = @"fb_mobile_login_complete";
FBSDKAppEventName FBSDKAppEventNameFBSessionAuthMethodStart = @"fb_mobile_login_method_start";
FBSDKAppEventName FBSDKAppEventNameFBSessionAuthMethodEnd = @"fb_mobile_login_method_complete";
FBSDKAppEventName FBSDKAppEventNameFBSessionAuthHeartbeat = @"fb_mobile_login_heartbeat";

FBSDKAppEventName FBSDKAppEventNameFBReferralStart = @"fb_referral_start";
FBSDKAppEventName FBSDKAppEventNameFBReferralEnd = @"fb_referral_end";

FBSDKAppEventName FBSDKAppEventNameFBSDKLikeButtonImpression = @"fb_like_button_impression";
FBSDKAppEventName FBSDKAppEventNameFBSDKSendButtonImpression = @"fb_send_button_impression";
FBSDKAppEventName FBSDKAppEventNameFBSDKShareButtonImpression = @"fb_share_button_impression";
FBSDKAppEventName FBSDKAppEventNameFBSDKLiveStreamingButtonImpression = @"fb_live_streaming_button_impression";

FBSDKAppEventName FBSDKAppEventNameFBSDKSmartLoginService = @"fb_smart_login_service";

FBSDKAppEventName FBSDKAppEventNameFBSDKLikeButtonDidTap = @"fb_like_button_did_tap";
FBSDKAppEventName FBSDKAppEventNameFBSDKLoginButtonDidTap = @"fb_login_button_did_tap";
FBSDKAppEventName FBSDKAppEventNameFBSDKSendButtonDidTap = @"fb_send_button_did_tap";
FBSDKAppEventName FBSDKAppEventNameFBSDKShareButtonDidTap = @"fb_share_button_did_tap";
FBSDKAppEventName FBSDKAppEventNameFBSDKLiveStreamingButtonDidTap = @"fb_live_streaming_button_did_tap";

FBSDKAppEventName FBSDKAppEventNameFBSDKLikeControlDidDisable = @"fb_like_control_did_disable";
FBSDKAppEventName FBSDKAppEventNameFBSDKLikeControlDidLike = @"fb_like_control_did_like";
FBSDKAppEventName FBSDKAppEventNameFBSDKLikeControlDidPresentDialog = @"fb_like_control_did_present_dialog";
FBSDKAppEventName FBSDKAppEventNameFBSDKLikeControlDidTap = @"fb_like_control_did_tap";
FBSDKAppEventName FBSDKAppEventNameFBSDKLikeControlDidUnlike = @"fb_like_control_did_unlike";
FBSDKAppEventName FBSDKAppEventNameFBSDKLikeControlError = @"fb_like_control_error";
FBSDKAppEventName FBSDKAppEventNameFBSDKLikeControlImpression = @"fb_like_control_impression";
FBSDKAppEventName FBSDKAppEventNameFBSDKLikeControlNetworkUnavailable = @"fb_like_control_network_unavailable";

FBSDKAppEventName FBSDKAppEventNameFBSDKEventShareDialogResult = @"fb_dialog_share_result";
FBSDKAppEventName FBSDKAppEventNameFBSDKEventMessengerShareDialogResult = @"fb_messenger_dialog_share_result";
FBSDKAppEventName FBSDKAppEventNameFBSDKEventAppInviteShareDialogResult = @"fb_app_invite_dialog_share_result";

FBSDKAppEventName FBSDKAppEventNameFBSDKEventShareDialogShow = @"fb_dialog_share_show";
FBSDKAppEventName FBSDKAppEventNameFBSDKEventMessengerShareDialogShow = @"fb_messenger_dialog_share_show";
FBSDKAppEventName FBSDKAppEventNameFBSDKEventAppInviteShareDialogShow = @"fb_app_invite_share_show";

FBSDKAppEventName FBSDKAppEventNameFBSessionFASLoginDialogResult = @"fb_mobile_login_fas_dialog_result";

FBSDKAppEventName FBSDKAppEventNameFBSDKLiveStreamingStart = @"fb_sdk_live_streaming_start";
FBSDKAppEventName FBSDKAppEventNameFBSDKLiveStreamingStop = @"fb_sdk_live_streaming_stop";
FBSDKAppEventName FBSDKAppEventNameFBSDKLiveStreamingPause = @"fb_sdk_live_streaming_pause";
FBSDKAppEventName FBSDKAppEventNameFBSDKLiveStreamingResume = @"fb_sdk_live_streaming_resume";
FBSDKAppEventName FBSDKAppEventNameFBSDKLiveStreamingError = @"fb_sdk_live_streaming_error";
FBSDKAppEventName FBSDKAppEventNameFBSDKLiveStreamingUpdateStatus = @"fb_sdk_live_streaming_update_status";
FBSDKAppEventName FBSDKAppEventNameFBSDKLiveStreamingVideoID = @"fb_sdk_live_streaming_video_id";
FBSDKAppEventName FBSDKAppEventNameFBSDKLiveStreamingMic = @"fb_sdk_live_streaming_mic";
FBSDKAppEventName FBSDKAppEventNameFBSDKLiveStreamingCamera = @"fb_sdk_live_streaming_camera";

// Event Parameters internal to this file
NSString *const FBSDKAppEventParameterDialogOutcome = @"fb_dialog_outcome";
NSString *const FBSDKAppEventParameterDialogErrorMessage = @"fb_dialog_outcome_error_message";
NSString *const FBSDKAppEventParameterDialogMode = @"fb_dialog_mode";
NSString *const FBSDKAppEventParameterDialogShareContentType = @"fb_dialog_share_content_type";
NSString *const FBSDKAppEventParameterDialogShareContentUUID = @"fb_dialog_share_content_uuid";
NSString *const FBSDKAppEventParameterDialogShareContentPageID = @"fb_dialog_share_content_page_id";
NSString *const FBSDKAppEventParameterShareTrayActivityName = @"fb_share_tray_activity";
NSString *const FBSDKAppEventParameterShareTrayResult = @"fb_share_tray_result";
NSString *const FBSDKAppEventParameterLogTime = @"_logTime";
NSString *const FBSDKAppEventParameterEventName = @"_eventName";
NSString *const FBSDKAppEventParameterImplicitlyLogged = @"_implicitlyLogged";
NSString *const FBSDKAppEventParameterInBackground = @"_inBackground";

NSString *const FBSDKAppEventParameterLiveStreamingPrevStatus = @"live_streaming_prev_status";
NSString *const FBSDKAppEventParameterLiveStreamingStatus = @"live_streaming_status";
NSString *const FBSDKAppEventParameterLiveStreamingError = @"live_streaming_error";
NSString *const FBSDKAppEventParameterLiveStreamingVideoID = @"live_streaming_video_id";
NSString *const FBSDKAppEventParameterLiveStreamingMicEnabled = @"live_streaming_mic_enabled";
NSString *const FBSDKAppEventParameterLiveStreamingCameraEnabled = @"live_streaming_camera_enabled";

FBSDKAppEventParameterProduct FBSDKAppEventParameterProductItemID = @"fb_product_item_id";
FBSDKAppEventParameterProduct FBSDKAppEventParameterProductAvailability = @"fb_product_availability";
FBSDKAppEventParameterProduct FBSDKAppEventParameterProductCondition = @"fb_product_condition";
FBSDKAppEventParameterProduct FBSDKAppEventParameterProductDescription = @"fb_product_description";
FBSDKAppEventParameterProduct FBSDKAppEventParameterProductImageLink = @"fb_product_image_link";
FBSDKAppEventParameterProduct FBSDKAppEventParameterProductLink = @"fb_product_link";
FBSDKAppEventParameterProduct FBSDKAppEventParameterProductTitle = @"fb_product_title";
FBSDKAppEventParameterProduct FBSDKAppEventParameterProductGTIN = @"fb_product_gtin";
FBSDKAppEventParameterProduct FBSDKAppEventParameterProductMPN = @"fb_product_mpn";
FBSDKAppEventParameterProduct FBSDKAppEventParameterProductBrand = @"fb_product_brand";
FBSDKAppEventParameterProduct FBSDKAppEventParameterProductPriceAmount = @"fb_product_price_amount";
FBSDKAppEventParameterProduct FBSDKAppEventParameterProductPriceCurrency = @"fb_product_price_currency";

// Event parameter values internal to this file
NSString *const FBSDKAppEventsDialogOutcomeValue_Completed = @"Completed";
NSString *const FBSDKAppEventsDialogOutcomeValue_Cancelled = @"Cancelled";
NSString *const FBSDKAppEventsDialogOutcomeValue_Failed = @"Failed";

NSString *const FBSDKAppEventsDialogShareModeAutomatic = @"Automatic";
NSString *const FBSDKAppEventsDialogShareModeBrowser = @"Browser";
NSString *const FBSDKAppEventsDialogShareModeNative = @"Native";
NSString *const FBSDKAppEventsDialogShareModeShareSheet = @"ShareSheet";
NSString *const FBSDKAppEventsDialogShareModeWeb = @"Web";
NSString *const FBSDKAppEventsDialogShareModeFeedBrowser = @"FeedBrowser";
NSString *const FBSDKAppEventsDialogShareModeFeedWeb = @"FeedWeb";
NSString *const FBSDKAppEventsDialogShareModeUnknown = @"Unknown";

NSString *const FBSDKAppEventsDialogShareContentTypeStatus = @"Status";
NSString *const FBSDKAppEventsDialogShareContentTypePhoto = @"Photo";
NSString *const FBSDKAppEventsDialogShareContentTypeVideo = @"Video";
NSString *const FBSDKAppEventsDialogShareContentTypeCamera = @"Camera";
NSString *const FBSDKAppEventsDialogShareContentTypeUnknown = @"Unknown";

NSString *const FBSDKGateKeeperAppEventsKillSwitch = @"app_events_killswitch";

#if __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_10_0

NSNotificationName const FBSDKAppEventsLoggingResultNotification = @"com.facebook.sdk:FBSDKAppEventsLoggingResultNotification";

#else

NSString *const FBSDKAppEventsLoggingResultNotification = @"com.facebook.sdk:FBSDKAppEventsLoggingResultNotification";

#endif

NSString *const FBSDKAppEventsOverrideAppIDBundleKey = @"FacebookLoggingOverrideAppID";

//
// Push Notifications
//
// Activities Endpoint Parameter
static NSString *const FBSDKActivitesParameterPushDeviceToken = @"device_token";
// Event Names
static FBSDKAppEventName FBSDKAppEventNamePushTokenObtained = @"fb_mobile_obtain_push_token";
static FBSDKAppEventName FBSDKAppEventNamePushOpened = @"fb_mobile_push_opened";
// Event Parameter
static NSString *const FBSDKAppEventParameterPushCampaign = @"fb_push_campaign";
static NSString *const FBSDKAppEventParameterPushAction = @"fb_push_action";
// Payload Keys
static NSString *const FBSDKAppEventsPushPayloadKey = @"fb_push_payload";
static NSString *const FBSDKAppEventsPushPayloadCampaignKey = @"campaign";

//
// Augmentation of web browser constants
//
NSString *const FBSDKAppEventsWKWebViewMessagesPixelIDKey = @"pixelID";
NSString *const FBSDKAppEventsWKWebViewMessagesHandlerKey = @"fbmqHandler";
NSString *const FBSDKAppEventsWKWebViewMessagesEventKey = @"event";
NSString *const FBSDKAppEventsWKWebViewMessagesParamsKey = @"params";
NSString *const FBSDKAPPEventsWKWebViewMessagesProtocolKey = @"fbmq-0.1";

#define NUM_LOG_EVENTS_TO_TRY_TO_FLUSH_AFTER 100
#define FLUSH_PERIOD_IN_SECONDS 15
#define USER_ID_USER_DEFAULTS_KEY @"com.facebook.sdk.appevents.userid"

#define FBUnityUtilityClassName "FBUnityUtility"
#define FBUnityUtilityUpdateBindingsSelector @"triggerUpdateBindings:"

static NSString *g_overrideAppID = nil;
static BOOL g_explicitEventsLoggedYet;
static Class<FBSDKGateKeeperManaging> g_gateKeeperManager;
static Class<FBSDKAppEventsConfigurationProviding> g_appEventsConfigurationProvider;
static Class<FBSDKServerConfigurationProviding> g_serverConfigurationProvider;
static id<FBSDKGraphRequestProviding> g_graphRequestProvider;
static id<FBSDKFeatureChecking> g_featureChecker;
static Class<FBSDKLogging> g_logger;
static id<FBSDKSettings> g_settings;
static Class<FBSDKPaymentObserving> g_paymentObserver;

#if !TARGET_OS_TV
static id<FBSDKEventProcessing> g_eventProcessor = nil;
#endif

@interface FBSDKAppEvents ()

@property (class, nullable, assign) id<FBSDKDataPersisting> store;

@property (nonatomic, assign) FBSDKAppEventsFlushBehavior flushBehavior;

// for testing only.
@property (nonatomic, assign) BOOL disableTimer;

@property (nonatomic, copy) NSString *pushNotificationsDeviceTokenString;

@property (nonatomic, strong) dispatch_source_t flushTimer;

@property (nonatomic, copy) NSString *userID;

@property (nonatomic, strong) id<FBSDKAtePublishing> atePublisher;

@end

@implementation FBSDKAppEvents
{
  FBSDKServerConfiguration *_serverConfiguration;
  FBSDKAppEventsState *_appEventsState;
#if !TARGET_OS_TV
  FBSDKEventBindingManager *_eventBindingManager;
#endif
  BOOL _isUnityInit;
}

#pragma mark - Object Lifecycle

static id<FBSDKDataPersisting> _store;
static BOOL _canLogEvents = NO;

static UIApplicationState _applicationState = UIApplicationStateInactive;

+ (void)initialize
{
  if (self == [FBSDKAppEvents class]) {
    g_overrideAppID = [[[NSBundle mainBundle] objectForInfoDictionaryKey:FBSDKAppEventsOverrideAppIDBundleKey] copy];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^(void) {
      [FBSDKBasicUtility anonymousID];
    });
  }
}

- (instancetype)init
{
  NSString *userID = [self.class.store stringForKey:USER_ID_USER_DEFAULTS_KEY];
  FBSDKAppEventsAtePublisher *publisher = [[FBSDKAppEventsAtePublisher alloc] initWithAppIdentifier:self.appID
                                                                                              store:self.class.store];
  return [self initWithFlushBehavior:FBSDKAppEventsFlushBehaviorAuto
                flushPeriodInSeconds:FLUSH_PERIOD_IN_SECONDS
                              userID:userID
                        atePublisher:publisher];
}

- (instancetype)initWithFlushBehavior:(FBSDKAppEventsFlushBehavior)flushBehavior
                 flushPeriodInSeconds:(int)flushPeriodInSeconds
                               userID:(nonnull NSString *)userID
                         atePublisher:(nonnull id<FBSDKAtePublishing>)atePublisher
{
  self = [super init];
  if (self) {
    _flushBehavior = flushBehavior;

    __weak FBSDKAppEvents *weakSelf = self;
    self.flushTimer = [FBSDKUtility startGCDTimerWithInterval:flushPeriodInSeconds
                                                        block:^{
                                                          [weakSelf flushTimerFired:nil];
                                                        }];

    _userID = userID;
    _atePublisher = atePublisher;

    [self fetchServerConfiguration:nil];
  }

  return self;
}

- (void)registerNotifications
{
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
}

- (void)dealloc
{
  [[NSNotificationCenter defaultCenter] removeObserver:self];
  [FBSDKUtility stopGCDTimer:self.flushTimer];
}

#pragma mark - Public Methods

+ (void)logEvent:(FBSDKAppEventName)eventName
{
  [FBSDKAppEvents logEvent:eventName
                parameters:@{}];
}

+ (void)logEvent:(FBSDKAppEventName)eventName
      valueToSum:(double)valueToSum
{
  [FBSDKAppEvents logEvent:eventName
                valueToSum:valueToSum
                parameters:@{}];
}

+ (void)logEvent:(FBSDKAppEventName)eventName
      parameters:(NSDictionary *)parameters
{
  [FBSDKAppEvents logEvent:eventName
                valueToSum:nil
                parameters:parameters
               accessToken:nil];
}

+ (void)logEvent:(FBSDKAppEventName)eventName
      valueToSum:(double)valueToSum
      parameters:(NSDictionary *)parameters
{
  [FBSDKAppEvents logEvent:eventName
                valueToSum:@(valueToSum)
                parameters:parameters
               accessToken:nil];
}

+ (void)logEvent:(FBSDKAppEventName)eventName
      valueToSum:(NSNumber *)valueToSum
      parameters:(NSDictionary *)parameters
     accessToken:(FBSDKAccessToken *)accessToken
{
  [[FBSDKAppEvents singleton] instanceLogEvent:eventName
                                    valueToSum:valueToSum
                                    parameters:parameters
                            isImplicitlyLogged:[parameters[FBSDKAppEventParameterImplicitlyLogged] boolValue]
                                   accessToken:accessToken];
}

+ (void)logPurchase:(double)purchaseAmount
           currency:(NSString *)currency
{
  [FBSDKAppEvents logPurchase:purchaseAmount
                     currency:currency
                   parameters:@{}];
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
                valueToSum:@(purchaseAmount)
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
  [self logPushNotificationOpen:payload action:@""];
}

+ (void)logPushNotificationOpen:(NSDictionary *)payload action:(NSString *)action
{
  NSDictionary *facebookPayload = payload[FBSDKAppEventsPushPayloadKey];
  if (!facebookPayload) {
    return;
  }
  NSString *campaign = facebookPayload[FBSDKAppEventsPushPayloadCampaignKey];
  if (campaign.length == 0) {
    [g_logger singleShotLogEntry:FBSDKLoggingBehaviorDeveloperErrors
                        logEntry:@"Malformed payload specified for logging a push notification open."];
    return;
  }

  NSMutableDictionary *parameters = [NSMutableDictionary dictionaryWithObject:campaign forKey:FBSDKAppEventParameterPushCampaign];
  if (action && action.length > 0) {
    [FBSDKTypeUtility dictionary:parameters setObject:action forKey:FBSDKAppEventParameterPushAction];
  }
  [self logEvent:FBSDKAppEventNamePushOpened parameters:parameters];
}

/*
 *  Uploads product catalog product item as an app event
 */
+ (void)logProductItem:(NSString *)itemID
          availability:(FBSDKProductAvailability)availability
             condition:(FBSDKProductCondition)condition
           description:(NSString *)description
             imageLink:(NSString *)imageLink
                  link:(NSString *)link
                 title:(NSString *)title
           priceAmount:(double)priceAmount
              currency:(NSString *)currency
                  gtin:(NSString *)gtin
                   mpn:(NSString *)mpn
                 brand:(NSString *)brand
            parameters:(NSDictionary *)parameters
{
  if (itemID == nil) {
    [g_logger singleShotLogEntry:FBSDKLoggingBehaviorDeveloperErrors
                        logEntry:@"itemID cannot be null"];
    return;
  } else if (description == nil) {
    [g_logger singleShotLogEntry:FBSDKLoggingBehaviorDeveloperErrors
                        logEntry:@"description cannot be null"];
    return;
  } else if (imageLink == nil) {
    [g_logger singleShotLogEntry:FBSDKLoggingBehaviorDeveloperErrors
                        logEntry:@"imageLink cannot be null"];
    return;
  } else if (link == nil) {
    [g_logger singleShotLogEntry:FBSDKLoggingBehaviorDeveloperErrors
                        logEntry:@"link cannot be null"];
    return;
  } else if (title == nil) {
    [g_logger singleShotLogEntry:FBSDKLoggingBehaviorDeveloperErrors
                        logEntry:@"title cannot be null"];
    return;
  } else if (currency == nil) {
    [g_logger singleShotLogEntry:FBSDKLoggingBehaviorDeveloperErrors
                        logEntry:@"currency cannot be null"];
    return;
  } else if (gtin == nil && mpn == nil && brand == nil) {
    [g_logger singleShotLogEntry:FBSDKLoggingBehaviorDeveloperErrors
                        logEntry:@"Either gtin, mpn or brand is required"];
    return;
  }

  NSMutableDictionary *dict = [NSMutableDictionary dictionary];
  if (nil != parameters) {
    [dict setValuesForKeysWithDictionary:parameters];
  }

  [FBSDKTypeUtility dictionary:dict setObject:itemID forKey:FBSDKAppEventParameterProductItemID];

  NSString *avail = nil;
  switch (availability) {
    case FBSDKProductAvailabilityInStock:
      avail = @"IN_STOCK"; break;
    case FBSDKProductAvailabilityOutOfStock:
      avail = @"OUT_OF_STOCK"; break;
    case FBSDKProductAvailabilityPreOrder:
      avail = @"PREORDER"; break;
    case FBSDKProductAvailabilityAvailableForOrder:
      avail = @"AVALIABLE_FOR_ORDER"; break;
    case FBSDKProductAvailabilityDiscontinued:
      avail = @"DISCONTINUED"; break;
  }
  if (avail) {
    [FBSDKTypeUtility dictionary:dict setObject:avail forKey:FBSDKAppEventParameterProductAvailability];
  }

  NSString *cond = nil;
  switch (condition) {
    case FBSDKProductConditionNew:
      cond = @"NEW"; break;
    case FBSDKProductConditionRefurbished:
      cond = @"REFURBISHED"; break;
    case FBSDKProductConditionUsed:
      cond = @"USED"; break;
  }
  if (cond) {
    [FBSDKTypeUtility dictionary:dict setObject:cond forKey:FBSDKAppEventParameterProductCondition];
  }

  [FBSDKTypeUtility dictionary:dict setObject:description forKey:FBSDKAppEventParameterProductDescription];
  [FBSDKTypeUtility dictionary:dict setObject:imageLink forKey:FBSDKAppEventParameterProductImageLink];
  [FBSDKTypeUtility dictionary:dict setObject:link forKey:FBSDKAppEventParameterProductLink];
  [FBSDKTypeUtility dictionary:dict setObject:title forKey:FBSDKAppEventParameterProductTitle];
  [FBSDKTypeUtility dictionary:dict setObject:[NSString stringWithFormat:@"%.3lf", priceAmount] forKey:FBSDKAppEventParameterProductPriceAmount];
  [FBSDKTypeUtility dictionary:dict setObject:currency forKey:FBSDKAppEventParameterProductPriceCurrency];
  if (gtin) {
    [FBSDKTypeUtility dictionary:dict setObject:gtin forKey:FBSDKAppEventParameterProductGTIN];
  }
  if (mpn) {
    [FBSDKTypeUtility dictionary:dict setObject:mpn forKey:FBSDKAppEventParameterProductMPN];
  }
  if (brand) {
    [FBSDKTypeUtility dictionary:dict setObject:brand forKey:FBSDKAppEventParameterProductBrand];
  }

  [FBSDKAppEvents logEvent:FBSDKAppEventNameProductCatalogUpdate
                parameters:dict];
}

+ (void)activateApp
{
  if (![self canLogEvents]) {
    NSLog(
      @"<Warning> App events cannot be activated before the Facebook SDK is initialized. "
      "Learn more: https://github.com/facebook/facebook-ios-sdk/blob/master/CHANGELOG.md#900"
    );
    return;
  }

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
  NSString *deviceTokenString = [FBSDKInternalUtility hexadecimalStringFromData:deviceToken];
  [FBSDKAppEvents setPushNotificationsDeviceTokenString:deviceTokenString];
}

+ (void)setPushNotificationsDeviceTokenString:(NSString *)deviceTokenString
{
  if (deviceTokenString == nil) {
    [FBSDKAppEvents singleton].pushNotificationsDeviceTokenString = nil;
    return;
  }

  if (![deviceTokenString isEqualToString:([FBSDKAppEvents singleton].pushNotificationsDeviceTokenString)]) {
    [FBSDKAppEvents singleton].pushNotificationsDeviceTokenString = deviceTokenString;

    [FBSDKAppEvents logEvent:FBSDKAppEventNamePushTokenObtained];

    // Unless the behavior is set to only allow explicit flushing, we go ahead and flush the event
    if ([FBSDKAppEvents flushBehavior] != FBSDKAppEventsFlushBehaviorExplicitOnly) {
      [[FBSDKAppEvents singleton] flushForReason:FBSDKAppEventsFlushReasonEagerlyFlushingEvent];
    }
  }
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
    FBSDKConditionalLog(
      !g_explicitEventsLoggedYet,
      FBSDKLoggingBehaviorDeveloperErrors,
      @"[FBSDKAppEvents setLoggingOverrideAppID:] should only be called prior to any events being logged."
    );
    g_overrideAppID = appID;
  }
}

+ (void)flush
{
  [[FBSDKAppEvents singleton] flushForReason:FBSDKAppEventsFlushReasonExplicit];
}

+ (void)setUserID:(NSString *)userID
{
  if ([[[self class] singleton].userID isEqualToString:userID]) {
    return;
  }
  [[self class] singleton].userID = userID;
  [self.store setObject:userID forKey:USER_ID_USER_DEFAULTS_KEY];
}

+ (void)clearUserID
{
  [self setUserID:nil];
}

+ (NSString *)userID
{
  return [[self class] singleton].userID;
}

+ (void)setUserEmail:(nullable NSString *)email
           firstName:(nullable NSString *)firstName
            lastName:(nullable NSString *)lastName
               phone:(nullable NSString *)phone
         dateOfBirth:(nullable NSString *)dateOfBirth
              gender:(nullable NSString *)gender
                city:(nullable NSString *)city
               state:(nullable NSString *)state
                 zip:(nullable NSString *)zip
             country:(nullable NSString *)country
{
  [FBSDKUserDataStore setUserEmail:email
                         firstName:firstName
                          lastName:lastName
                             phone:phone
                       dateOfBirth:dateOfBirth
                            gender:gender
                              city:city
                             state:state
                               zip:zip
                           country:country
                        externalId:nil];
}

+ (NSString *)getUserData
{
  return [FBSDKUserDataStore getUserData];
}

+ (void)clearUserData
{
  [FBSDKUserDataStore clearUserData];
}

+ (void)setUserData:(nullable NSString *)data
            forType:(FBSDKAppEventUserDataType)type
{
  [FBSDKUserDataStore setUserData:data forType:type];
}

+ (void)clearUserDataForType:(FBSDKAppEventUserDataType)type
{
  [FBSDKUserDataStore clearUserDataForType:type];
}

+ (void)updateUserProperties:(NSDictionary<NSString *, id> *)properties handler:(FBSDKGraphRequestBlock)handler
{}

+ (NSString *)anonymousID
{
  return [FBSDKBasicUtility anonymousID];
}

#if !TARGET_OS_TV
+ (void)augmentHybridWKWebView:(WKWebView *)webView
{
  // Ensure we can instantiate WebKit before trying this
  Class WKWebViewClass = fbsdkdfl_WKWebViewClass();
  if (WKWebViewClass != nil && [webView isKindOfClass:WKWebViewClass]) {
    Class WKUserScriptClass = fbsdkdfl_WKUserScriptClass();
    if (WKUserScriptClass != nil) {
      WKUserContentController *controller = webView.configuration.userContentController;
      FBSDKHybridAppEventsScriptMessageHandler *scriptHandler = [FBSDKHybridAppEventsScriptMessageHandler new];
      [controller addScriptMessageHandler:scriptHandler name:FBSDKAppEventsWKWebViewMessagesHandlerKey];

      NSString *js = [NSString stringWithFormat:@"window.fbmq_%@={'sendEvent': function(pixel_id,event_name,custom_data){var msg={\"%@\":pixel_id, \"%@\":event_name,\"%@\":custom_data};window.webkit.messageHandlers[\"%@\"].postMessage(msg);}, 'getProtocol':function(){return \"%@\";}}",
                      [[self singleton] appID],
                      FBSDKAppEventsWKWebViewMessagesPixelIDKey,
                      FBSDKAppEventsWKWebViewMessagesEventKey,
                      FBSDKAppEventsWKWebViewMessagesParamsKey,
                      FBSDKAppEventsWKWebViewMessagesHandlerKey,
                      FBSDKAPPEventsWKWebViewMessagesProtocolKey
      ];

      [controller addUserScript:[[WKUserScriptClass alloc] initWithSource:js injectionTime:WKUserScriptInjectionTimeAtDocumentStart forMainFrameOnly:NO]];
    }
  } else {
    [FBSDKAppEventsUtility logAndNotify:@"You must call augmentHybridWKWebView with WebKit linked to your project and a WKWebView instance"];
  }
}

#endif

+ (void)setIsUnityInit:(BOOL)isUnityInit
{
  [FBSDKAppEvents singleton]->_isUnityInit = isUnityInit;
}

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
+ (void)sendEventBindingsToUnity
{
  // Send event bindings to Unity only Unity is initialized
  if ([FBSDKAppEvents singleton]->_isUnityInit
      && [FBSDKAppEvents singleton]->_serverConfiguration
      && [FBSDKTypeUtility isValidJSONObject:[FBSDKAppEvents singleton]->_serverConfiguration.eventBindings]
  ) {
    NSData *jsonData = [FBSDKTypeUtility dataWithJSONObject:[FBSDKAppEvents singleton]->_serverConfiguration.eventBindings ?: @""
                                                    options:0
                                                      error:nil];
    NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    Class classFBUnityUtility = objc_lookUpClass(FBUnityUtilityClassName);
    SEL updateBindingSelector = NSSelectorFromString(FBUnityUtilityUpdateBindingsSelector);
    if ([classFBUnityUtility respondsToSelector:updateBindingSelector]) {
      [classFBUnityUtility performSelector:updateBindingSelector withObject:jsonString];
    }
  }
}

#pragma clang diagnostic pop

#pragma mark - Internal Methods

+ (void)configureWithGateKeeperManager:(Class<FBSDKGateKeeperManaging>)gateKeeperManager
        appEventsConfigurationProvider:(Class<FBSDKAppEventsConfigurationProviding>)appEventsConfigurationProvider
           serverConfigurationProvider:(Class<FBSDKServerConfigurationProviding>)serverConfigurationProvider
                  graphRequestProvider:(id<FBSDKGraphRequestProviding>)provider
                        featureChecker:(id<FBSDKFeatureChecking>)featureChecker
                                 store:(id<FBSDKDataPersisting>)store
                                logger:(Class<FBSDKLogging>)logger
                              settings:(id<FBSDKSettings>)settings
                       paymentObserver:(Class<FBSDKPaymentObserving>)paymentObserver
{
  [FBSDKAppEvents setAppEventsConfigurationProvider:appEventsConfigurationProvider];
  [FBSDKAppEvents setServerConfigurationProvider:serverConfigurationProvider];
  g_gateKeeperManager = gateKeeperManager;
  self.store = store;
  g_logger = logger;
  [FBSDKAppEvents setRequestProvider:provider];
  [FBSDKAppEvents setFeatureChecker:featureChecker];
  [FBSDKAppEvents setCanLogEvents];
  g_settings = settings;
  g_paymentObserver = paymentObserver;
}

+ (void)setFeatureChecker:(id<FBSDKFeatureChecking>)checker
{
  if (g_featureChecker != checker) {
    g_featureChecker = checker;
  }
}

+ (void)setRequestProvider:(id<FBSDKGraphRequestProviding>)provider
{
  if (g_graphRequestProvider != provider) {
    g_graphRequestProvider = provider;
  }
}

+ (void)setAppEventsConfigurationProvider:(Class<FBSDKAppEventsConfigurationProviding>)provider
{
  if (g_appEventsConfigurationProvider != provider) {
    g_appEventsConfigurationProvider = provider;
  }
}

+ (void)setServerConfigurationProvider:(Class<FBSDKServerConfigurationProviding>)provider
{
  if (g_serverConfigurationProvider != provider) {
    g_serverConfigurationProvider = provider;
  }
}

+ (id<FBSDKDataPersisting>)store
{
  return _store;
}

+ (void)setStore:(id<FBSDKDataPersisting>)store
{
  if (_store != store) {
    _store = store;
  }
}

#if !TARGET_OS_TV

+ (void)setEventProcessor:(id<FBSDKEventProcessing>)eventProcessor
{
  g_eventProcessor = eventProcessor;
}

#endif

+ (void)logInternalEvent:(FBSDKAppEventName)eventName
      isImplicitlyLogged:(BOOL)isImplicitlyLogged;
{
  [FBSDKAppEvents logInternalEvent:eventName
                        parameters:@{}
                isImplicitlyLogged:isImplicitlyLogged];
}

+ (void)logInternalEvent:(FBSDKAppEventName)eventName
              valueToSum:(double)valueToSum
      isImplicitlyLogged:(BOOL)isImplicitlyLogged
{
  [FBSDKAppEvents logInternalEvent:eventName
                        valueToSum:valueToSum
                        parameters:@{}
                isImplicitlyLogged:isImplicitlyLogged];
}

+ (void)logInternalEvent:(FBSDKAppEventName)eventName
              parameters:(NSDictionary *)parameters
      isImplicitlyLogged:(BOOL)isImplicitlyLogged
{
  [FBSDKAppEvents logInternalEvent:eventName
                        valueToSum:nil
                        parameters:parameters
                isImplicitlyLogged:isImplicitlyLogged
                       accessToken:nil];
}

+ (void)logInternalEvent:(FBSDKAppEventName)eventName
              parameters:(NSDictionary *)parameters
      isImplicitlyLogged:(BOOL)isImplicitlyLogged
             accessToken:(FBSDKAccessToken *)accessToken
{
  [FBSDKAppEvents logInternalEvent:eventName
                        valueToSum:nil
                        parameters:parameters
                isImplicitlyLogged:isImplicitlyLogged
                       accessToken:accessToken];
}

+ (void)logInternalEvent:(FBSDKAppEventName)eventName
              valueToSum:(double)valueToSum
              parameters:(NSDictionary *)parameters
      isImplicitlyLogged:(BOOL)isImplicitlyLogged
{
  [FBSDKAppEvents logInternalEvent:eventName
                        valueToSum:@(valueToSum)
                        parameters:parameters
                isImplicitlyLogged:isImplicitlyLogged
                       accessToken:nil];
}

+ (void)logInternalEvent:(NSString *)eventName
              valueToSum:(NSNumber *)valueToSum
              parameters:(NSDictionary *)parameters
      isImplicitlyLogged:(BOOL)isImplicitlyLogged
             accessToken:(FBSDKAccessToken *)accessToken
{
  if ([g_settings isAutoLogAppEventsEnabled]) {
    [[FBSDKAppEvents singleton] instanceLogEvent:eventName
                                      valueToSum:valueToSum
                                      parameters:parameters
                              isImplicitlyLogged:isImplicitlyLogged
                                     accessToken:accessToken];
  }
}

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
  static dispatch_once_t onceToken;
  static FBSDKAppEvents *shared = nil;
  dispatch_once(&onceToken, ^{
    shared = [self new];
  });
  return shared;
}

- (void)flushForReason:(FBSDKAppEventsFlushReason)flushReason
{
  // Always flush asynchronously, even on main thread, for two reasons:
  // - most consistent code path for all threads.
  // - allow locks being held by caller to be released prior to actual flushing work being done.
  @synchronized(self) {
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
  return [FBSDKAppEvents loggingOverrideAppID] ?: [g_settings appID];
}

- (void)publishInstall
{
  NSString *appID = [self appID];
  if (appID.length == 0) {
    [g_logger singleShotLogEntry:FBSDKLoggingBehaviorDeveloperErrors logEntry:@"Missing [FBSDKAppEvents appID] for [FBSDKAppEvents publishInstall:]"];
    return;
  }
  NSString *lastAttributionPingString = [NSString stringWithFormat:@"com.facebook.sdk:lastAttributionPing%@", appID];
  id<FBSDKDataPersisting> defaults = self.class.store;
  if ([defaults objectForKey:lastAttributionPingString]) {
    return;
  }
  [self fetchServerConfiguration:^{
    if ([FBSDKAppEventsUtility shouldDropAppEvent]) {
      return;
    }
    NSMutableDictionary *params = [FBSDKAppEventsUtility activityParametersDictionaryForEvent:@"MOBILE_APP_INSTALL"
                                                                    shouldAccessAdvertisingID:self->_serverConfiguration.isAdvertisingIDEnabled];
    [self appendInstallTimestamp:params];
    NSString *path = [NSString stringWithFormat:@"%@/activities", appID];
    id<FBSDKGraphRequest> request = [g_graphRequestProvider createGraphRequestWithGraphPath:path
                                                                                 parameters:params
                                                                                tokenString:nil
                                                                                 HTTPMethod:FBSDKHTTPMethodPOST
                                                                                      flags:FBSDKGraphRequestFlagDoNotInvalidateTokenOnError | FBSDKGraphRequestFlagDisableErrorRecovery];
    [request startWithCompletionHandler:^(FBSDKGraphRequestConnection *connection, id result, NSError *error) {
      if (!error) {
        [defaults setObject:[NSDate date] forKey:lastAttributionPingString];
        NSString *lastInstallResponseKey = [NSString stringWithFormat:@"com.facebook.sdk:lastInstallResponse%@", appID];
        [defaults setObject:result forKey:lastInstallResponseKey];
      }
    }];
  }];
}

- (void)publishATE
{
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    if (self.atePublisher) {
      [self.atePublisher publishATE];
    }
  });
}

- (void)appendInstallTimestamp:(NSMutableDictionary *)parameters
{
  if (@available(iOS 14.0, *)) {
    if ([g_settings isSetATETimeExceedsInstallTime]) {
      NSDate *setAteTimestamp = g_settings.advertiserTrackingEnabledTimestamp;
      [FBSDKTypeUtility dictionary:parameters setObject:@([FBSDKAppEventsUtility convertToUnixTime:setAteTimestamp]) forKey:@"install_timestamp"];
    } else {
      NSDate *installTimestamp = g_settings.installTimestamp;
      [FBSDKTypeUtility dictionary:parameters setObject:@([FBSDKAppEventsUtility convertToUnixTime:installTimestamp]) forKey:@"install_timestamp"];
    }
  }
}

+ (void)setCanLogEvents
{
  _canLogEvents = YES;
}

+ (BOOL)canLogEvents
{
  return _canLogEvents;
}

+ (void)setApplicationState:(UIApplicationState)state
{
  _applicationState = state;
}

+ (UIApplicationState)applicationState
{
  return _applicationState;
}

#if !TARGET_OS_TV
- (void)enableCodelessEvents
{
  if (_serverConfiguration.isCodelessEventsEnabled) {
    [FBSDKCodelessIndexer enable];

    if (!_eventBindingManager) {
      _eventBindingManager = [FBSDKEventBindingManager new];
    }

    if ([FBSDKInternalUtility isUnity]) {
      [FBSDKAppEvents sendEventBindingsToUnity];
    } else {
      [_eventBindingManager updateBindings:[FBSDKEventBindingManager
                                            parseArray:_serverConfiguration.eventBindings]];
    }
  }
}

#endif

// app events can use a server configuration up to 24 hours old to minimize network traffic.
- (void)fetchServerConfiguration:(FBSDKCodeBlock)callback
{
  [g_appEventsConfigurationProvider loadAppEventsConfigurationWithBlock:^{
    [g_serverConfigurationProvider loadServerConfigurationWithCompletionBlock:^(FBSDKServerConfiguration *serverConfiguration, NSError *error) {
      self->_serverConfiguration = serverConfiguration;

      if ([g_settings isAutoLogAppEventsEnabled] && self->_serverConfiguration.implicitPurchaseLoggingEnabled) {
        [g_paymentObserver startObservingTransactions];
      } else {
        [g_paymentObserver stopObservingTransactions];
      }
      [g_featureChecker checkFeature:FBSDKFeatureRestrictiveDataFiltering completionBlock:^(BOOL enabled) {
        if (enabled) {
          [FBSDKRestrictiveDataFilterManager enable];
        }
      }];
      [g_featureChecker checkFeature:FBSDKFeatureEventDeactivation completionBlock:^(BOOL enabled) {
        if (enabled) {
          [FBSDKEventDeactivationManager enable];
        }
      }];
      if (@available(iOS 14.0, *)) {
        __weak FBSDKAppEvents *weakSelf = self;
        [g_featureChecker checkFeature:FBSDKFeatureATELogging completionBlock:^(BOOL enabled) {
          if (enabled) {
            [weakSelf publishATE];
          }
        }];
      }
    #if !TARGET_OS_TV
      [g_featureChecker checkFeature:FBSDKFeatureCodelessEvents completionBlock:^(BOOL enabled) {
        if (enabled) {
          [self enableCodelessEvents];
        }
      }];
      [g_featureChecker checkFeature:FBSDKFeatureAAM completionBlock:^(BOOL enabled) {
        if (enabled) {
          [FBSDKMetadataIndexer enable];
        }
      }];
      [g_featureChecker checkFeature:FBSDKFeaturePrivacyProtection completionBlock:^(BOOL enabled) {
        if (enabled) {
          [g_eventProcessor enable];
        }
      }];
      if (@available(iOS 11.3, *)) {
        if ([g_settings isSKAdNetworkReportEnabled]) {
          [g_featureChecker checkFeature:FBSDKFeatureSKAdNetwork completionBlock:^(BOOL SKAdNetworkEnabled) {
            if (SKAdNetworkEnabled) {
              [SKAdNetwork registerAppForAdNetworkAttribution];
              [g_featureChecker checkFeature:FBSDKFeatureSKAdNetworkConversionValue completionBlock:^(BOOL SKAdNetworkConversionValueEnabled) {
                if (SKAdNetworkConversionValueEnabled) {
                  [FBSDKSKAdNetworkReporter enable];
                }
              }];
            }
          }];
        }
      }
      if (@available(iOS 14.0, *)) {
        [g_featureChecker checkFeature:FBSDKFeatureAEM completionBlock:^(BOOL AEMEnabled) {
          if (AEMEnabled) {
            [FBSDKAEMReporter enable];
          }
        }];
      }
    #endif
      if (callback) {
        callback();
      }
    }];
  }];
}

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
- (void)instanceLogEvent:(FBSDKAppEventName)eventName
              valueToSum:(NSNumber *)valueToSum
              parameters:(NSDictionary *)parameters
      isImplicitlyLogged:(BOOL)isImplicitlyLogged
             accessToken:(FBSDKAccessToken *)accessToken
{
  // Kill events if kill-switch is enabled
  if (!g_gateKeeperManager) {
    [g_logger singleShotLogEntry:FBSDKLoggingBehaviorAppEvents
                    formatString:@"FBSDKAppEvents: Cannot log app events before the SDK is initialized."];
    return;
  } else if ([g_gateKeeperManager boolForKey:FBSDKGateKeeperAppEventsKillSwitch
                                defaultValue:NO]) {
    [g_logger singleShotLogEntry:FBSDKLoggingBehaviorAppEvents
                    formatString:@"FBSDKAppEvents: KillSwitch is enabled and fail to log app event: %@",
     eventName];
    return;
  }
#if !TARGET_OS_TV
  // Update conversion value for SKAdNetwork if needed
  [FBSDKSKAdNetworkReporter recordAndUpdateEvent:eventName currency:[FBSDKTypeUtility dictionary:parameters objectForKey:FBSDKAppEventParameterNameCurrency ofType:NSString.class] value:valueToSum];
  // Update conversion value for AEM if needed
  [FBSDKAEMReporter recordAndUpdateEvent:eventName
                                currency:[FBSDKTypeUtility dictionary:parameters objectForKey:FBSDKAppEventParameterNameCurrency ofType:NSString.class]
                                   value:valueToSum];
#endif

  if ([FBSDKAppEventsUtility shouldDropAppEvent]) {
    return;
  }

  if (isImplicitlyLogged && _serverConfiguration && !_serverConfiguration.isImplicitLoggingSupported) {
    return;
  }

  if (!isImplicitlyLogged && !g_explicitEventsLoggedYet) {
    g_explicitEventsLoggedYet = YES;
  }
  __block BOOL failed = ![FBSDKAppEventsUtility validateIdentifier:eventName];

  // Make sure parameter dictionary is well formed.  Log and exit if not.
  [FBSDKTypeUtility dictionary:parameters enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
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
  }];

  if (failed) {
    return;
  }
  // Filter out deactivated params
  parameters = [FBSDKEventDeactivationManager processParameters:parameters eventName:eventName];

#if !TARGET_OS_TV
  // Filter out restrictive data with on-device ML
  parameters = [FBSDKIntegrityManager processParameters:parameters];
#endif
  // Filter out restrictive keys
  parameters = [FBSDKRestrictiveDataFilterManager processParameters:parameters
                                                          eventName:eventName];

  NSMutableDictionary<NSString *, id> *eventDictionary = [NSMutableDictionary dictionaryWithDictionary:parameters];
  [FBSDKTypeUtility dictionary:eventDictionary setObject:eventName forKey:FBSDKAppEventParameterEventName];
  if (!eventDictionary[FBSDKAppEventParameterLogTime]) {
    [FBSDKTypeUtility dictionary:eventDictionary setObject:@([FBSDKAppEventsUtility unixTimeNow]) forKey:FBSDKAppEventParameterLogTime];
  }
  [FBSDKTypeUtility dictionary:eventDictionary setObject:valueToSum forKey:@"_valueToSum"];
  if (isImplicitlyLogged) {
    [FBSDKTypeUtility dictionary:eventDictionary setObject:@"1" forKey:FBSDKAppEventParameterImplicitlyLogged];
  }

  NSString *currentViewControllerName;
  UIApplicationState applicationState;
  if ([NSThread isMainThread]) {
    // We only collect the view controller when on the main thread, as the behavior off
    // the main thread is unpredictable.  Besides, UI state for off-main-thread computations
    // isn't really relevant anyhow.
    UIViewController *vc = [UIApplication sharedApplication].keyWindow.rootViewController;
    vc = vc.presentedViewController ?: vc;
    if (vc) {
      currentViewControllerName = [[vc class] description];
    } else {
      currentViewControllerName = @"no_ui";
    }
    applicationState = [UIApplication sharedApplication].applicationState;
  } else {
    currentViewControllerName = @"off_thread";
    applicationState = [self.class applicationState];
  }
  [FBSDKTypeUtility dictionary:eventDictionary setObject:currentViewControllerName forKey:@"_ui"];

  if (applicationState == UIApplicationStateBackground) {
    [FBSDKTypeUtility dictionary:eventDictionary setObject:@"1" forKey:FBSDKAppEventParameterInBackground];
  }

  NSString *tokenString = [FBSDKAppEventsUtility tokenStringToUseFor:accessToken];
  NSString *appID = [self appID];

  @synchronized(self) {
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
      [g_logger singleShotLogEntry:FBSDKLoggingBehaviorAppEvents
                      formatString:@"FBSDKAppEvents: Recording event @ %ld: %@",
       [FBSDKAppEventsUtility unixTimeNow],
       eventDictionary];
    }

    [self checkPersistedEvents];

    if (_appEventsState.events.count > NUM_LOG_EVENTS_TO_TRY_TO_FLUSH_AFTER
        && self.flushBehavior != FBSDKAppEventsFlushBehaviorExplicitOnly) {
      [self flushForReason:FBSDKAppEventsFlushReasonEventThreshold];
    }
  }
}

#pragma clang diagnostic pop

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

  if (appEventsState.appID.length == 0) {
    [g_logger singleShotLogEntry:FBSDKLoggingBehaviorDeveloperErrors logEntry:@"Missing [FBSDKAppEvents appEventsState.appID] for [FBSDKAppEvents flushOnMainQueue:]"];
    return;
  }

  [FBSDKAppEventsUtility ensureOnMainThread:NSStringFromSelector(_cmd) className:NSStringFromClass([self class])];

  [self fetchServerConfiguration:^(void) {
    if ([FBSDKAppEventsUtility shouldDropAppEvent]) {
      return;
    }
    NSString *receipt_data = appEventsState.extractReceiptData;
    NSString *encodedEvents = [appEventsState JSONStringForEvents:self->_serverConfiguration.implicitLoggingEnabled];
    if (!encodedEvents || appEventsState.events.count == 0) {
      [g_logger singleShotLogEntry:FBSDKLoggingBehaviorAppEvents
                          logEntry:@"FBSDKAppEvents: Flushing skipped - no events after removing implicitly logged ones.\n"];
      return;
    }
    NSMutableDictionary *postParameters = [FBSDKAppEventsUtility
                                           activityParametersDictionaryForEvent:@"CUSTOM_APP_EVENTS"
                                           shouldAccessAdvertisingID:self->_serverConfiguration.advertisingIDEnabled];
    NSInteger length = receipt_data.length;
    if (length > 0) {
      [FBSDKTypeUtility dictionary:postParameters setObject:receipt_data forKey:@"receipt_data"];
    }

    [FBSDKTypeUtility dictionary:postParameters setObject:encodedEvents forKey:@"custom_events"];
    if (appEventsState.numSkipped > 0) {
      [FBSDKTypeUtility dictionary:postParameters setObject:[NSString stringWithFormat:@"%lu", (unsigned long)appEventsState.numSkipped] forKey:@"num_skipped_events"];
    }
    if (self.pushNotificationsDeviceTokenString) {
      [FBSDKTypeUtility dictionary:postParameters setObject:self.pushNotificationsDeviceTokenString forKey:FBSDKActivitesParameterPushDeviceToken];
    }

    NSString *loggingEntry = nil;
    if ([g_settings.loggingBehaviors containsObject:FBSDKLoggingBehaviorAppEvents]) {
      NSData *prettyJSONData = [FBSDKTypeUtility dataWithJSONObject:appEventsState.events
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
    id<FBSDKGraphRequest> request = [g_graphRequestProvider createGraphRequestWithGraphPath:[NSString stringWithFormat:@"%@/activities", appEventsState.appID]
                                                                                 parameters:postParameters
                                                                                tokenString:appEventsState.tokenString
                                                                                 HTTPMethod:FBSDKHTTPMethodPOST
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
    FlushResultNoConnectivity,
  };

  [FBSDKAppEventsUtility ensureOnMainThread:NSStringFromSelector(_cmd) className:NSStringFromClass([self class])];

  FBSDKAppEventsFlushResult flushResult = FlushResultSuccess;
  if (error) {
    NSInteger errorCode = [error.userInfo[FBSDKGraphRequestErrorHTTPStatusCodeKey] integerValue];

    // We interpret a 400 coming back from FBRequestConnection as a server error due to improper data being
    // sent down.  Otherwise we assume no connectivity, or another condition where we could treat it as no connectivity.
    // Adding 404 as having wrong/missing appID results in 404 and that is not a connectivity issue
    flushResult = (errorCode == 400 || errorCode == 404) ? FlushResultServerError : FlushResultNoConnectivity;
  }

  if (flushResult == FlushResultServerError) {
    // Only log events that developer can do something with (i.e., if parameters are incorrect).
    // as opposed to cases where the token is bad.
    if ([error.userInfo[FBSDKGraphRequestErrorKey] unsignedIntegerValue] == FBSDKGraphRequestErrorOther) {
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
      resultString = [NSString stringWithFormat:@"Server Error - %@", error.description];
      break;
  }

  [g_logger singleShotLogEntry:FBSDKLoggingBehaviorAppEvents
                  formatString:@"%@\nFlush Result : %@", loggingEntry, resultString];
}

- (void)flushTimerFired:(id)arg
{
  [FBSDKAppEventsUtility ensureOnMainThread:NSStringFromSelector(_cmd) className:NSStringFromClass([self class])];
  if (self.flushBehavior != FBSDKAppEventsFlushBehaviorExplicitOnly && !self.disableTimer) {
    [self flushForReason:FBSDKAppEventsFlushReasonTimer];
  }
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
  @synchronized(self) {
    copy = [_appEventsState copy];
    _appEventsState = nil;
  }
  if (copy) {
    [FBSDKAppEventsStateManager persistAppEventsData:copy];
  }
  [FBSDKTimeSpentData suspend];
}

#pragma mark - Custom Audience

+ (id<FBSDKGraphRequest>)requestForCustomAudienceThirdPartyIDWithAccessToken:(FBSDKAccessToken *)accessToken
{
  accessToken = accessToken ?: [FBSDKAccessToken currentAccessToken];
  // Rules for how we use the attribution ID / advertiser ID for an 'custom_audience_third_party_id' Graph API request
  // 1) if the OS tells us that the user has Limited Ad Tracking, then just don't send, and return a nil in the token.
  // 2) if the app has set 'limitEventAndDataUsage', this effectively implies that app-initiated ad targeting shouldn't happen,
  // so use that data here to return nil as well.
  // 3) if we have a user session token, then no need to send attribution ID / advertiser ID back as the udid parameter
  // 4) otherwise, send back the udid parameter.
  if (g_settings.advertisingTrackingStatus == FBSDKAdvertisingTrackingDisallowed || g_settings.shouldLimitEventAndDataUsage) {
    return nil;
  }

  NSString *tokenString = [FBSDKAppEventsUtility tokenStringToUseFor:accessToken];
  NSString *udid = nil;
  if (!accessToken) {
    // We don't have a logged in user, so we need some form of udid representation. Prefer advertiser ID if
    // available. Note that this function only makes sense to be called in the context of advertising.
    udid = [FBSDKAppEventsUtility.shared advertiserID];
    if (!udid) {
      // No udid, and no user token.  No point in making the request.
      return nil;
    }
  }

  NSDictionary *parameters = @{};
  if (udid) {
    parameters = @{ @"udid" : udid };
  }

  NSString *graphPath = [NSString stringWithFormat:@"%@/custom_audience_third_party_id", [[self singleton] appID]];

  id<FBSDKGraphRequest> request = [g_graphRequestProvider createGraphRequestWithGraphPath:graphPath
                                                                               parameters:parameters
                                                                              tokenString:tokenString
                                                                               HTTPMethod:FBSDKHTTPMethodGET
                                                                                    flags:FBSDKGraphRequestFlagDoNotInvalidateTokenOnError | FBSDKGraphRequestFlagDisableErrorRecovery];
  return request;
}

#pragma mark - Testability

#if DEBUG

+ (void)reset
{
  [self resetApplicationState];
  g_gateKeeperManager = nil;
  g_graphRequestProvider = nil;
  _store = nil;
  _canLogEvents = NO;
}

+ (void)resetApplicationState
{
  _applicationState = UIApplicationStateInactive;
}

+ (id<FBSDKFeatureChecking>)featureChecker
{
  return g_featureChecker;
}

+ (id<FBSDKGraphRequestProviding>)requestProvider
{
  return g_graphRequestProvider;
}

+ (Class<FBSDKServerConfigurationProviding>)serverConfigurationProvider
{
  return g_serverConfigurationProvider;
}

+ (Class<FBSDKAppEventsConfigurationProviding>)appEventsConfigurationProvider
{
  return g_appEventsConfigurationProvider;
}

+ (Class<FBSDKGateKeeperManaging>)gateKeeperManager
{
  return g_gateKeeperManager;
}

+ (Class<FBSDKLogging>)logger
{
  return g_logger;
}

+ (id<FBSDKSettings>)settings
{
  return g_settings;
}

+ (void)setSettings:(id<FBSDKSettings>)settings
{
  g_settings = settings;
}

+ (Class<FBSDKPaymentObserving>)paymentObserver
{
  return g_paymentObserver;
}

+ (void)setPaymentObserver:(Class<FBSDKPaymentObserving>)paymentObserver
{
  g_paymentObserver = paymentObserver;
}

 #if !TARGET_OS_TV

+ (id<FBSDKEventProcessing>)eventProcessor
{
  return g_eventProcessor;
}

 #endif

#endif

@end
