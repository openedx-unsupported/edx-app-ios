#import <Foundation/Foundation.h>
#import "ABKInAppMessage.h"
#import "ABKInAppMessageControllerDelegate.h"
#import "ABKInAppMessageUIControlling.h"

/*! Note: This class is not thread safe and all class methods should be called from the main thread.*/

/*
 * Braze Public API: ABKInAppMessageController
 */
NS_ASSUME_NONNULL_BEGIN
@interface ABKInAppMessageController : NSObject

/*!
 * Setting the delegate allows your app to control how, when, and if in-app messages are displayed.
 * Your app can set the delegate to override the default behavior of the ABKInAppMessageController. See
 * ABKInAppMessageControllerDelegate.h for more information.
 */
@property (weak, nonatomic, nullable) id <ABKInAppMessageControllerDelegate> delegate;

/*!
 * If you have implemented the In-App Message subspec, you can use the ABKInAppMessageUIController to control
 * in-app message behavior. See ABKInAppMessageUIController for more information.
 */
@property (strong, nonatomic, nullable) id<ABKInAppMessageUIControlling> inAppMessageUIController;

/*!
 * This boolean determines if modal in-app messages will be dismissed when the user taps outside of the
 * in-app message.
 *
 * @discussion The default of this value is NO but can be overriden by setting the value of ABKEnableDismissModalOnOutsideTapKey in
 *             appboyOptions or in the Braze dictionary in your Info.plist file.
 */
@property BOOL enableDismissModalOnOutsideTap;

/*!
 * @param delegate The in-app message delegate that implements the ABKInAppMessageControllerDelegate methods. If the delegate is
 * nil, it acts as one which always returns ABKDisplayInAppMessageNow and doesn't implement all other delegate methods.
 *
 * @discussion This method grabs the next in-app message from the in-app message stack, if there is one, and displays it with
 * the provided delegate. The delegate must return a ABKInAppMessageDisplayChoice that defines how the in-app message will be
 * handled. Please refer to the ABKInAppMessageDisplayChoice enum documentation for more detailed information.
 *
 * If there are no in-app messages available this returns immediately having taken no action.
 */
- (void)displayNextInAppMessageWithDelegate:(nullable id<ABKInAppMessageControllerDelegate>)delegate __deprecated_msg("Please use 'displayNextInAppMessage' instead.");

/*!
 * Displays the next in-app message from the in-app message stack.
 *
 * This method pops the next in-app message from the in-app message stack and tries to displays it.
 * When defined, the current delegate methods are executed to respect any custom behavior.
 */
- (void)displayNextInAppMessage;

/*!
 * @return The number of in-app messages that are locally waiting to be displayed.
 *
 * @discussion Use this method to check how many in-app messages are waiting to be displayed and call
 * displayNextInAppMessageWithDelegate: at to display it. If an in-app message is currently being displayed, it will not be included
 * in the count.
 *
 * Note: Returning ABKDisplayInAppMessageLater in the beforeInAppMessageDisplayed: delegate method will put the in-app message back onto
 * the stack and this will be reflected in inAppMessagesRemainingOnStack.
 */
- (NSInteger)inAppMessagesRemainingOnStack;

/*!
 * @discussion This method allows you to request display of an in-app message. It adds the in-app message object to the top of the in-app message stack
 * and tries to display it immediately.
 *
 * If you add an ABKInAppMessage instance that you received through a Braze delegate method - i.e. one that is associated with a campaign or Canvas,
 * then impression and click analytics will work automatically. If you add an ABKInAppMessage instance that you instantiated yourself programmatically
 * (uncommon), then analytics will not be available.
 *
 * @param newInAppMessage the in-app message to add.
 */
- (void)addInAppMessage:(ABKInAppMessage *)newInAppMessage;

@end
NS_ASSUME_NONNULL_END
