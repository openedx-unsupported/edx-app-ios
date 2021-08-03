#import <Foundation/Foundation.h>

/*
 * Braze Public API: ABKAppboyIDFADelegate
 */
NS_ASSUME_NONNULL_BEGIN
@protocol ABKIDFADelegate <NSObject>
/*!
 * The result of [[[ASIdentifierManager sharedManager] advertisingIdentifier] UUIDString].
 *
 * @return The current IDFA for the user.
 */
- (NSString *)advertisingIdentifierString;

/*!
 * With iOS 14, the delegate should first check ATTrackingManager on iOS 14 and then check ASIdentifierManager on
 * earlier iOS versions. An example implementation is included with Stopwatch here:
 * https://github.com/Appboy/appboy-ios-sdk/blob/master/Example/Stopwatch/Sources/Utils/IDFADelegate.m
 *
 * @return YES if advertising tracking is enabled for iOS 14 and earlier or if AppTrackingTransparency (ATT) is authorized with iOS 14+, NO otherwise
 */
- (BOOL)isAdvertisingTrackingEnabledOrATTAuthorized;

@end
NS_ASSUME_NONNULL_END
