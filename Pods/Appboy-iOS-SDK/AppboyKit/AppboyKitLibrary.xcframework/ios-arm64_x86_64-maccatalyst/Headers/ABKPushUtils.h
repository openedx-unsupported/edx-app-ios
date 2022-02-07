#if !TARGET_OS_TV
#import <Foundation/Foundation.h>
#import <UserNotifications/UserNotifications.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/*
 * Braze Public API: ABKPushUtils
 */
@interface ABKPushUtils : NSObject

/*!
 * @param response The UNNotificationResponse passed to userNotificationCenter:didReceiveNotificationResponse:withCompletionHandler:.
 *
 * @return YES if the user notification was sent from Braze servers.
 */
+ (BOOL)isAppboyUserNotification:(UNNotificationResponse *)response API_AVAILABLE(ios(10.0), macCatalyst(14.0));

/*!
 * @param userInfo The userInfo dictionary passed to application:didReceiveRemoteNotification:fetch​Completion​Handler:
 *                 or application:didReceiveRemoteNotification:.
 *
 * @return YES if the push notification was sent from Braze servers.
 */
+ (BOOL)isAppboyRemoteNotification:(NSDictionary *)userInfo;

/*!
 * @param userInfo The userInfo dictionary passed to application:didReceiveRemoteNotification:fetchCompletionHandler:
 *                 or application:didReceiveRemoteNotification:.
 *
 * @return YES if the push notification was sent by Braze for an internal feature.
 *
 * @discussion Braze uses content-available silent notifications for internal features. You can use this method to ensure
 *             your app doesn't take any undesired or unnecessary actions upon receiving Braze's internal content-available notifications
 *             (e.g., pinging your server for content).
 */
+ (BOOL)isAppboyInternalRemoteNotification:(NSDictionary *)userInfo;

/*!
 * @param response The UNNotificationResponse passed to userNotificationCenter:didReceiveNotificationResponse:withCompletionHandler:.
 *
 * @return YES if the user notification was sent by Braze for uninstall tracking.
 *
 * @discussion Uninstall tracking notifications are content-available silent notifications. You can use this method to ensure 
 *             your app doesn't take any undesired or unnecessary actions upon receiving Braze's uninstall tracking notifications
 *             (e.g., pinging your server for content).
 */
+ (BOOL)isUninstallTrackingUserNotification:(UNNotificationResponse *)response API_AVAILABLE(ios(10.0), macCatalyst(14.0));

/*!
 * @param userInfo The userInfo dictionary passed to application:didReceiveRemoteNotification:fetchCompletionHandler:
 *                 or application:didReceiveRemoteNotification:.
 *
 * @return YES if the push notification was sent by Braze for uninstall tracking.
 *
 * @discussion Uninstall tracking notifications are content-available silent notifications. You can use this method to ensure
 *             your app doesn't take any undesired or unnecessary actions upon receiving Braze's uninstall tracking notifications
 *             (e.g., pinging your server for content).
 */
+ (BOOL)isUninstallTrackingRemoteNotification:(NSDictionary *)userInfo;

/*!
 * @param response The UNNotificationResponse passed to userNotificationCenter:didReceiveNotificationResponse:withCompletionHandler:.
 *
 * @return YES if the user notification was sent by Braze for syncing geofences.
 *
 * @discussion Geofence sync notifications are content-available silent notifications. You can use this method to ensure
 *             your app doesn't take any undesired or unnecessary actions upon receiving Braze's geofence sync notifications
 *             (e.g., pinging your server for content).
 */
+ (BOOL)isGeofencesSyncUserNotification:(UNNotificationResponse *)response API_AVAILABLE(ios(10.0), macCatalyst(14.0));

/*!
 * @param userInfo The userInfo dictionary passed to application:didReceiveRemoteNotification:fetchCompletionHandler:
 *                 or application:didReceiveRemoteNotification:.
 *
 * @return YES if the push notification was sent by Braze for syncing geofences.
 *
 * @discussion Geofence sync notifications are content-available silent notifications. You can use this method to ensure
 *             your app doesn't take any undesired or unnecessary actions upon receiving Braze's geofence sync notifications
 *             (e.g., pinging your server for content).
 */
+ (BOOL)isGeofencesSyncRemoteNotification:(NSDictionary *)userInfo;

/*!
 * @param userInfo The userInfo dictionary passed to application:didReceiveRemoteNotification:fetch​Completion​Handler:
 *
 * @return YES if the push notification was sent by Braze and is silent.
 */
+ (BOOL)isAppboySilentRemoteNotification:(NSDictionary *)userInfo;

/*!
 * @param userInfo The userInfo dictionary passed to application:didReceiveRemoteNotification:fetchCompletionHandler:
 *                 or application:didReceiveRemoteNotification:.
 *
 * @return YES if the push notification was sent by Braze for push stories.
 */
+ (BOOL)isPushStoryRemoteNotification:(NSDictionary *)userInfo;

+ (BOOL)notificationContainsContentCard:(NSDictionary *)userInfo;

/*!
 * @param userInfo The userInfo dictionary payload.
 *
 * @return YES if the notification contains an a flag that inticates the device should fetch test triggers from the server.
 *
 */
+ (BOOL)shouldFetchTestTriggersFlagContainedInPayload:(NSDictionary *)userInfo __deprecated;

/*!
 * @return A set of the default UNNotificationCategories used by Braze.
 */
+ (NSSet<UNNotificationCategory *> *)getAppboyUNNotificationCategorySet API_AVAILABLE(ios(10.0), macCatalyst(14.0));

+ (NSSet<UIUserNotificationCategory *> *)getAppboyUIUserNotificationCategorySet __deprecated_msg("Please use `getAppboyUNNotificationCategorySet` instead.");

@end
NS_ASSUME_NONNULL_END
#endif
