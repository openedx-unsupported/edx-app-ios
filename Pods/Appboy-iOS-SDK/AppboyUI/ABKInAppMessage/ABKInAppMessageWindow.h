#import <UIKit/UIKit.h>

/*!
 * ABKInAppMessageWindow handles a subset of all touches.
 *
 * By default, touches not handled by ABKInAppMessageWindow are automatically passed to the next
 * UIWindow in the view hierarchy by UIKit.
 */
@interface ABKInAppMessageWindow : UIWindow

/*!
 * ABKInAppMessageWindow handles all touch events when enabled, no touch events are passed to a next
 * UIWindow.
 */
@property (nonatomic) BOOL handleAllTouchEvents;

@end
