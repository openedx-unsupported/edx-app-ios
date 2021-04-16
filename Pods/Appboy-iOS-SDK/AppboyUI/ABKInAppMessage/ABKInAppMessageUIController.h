#import <UIKit/UIKit.h>
#import "ABKInAppMessageUIControlling.h"
#import "ABKInAppMessageUIDelegate.h"
#import "ABKInAppMessageWindowController.h"

@interface ABKInAppMessageUIController : NSObject <ABKInAppMessageUIControlling>

/*!
 * supportedOrientationMask allows you to change which orientation mask the in-app message supports.
 * In-app messages will normally support the orientations specified in the app settings, but the method
 * supportedInterfaceOrientations may optionally override that. The value of supportedOrientationMask will be returned
 * in supportedInterfaceOrientations in the in-app message view controller.
 *
 * The default value of supportedOrientationMask is UIInterfaceOrientationMaskAll.
 */
@property UIInterfaceOrientationMask supportedOrientationMask;

/*!
 * preferredOrientation allows you to select which orientation should be preferred if multiple orientations are supported by the view controller.
 * If set to a value other than UIInterfaceOrientationUnknown, the value of preferredOrientation will be returned by
 * preferredInterfaceOrientationForPresentation in the in-app message view controller.
 * Otherwise, the current status bar orientation will be returned.
 *
 * The default value of preferredOrientation is UIInterfaceOrientationUnknown, which means status bar orientation should be set
 * for in-app message orientation.
 */
@property UIInterfaceOrientation preferredOrientation;

/*!
 * keyboardVisible will have the value YES when the keyboard is shown.
 */
@property BOOL keyboardVisible;

/*!
 * The ABKInAppMessageWindowController that is being shown.
 */
@property (nullable) ABKInAppMessageWindowController *inAppMessageWindowController;

/*!
 * The optional ABKInAppMessageUIDelegate that can be used to specify the UI behaviors of in-app messages.
 */
@property (weak, nullable) id<ABKInAppMessageUIDelegate> uiDelegate;

@end
