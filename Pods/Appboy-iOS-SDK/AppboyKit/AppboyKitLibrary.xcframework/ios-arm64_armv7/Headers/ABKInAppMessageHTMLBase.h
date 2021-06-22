#import <Foundation/Foundation.h>
#import "ABKInAppMessage.h"

/*
 * Braze Public API: ABKInAppMessageHTMLBase
 */
NS_ASSUME_NONNULL_BEGIN
@interface ABKInAppMessageHTMLBase : ABKInAppMessage

/*!
 * This is the local URL of the assets directory for the HTML in-app message. Please note that the
 * value of this property can be overridden by Braze at the time of displaying, so please don't set
 * it as the value will be discarded.
 */
@property (strong, nonatomic) NSURL *assetsLocalDirectoryPath;

/*!
 * Log a click on the in-app message with a buttonId. HTMLFull in-app messages have the limitation of only
 * handling a single button click, but we allow HTML in-app messages to handle multiple button clicks.
 *
 * @param buttonId the id of the click
 */
- (void)logInAppMessageHTMLClickWithButtonID:(NSString *)buttonId;

@end
NS_ASSUME_NONNULL_END
