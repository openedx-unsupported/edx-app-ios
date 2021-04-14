#import <Foundation/Foundation.h>
#import <WebKit/WebKit.h>
#import "ABKInAppMessageViewController.h"
#import "AppboyKit.h"

NS_ASSUME_NONNULL_BEGIN
/*!
 * The in-app message UI delegate allows you to control the display and behavior of the Braze in-app message.
 */
@protocol ABKInAppMessageUIDelegate <NSObject>

@optional

/*!
 * @param inAppMessage The in-app message object being offered to the delegate method.
 * @param keyboardIsUp This boolean indicates whether or not the keyboard is currently being displayed when this
 * delegate fires.
 * @return ABKInAppMessageDisplayChoice for details refer to the documentation regarding the ENUM ABKInAppMessageDisplayChoice
 * above.
 *
 * This delegate method defines whether the in-app message will be displayed now, displayed later, or discarded.
 *
 * The default behavior is that the in-app message will be displayed unless the keyboard is currently active on the screen.
 * However, if there are other situations where you would not want the in-app message to appear (such as during a full screen
 * game or on a loading screen), you can use this delegate to delay or discard pending in-app message messages.
 *
 * This method is deprecated. Please use the beforeInAppMessageDisplayed: method in ABKInAppMessageControllerDelegate
 * and use the methods receiveKeyboardDidHideNotification: and receiveKeyboardWasShownNotification:
 * in ABKInAppMessageUIController to customize based on keyboard behavior.
 */
- (ABKInAppMessageDisplayChoice)beforeInAppMessageDisplayed:(ABKInAppMessage *)inAppMessage withKeyboardIsUp:(BOOL)keyboardIsUp __deprecated;

/*!
 * @param inAppMessage The in-app message object being offered to the delegate.
 *
 * This delegate method allows host applications to customize the look of an in-app message while
 * maintaining the same user experience and impression/click tracking as the default Braze in-app
 * message. It allows developers to pass incoming in-app messages to custom view controllers which
 * they have created.
 *
 * The custom view controller is responsible for handling any responsive UI layout use-cases. e.g. device orientations,
 * or varied message lengths.
 *
 * Even with a custom view, by inheriting from ABKInAppMessageViewController, the in-app message will automatically animate and
 * dismiss according to the parameters of the provided ABKInAppMessage object. See ABKInAppMessage.h for more information.
 *
 * By default, Braze will add following functions/changes to the custom view controller, and animate
 * the in-app message on and off the screen, based on the class of the given in-app message:
 *   * ABKInAppMessageSlideup:
 *      * stretch/shrink the in-app message view's width to fix the screen's width. If you wish to
 *        have margins between the in-app message and the edge of the screen, those must be incorporated
 *        into the custom view controller itself.
 *      * add the impression and click tracking for the in-app message
 *      * when user clicks on the in-app message, call the onInAppMessageClicked:, and handle the click
 *        behavior correspond to the in-app message's inAppMessageClickActionType property.
 *      * add a pan gesture to the in-app message so user can swipe it away.
 *   * ABKInAppMessageModal:
 *      * make the in-app message clickable when there is no button(s) on it.
 *      * put the in-app message in the center of the screen, and add a full screen background layer.
 *   * ABKInAppMessageFull:
 *      * make the in-app message clickable when there is no button(s) on it.
 *      * stretch/shrink the in-app message view to fix the whole screen.
 *
 * NOTE: The returned view controller should be a ABKInAppMessageViewController or preferably, a subclass of
 * ABKInAppMessageViewController. The view of the returned view controller should be an instance of ABKInAppMessageView or its
 * subclass.
 */
- (ABKInAppMessageViewController *)inAppMessageViewControllerWithInAppMessage:(ABKInAppMessage *)inAppMessage;

/*!
 * @param inAppMessage The in-app message object being offered to the delegate.
 *
 * This delegate method is fired when:
 *   * the user manually dismisses the in-app message.
 *   * the in-app message times out and expires.
 *   * the close button on a modal in-app message or a full in-app message is clicked.
 * Use this method to perform any custom logic that should execute after the in-app message has been
 * dismissed.
 */
- (void)onInAppMessageDismissed:(ABKInAppMessage *)inAppMessage;

/*!
 * @param inAppMessage The in-app message object being offered to the delegate.
 * @return Boolean Value which controls whether or not Braze will execute the click action. Returning YES will prevent
 *         Braze from performing the click action. Returning NO will cause Braze to execute the action defined in the
 *         in-app message's inAppMessageClickActionType property after this delegate method is called.
 *
 * This delegate method is fired when the user clicks on a slideup in-app message, or a modal/full
 * in-app message without button(s) on it. See ABKInAppMessage.h for more information.
 */
- (BOOL)onInAppMessageClicked:(ABKInAppMessage *)inAppMessage;

/*!
 * @param inAppMessage The in-app message object being offered to the delegate.
 * @param button The clicked button being offered to the delegate.
 * @return Boolean Value which controls whether or not Braze will execute the click action. Returning YES will prevent
 *         Braze from performing the click action. Returning NO will cause Braze to execute the action defined in the
 *         button's inAppMessageClickActionType property after this delegate method is called.
 *
 * This delegate method is fired whenever the user clicks a button on the in-app message. See
 * ABKInAppMessageBlock.h for more information.
 */
- (BOOL)onInAppMessageButtonClicked:(ABKInAppMessageImmersive *)inAppMessage button:(ABKInAppMessageButton *)button;

/*!
 * @param inAppMessage The in-app message object being offered to the delegate.
 * @param clickedURL The URL that is clicked by user.
 * @param buttonId The buttonId within the clicked link being offered to the delegate.
 * @return Boolean Value which controls whether or not Braze will execute the click action. Returning YES will prevent
 *         Braze from performing the click action. Returning NO will cause Braze to follow the link.
 *
 * This delegate method is fired whenever the user clicks a link on the HTML in-app message. See
 * ABKInAppMessageHTMLBase.h for more information.
 */
- (BOOL)onInAppMessageHTMLButtonClicked:(ABKInAppMessageHTMLBase *)inAppMessage clickedURL:(nullable NSURL *)clickedURL buttonID:(NSString *)buttonId;

- (WKWebViewConfiguration *)setCustomWKWebViewConfiguration;

@end
NS_ASSUME_NONNULL_END

