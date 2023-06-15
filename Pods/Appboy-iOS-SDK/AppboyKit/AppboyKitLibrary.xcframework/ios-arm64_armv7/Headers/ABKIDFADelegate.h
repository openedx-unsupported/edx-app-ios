#import <Foundation/Foundation.h>

/*
 * Braze Public API: ABKAppboyIDFADelegate
 */
NS_ASSUME_NONNULL_BEGIN
@protocol ABKIDFADelegate <NSObject>
/*!
 * Asks the delegate to return a valid IDFA for the current user.
 *
 * Use this delegate to pass the IDFA to Braze. Braze does not collect IDFA automatically.
 *
 * @return The current users's IDFA UUID.
 */
- (NSString *)advertisingIdentifierString;

/*!
 * Asks the delegate to return whether advertising tracking is enabled for the current user.
 *
 * Your delegate implementation should use ATTrackingManager on iOS 14+ and ASIdentifierManager on earlier iOS versions.
 *
 * An example implementation is available here:
 * https://github.com/Appboy/appboy-ios-sdk/blob/master/Example/Stopwatch/Sources/Utils/IDFADelegate.m
 *
 * @return YES if advertising tracking is enabled for iOS 14 and earlier or if AppTrackingTransparency (ATT) is authorized with iOS 14+, NO otherwise
 */
- (BOOL)isAdvertisingTrackingEnabledOrATTAuthorized;

@end
NS_ASSUME_NONNULL_END
