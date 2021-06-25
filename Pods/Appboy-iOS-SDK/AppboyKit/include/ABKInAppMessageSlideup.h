#import "ABKInAppMessage.h"

/*!
 * There are two possible values which control where the in-app message will enter the view.
 *
 *    ABKInAppMessageSlideupFromBottom - This is the default behavior.
 *      The in-app message will slide onto the screen from the bottom edge of the view and will hide by sliding back down off
 *      the bottom of the screen.
 *
 *    ABKInAppMessageSlideupFromTop - The in-app message will slide onto the screen from the top edge of the view and will hide by sliding
 *      back up off the top of the screen.
 */
typedef NS_ENUM(NSInteger, ABKInAppMessageSlideupAnchor) {
  ABKInAppMessageSlideupFromTop,
  ABKInAppMessageSlideupFromBottom
};

/*
 * Braze Public API: ABKInAppMessageSlideup
 */
NS_ASSUME_NONNULL_BEGIN
@interface ABKInAppMessageSlideup : ABKInAppMessage

/*!
 * If hideChevron equals YES, the in-app message will not render the chevron on the right side of the in-app message.
 * The chevron is a useful visual cue for the user that more content may be reached by tapping the in-app message.
 */
@property BOOL hideChevron;

/*!
 * inAppMessageSlideupAnchor defines the position of the in-app message on screen.
 * See the above documentation for ABKInAppMessageAnchor enum documentation above offers additional details.
 */
@property ABKInAppMessageSlideupAnchor inAppMessageSlideupAnchor;

/*!
 * chevronColor defines the chevron arrow color of the in-app message.
 * When this property is nil, the chevron's default color is white.
 */
@property (strong, nullable) UIColor *chevronColor;

@end
NS_ASSUME_NONNULL_END
