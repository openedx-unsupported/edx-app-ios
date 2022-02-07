#import <Foundation/Foundation.h>
#import "ABKInAppMessage.h"

NS_ASSUME_NONNULL_BEGIN
/*!
 * Possible values for in-app message handling after a in-app message is offered to an ABKInAppMessageControllerDelegate
 *   ABKDisplayInAppMessageNow - The in-app message will be displayed immediately.
 *   ABKDisplayInAppMessageLater - The in-app message will be not be displayed and will be placed back onto the top of the stack.
 *   ABKDiscardInAppMessage - The in-app message will be discarded and will not be displayed.
 *
 * The following conditions can cause a in-app message to be offered to the delegate defined by the delegate property on
 * [Appboy sharedInstance].inAppMessageController:
 * - A in-app message is received from the Braze server.
 * - A in-app message is waiting to display when an UIApplicationDidBecomeActiveNotification event occurs.
 * - A in-app message is added by ABKInAppMessageController method addInAppMessage:.
 *
 * You can choose to manually display any in-app messages that are waiting locally to be displayed by calling:
 * [[Appboy sharedInstance].inAppMessageController displayNextInAppMessage].
 */
typedef NS_ENUM(NSInteger, ABKInAppMessageDisplayChoice) {
  ABKDisplayInAppMessageNow,
  ABKDisplayInAppMessageLater,
  ABKDiscardInAppMessage
};

/*!
 * The in-app message delegate allows you to control the display of the Braze in-app message. For more detailed
 * information on in-app message behavior, including when and how the delegate is used, see the documentation for the
 * ABKInAppMessageDisplayChoice enum above for more detailed information.
 *
 * This delegate is for those who are using the Core subspec and not integrating the In-App Message subspec. If
 * you are using the In-App Message subspec, please use ABKInAppMessageUIDelegate.
 */

/*
 * Braze Public API: ABKInAppMessageControllerDelegate
 */
@protocol ABKInAppMessageControllerDelegate <NSObject>

@optional

/*!
 * @param inAppMessage The in-app message object being offered to the delegate method.
 * @return ABKInAppMessageDisplayChoice The in-app message display choice. For details refer to the documentation regarding the ENUM ABKInAppMessageDisplayChoice
 * above.
 *
 * This delegate method defines whether the in-app message will be displayed now, displayed later, or discarded.
 *
 * If there are situations where you would not want the in-app message to appear (such as during a full screen
 * game or on a loading screen), you can use this delegate to delay or discard pending in-app message messages.
 */
- (ABKInAppMessageDisplayChoice)beforeInAppMessageDisplayed:(ABKInAppMessage *)inAppMessage;

/*!
* @param inAppMessage The control in-app message object being offered to the delegate method.
* @return ABKInAppMessageDisplayChoice The control in-app message impression logging choice.
* For details refer to the documentation regarding the ENUM ABKInAppMessageDisplayChoice above.
* Logging a control message impression is an equivalent of displaying the message, except that no actual display occurs.
*
* This delegate method defines the timing of when the control in-app message impression event should be logged: now, later, or discarded.
* Logging a control message impression is an equivalent of displaying the message, except that no actual display occurs.
*
* If there are situations where you would not want the control in-app message impression to be logged, you can use this delegate to delay
* or discard it.
*/
- (ABKInAppMessageDisplayChoice)beforeControlMessageImpressionLogged:(ABKInAppMessage *)inAppMessage;

@end
NS_ASSUME_NONNULL_END
