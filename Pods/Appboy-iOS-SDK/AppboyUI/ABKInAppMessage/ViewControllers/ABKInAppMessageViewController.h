#import <UIKit/UIKit.h>
#import "ABKInAppMessage.h"

// Customize this to set the font for the in-app message message.
#define MessageLabelDefaultFont [UIFont systemFontOfSize:14.0]

static const CGFloat InAppMessageShadowBlurRadius = 4.0f;
static const CGFloat InAppMessageShadowOpacity = 0.3f;
static const CGFloat InAppMessageSelectedOpacity = 0.8f;

NS_ASSUME_NONNULL_BEGIN
@interface ABKInAppMessageViewController : UIViewController

/*!
 * The in-app message that is being displayed in the view controller.
 */
@property (strong) ABKInAppMessage *inAppMessage;

/*!
 * The UIImageView for the in-app message image.
 */
@property (weak, nonatomic) IBOutlet UIImageView *iconImageView;

/*!
 * The UILabel for the in-app message icon.
 */
@property (weak, nonatomic) IBOutlet UILabel *iconLabelView;

/*!
 * The UILabel for the in-app message message.
 */
@property (weak, nonatomic) IBOutlet UILabel *inAppMessageMessageLabel;

/*!
 * This is YES if the device being used is an iPad, and NO if the device is not an iPad.
 */
@property BOOL isiPad;

/*!
 * @discussion This method is used for passing the in-app message property to any custom view
 *             controller.
 */
- (instancetype)initWithInAppMessage:(ABKInAppMessage *)inAppMessage;

/*!
 * @discussion This method is used to decide whether the in-app message will be animated off the screen.
 *             If YES, the in-app message will animate off the screen. If NO, the in-app message will
 *             disappear immediately without animation.
 *
 * For customization, please use a subclass or category to override this method.
 */
- (void)hideInAppMessage:(BOOL)animated;

/*
 * @discussion This method is called right before an in-app message view is going to be animated and
 *             removed from screen. You can use this method to change the in-app message view's
 *             constraints and call the `layoutIfNeeded` method in the `moveInAppMessageViewOffScreen`
 *             method to animate the constraint changes.
 *
 * For customization, please use a subclass or category to override this method.
 * You must implement this method in a custom view controller.
 * The default implementation of the method does nothing.
 */
- (void)beforeMoveInAppMessageViewOffScreen;

/*
 * @discussion This method is called when an in-app message view is going to be removed from the
 *             screen. You can use this method to control the in-app message view's
 *             animation by setting the off-screen position and status of the in-app message view, for
 *             example, by setting the alpha of the view to 0.
 *
 * For customization, please use a subclass or category to override this method.
 * You must implement this method in a custom view controller.
 * The default implementation of the method does nothing.
 */
- (void)moveInAppMessageViewOffScreen;

/*
 * @discussion This method is called right before the in-app message view is going to be animated and
 *             displayed on the screen. You can use this method to change the in-app message view's
 *             constraints and call the `layoutIfNeeded` method in the `moveInAppMessageViewOnScreen`
 *             method to animate the constraint changes.
 *
 * For customization, please use a subclass or category to override this method.
 * You must implement this method in a custom view controller.
 * The default implementation of the method does nothing.
 */
- (void)beforeMoveInAppMessageViewOnScreen;

/*
 * @discussion This method is called when in-app message view is going to displayed on the screen. You
 *             can use this method to control the in-app message view's animation by setting the on-
 *             screen position and status of the in-app message view, for example by moving the in-app
 *             message view to the center of the screen or setting the alpha of the view to 1.
 *
 * For customization, please use a subclass or category to override this method.
 * You must implement this method in a custom view controller.
 * The default implementation of the method does nothing.
 */
- (void)moveInAppMessageViewOnScreen;

/*
 * @discussion This method sets the image of the in-app message.
 *
 * For customization, please use a subclass or category to override this method.
 */
- (BOOL)applyImageToImageView:(UIImageView *)iconImageView;

/*
 * @discussion This method sets the icon of the in-app message.
 *
 * For customization, please use a subclass or category to override this method.
 */
- (BOOL)applyIconToLabelView:(UILabel *)iconLabelView;

@end
NS_ASSUME_NONNULL_END
