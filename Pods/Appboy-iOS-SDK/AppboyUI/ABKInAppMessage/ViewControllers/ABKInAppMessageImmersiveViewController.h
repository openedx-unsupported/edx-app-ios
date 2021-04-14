#import "ABKInAppMessageViewController.h"
#import "ABKInAppMessageUIButton.h"

// Customize this to set the font for the in-app message header.
#define HeaderLabelDefaultFont [UIFont boldSystemFontOfSize:20.0]

NS_ASSUME_NONNULL_BEGIN
@interface ABKInAppMessageImmersiveViewController : ABKInAppMessageViewController

/*!
 * The UILabel for the in-app message header.
 */
@property (weak, nonatomic) IBOutlet UILabel *inAppMessageHeaderLabel;

/*!
 * The UIImageView for the in-app message image.
 */
@property (weak, nonatomic, nullable) IBOutlet UIImageView *graphicImageView;

/*!
 * The NSLayoutConstraint that specifies the space between the header and rest of the in-app message.
 */
@property (nonatomic) IBOutlet NSLayoutConstraint *headerBodySpaceConstraint;

/*!
 * The UIButton on the left of the in-app message.
 * When there is only one button in the in-app message, this left button is the one that is used.
 */
@property (retain, nonatomic, nullable) IBOutlet ABKInAppMessageUIButton *leftInAppMessageButton;

/*!
 * The UIButton on the right of the in-app message.
 */
@property (retain, nonatomic, nullable) IBOutlet ABKInAppMessageUIButton *rightInAppMessageButton;

/*!
 * The UIScrollView for the message of the in-app message.
 */
@property (nonatomic, nullable) IBOutlet UIScrollView *textsView;

/*!
 * @discussion This method is used for setting up the layout for ABKInAppMessageGraphic image style.
 *
 * For customization, please use a subclass or category to override this method.
 */
- (void)setupLayoutForGraphic;

/*!
 * @discussion This method is used for setting up the layout for ABKInAppMessageTopImage image style.
 *
 * For customization, please use a subclass or category to override this method.
 */
- (void)setupLayoutForTopImage;

/*!
 * @discussion This method is used for setting the color of the close button.
 *
 * For customization, please use a subclass or category to override this method.
 */
- (void)changeCloseButtonColor;

/*!
 * @discussion The touch up inside action for the close button. The default behavior is to close the
 *             in-app message.
 *
 * For customization, please use a subclass or category to override this method.
 */
- (IBAction)dismissInAppMessage:(id)sender;

/*!
 * @discussion The touch up inside action for the in-app message buttons.
 *
 * For customization, please use a subclass or category to override this method.
 */
- (IBAction)buttonClicked:(ABKInAppMessageUIButton *)button;

@end
NS_ASSUME_NONNULL_END
