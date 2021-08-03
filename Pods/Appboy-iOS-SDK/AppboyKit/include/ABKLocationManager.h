#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

@class ABKServerConfig;

NS_ASSUME_NONNULL_BEGIN

@interface ABKLocationManager : NSObject <CLLocationManagerDelegate>

/*!
 * Use ABKEnableAutomaticLocationCollectionKey to enable automatic location tracking.
 * For more information, please refer to Appboy.h.
 */
@property (readonly) BOOL enableLocationTracking;

/*!
 * Use ABKEnableGeofencesKey to enable geofences.
 * For more information, please refer to Appboy.h.
 */
@property (readonly) BOOL enableGeofences;

/*!
 * Use ABKDisableAutomaticGeofenceRequestsKey to disable automatic geofence requests.
 * For more information, please refer to requestGeofencesWithLongitude:latitude: in Appboy.h
 */
@property (readonly) BOOL disableAutomaticGeofenceRequests;

/*!
 * Calling this method will log a location using the regular location provider if a location is reported in under
 * 60 seconds. After 60 seconds expires the regular location provider will stop collecting location.
 */
- (void)logSingleLocation;

@end
NS_ASSUME_NONNULL_END
