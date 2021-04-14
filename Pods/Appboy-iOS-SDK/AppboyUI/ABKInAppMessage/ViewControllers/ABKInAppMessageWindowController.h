#import <UIKit/UIKit.h>
#import "Appboy.h"
#import "ABKInAppMessageUIDelegate.h"
#import "ABKInAppMessageWindowController.h"
#import "ABKInAppMessageWindow.h"

NS_ASSUME_NONNULL_BEGIN

// This notification is used to let the InAppMessageUIController know that the InAppMessageWindowController
// was dismissed.
static NSString * const ABKNotificationInAppMessageWindowDismissed = @"inAppMessageWindowDismissedNotification";

static double const InAppMessageAnimationDuration = 0.4;

/*!
 * ABKInAppMessageWindowController is the view controller responsible for housing and displaying
 * ABKInAppMessageViewControllers and performing actions after the in-app message is clicked. Instances 
 * of ABKInAppMessageWindowController are deallocated after the in-app message is dismissed.
 *
 * It will display the given in-app message view controller by animating it onto the screen, and
 * dismiss it by animating it off the screen, by calling the ABKInAppMessageViewController's
 * moveInAppMessageViewOffScreen: and moveInAppMessageViewOnScreen: methods, and log an impression
 * of the in-app message.
 * If the in-app message view controller is an instance of ABKInAppMessageSlideupViewController,
 * ABKInAppMessageModalViewController, or ABKInAppMessageFullViewController, it'll also handle the
 * following behaviors:
 *   * For ABKInAppMessageSlideupViewController:
 *       * set the width of the view controller based on slideup UI style and iPhone devices.
 *       * add a tap gesture recognizer to the in-app message view controller, and handle the clicks on it.
 *       * add a pan gesture recognizer to the in-app message view controller, and handle the panning on it.
 *   * For ABKInAppMessageModalViewController:
 *       * set the background color to be black with alpha 0.9.
 *       * move the in-app view controller to the center.
 *       * when the in-ap message has no buttons, add a tap gesture recognizer to the in-app message
 *         view controller, and handle the clicks on it.
 *       * block the clicks outside of the in-app message view.
 *   * For ABKInAppMessageFullViewController:
 *       * set the in-app message's frame to be full screen.
 *       * when the in-app message has no buttons, add a tap gesture recognizer to the in-app message
 *         view controller, and handle the clicks on it.
 *
 * Additionally, the view controller is responsible for executing that in-app message's specified
 * behavior on click or performing a "custom action", which can be specified through a delegate for
 * the in-app message.
 *
 * After the in-app message is dismissed, ABKInAppMessageWindowController will set the inAppMessageWindow
 * property to nil, and inform ABKInAppMessageUIController to set it's windowController property to
 * nil as well. At that point, the in-app message window's retainer count will drop to 0 and the
 * system will clean it out from the UIApplication's windows array.
 */
@interface ABKInAppMessageWindowController : UIViewController <UIGestureRecognizerDelegate>

/*!
 * The UI window used to display the in-app message.
 */
@property (nonatomic, nullable) IBOutlet ABKInAppMessageWindow *inAppMessageWindow;

/*!
 * The timer used to know when to slide the in-app message off the screen.
 */
@property (nullable) NSTimer *slideAwayTimer;

/*!
 * The in-app message that is being displayed.
 */
@property ABKInAppMessage *inAppMessage;

/*!
 * The optional ABKInAppMessageUIDelegate that can be used to customize display and behavior of the
 * in-app message.
 */
@property (weak, nullable) id<ABKInAppMessageUIDelegate> inAppMessageUIDelegate;

/*!
 * The view controller used to display the in-app message.
 */
@property ABKInAppMessageViewController *inAppMessageViewController;

/*!
 * Properties used to properly place the slideup in-app messages with pan gestures.
 */
@property CGFloat slideupConstraintMaxValue;
@property CGPoint inAppMessagePreviousPanPosition;

/*!
 * The orientation mask that the in-app message supports.
 * The default value is UIInterfaceOrientationMaskAll
 */
@property UIInterfaceOrientationMask supportedOrientationMask;

/*!
 * The preferred orientation for in-app message display.
 * The default is unknown, which means the orientation would be set as Status Bar current orientation.
 */
@property UIInterfaceOrientation preferredOrientation;

/*!
 * The variable that shows if the device is being rotated.
 */
@property BOOL isInRotation;

/*!
 * The variable that shows if the in-app message has been clicked.
 */
@property BOOL inAppMessageIsTapped;

/*!
 * The ID of a button that has been clicked.
 */
@property NSInteger clickedButtonId;

/*!
 * The ID of an HTML button that has been clicked.
 */
@property (nullable) NSString *clickedHTMLButtonId;

- (instancetype)initWithInAppMessage:(ABKInAppMessage *)inAppMessage
          inAppMessageViewController:(ABKInAppMessageViewController *)inAppMessageViewController
                inAppMessageDelegate:(id<ABKInAppMessageUIDelegate>)delegate;
/*!
 * @discussion This method is called when the keyboard is shown when an in-app message is being displayed.
 *
 * For customization, please use a subclass or category to override this method.
 */
- (void)keyboardWasShown;

/*!
 * @discussion This method is called to display the in-app message.
 *
 * For customization, please use a subclass or category to override this method.
 */
- (void)displayInAppMessageViewWithAnimation:(BOOL)withAnimation;

/*!
 * @discussion These methods are called to hide the in-app message.
 *
 * For customization, please use a subclass or category to override one of these methods.
 */
- (void)hideInAppMessageViewWithAnimation:(BOOL)withAnimation;
- (void)hideInAppMessageViewWithAnimation:(BOOL)withAnimation
                        completionHandler:(void (^ __nullable)(void))completionHandler;

/*!
 * @discussion This method is called when an in-app message button is clicked.
 *
 * For customization, please use a subclass or category to override this method.
 */
- (void)inAppMessageClickedWithActionType:(ABKInAppMessageClickActionType)actionType
                                      URL:(nullable NSURL *)url
                         openURLInWebView:(BOOL)openUrlInWebView;
  
NS_ASSUME_NONNULL_END

@end
