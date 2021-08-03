#import <Foundation/Foundation.h>
#import "ABKInAppMessage.h"
#import "ABKInAppMessageControllerDelegate.h"

@protocol ABKInAppMessageUIControlling <NSObject>

@optional

/*!
 * @discussion This method sets the optional ABKInAppMessageUIDelegate.
 *
 * To set this delegate, call [[Appboy sharedInstance].inAppMessageController.inAppMessageUIController
 * setInAppMessageUIDelegate: ] after initializing Braze.
 */
- (void)setInAppMessageUIDelegate:(id)uiDelegate;

/*!
 * @discussion This method will hide the in-app message that is currently being displayed.
 *             The animated parameter controls whether or not the in-app message will be animated
 *             away. This method does nothing if no in-app
 *             message is currently being displayed.
 *
 * Note: This will not fire the onInAppMessageDismissed: delegate method.
 *
 * For customization, please use a subclass or category to override this method.
 */
- (void)hideCurrentInAppMessage:(BOOL)animated;

/*!
 * @discussion This method will return the ABKInAppMessageDisplayChoice (see ABKInAppMessageControllerDelegate
 *             for more information) based on whether or not the keyboard is showing.
 *             If you have implemented the beforeInAppMessageDisplayed:withKeyboardIsUp: in
 *             ABKInAppMessageUIDelegate, the choice returned there will override the default choice.
 *
 * For customization, please use a subclass or category to override this method.
 */
- (ABKInAppMessageDisplayChoice)getCurrentDisplayChoiceForInAppMessage:(ABKInAppMessage *)inAppMessage;

/*!
 * @discussion This method will return the ABKInAppMessageDisplayChoice (see ABKInAppMessageControllerDelegate
 *             for more information) based on whether or not the keyboard is showing.
 *
 * For customization, please use a subclass or category to override this method.
 */
- (ABKInAppMessageDisplayChoice)getCurrentDisplayChoiceForControlInAppMessage:(ABKInAppMessage *)controlInAppMessage;

/*!
 * @discussion This method displays the in-app message. We call it when the in-app message has no
 *             image URL, or there is an image URL, and it has already been downloaded. If you call
 *             this method directly and the image hasn't been downloaded, there will be a spinner
 *             animating in the image view.
 *
 * For customization, please use a subclass or category to override this method.
 */
- (void)showInAppMessage:(ABKInAppMessage *)inAppMessage;

/*!
 * @discussion This method returns whether or not an in-app message is currently being shown.
 *
 * For customization, please use a subclass or category to override this method.
 */
- (BOOL)inAppMessageCurrentlyVisible;

@end
