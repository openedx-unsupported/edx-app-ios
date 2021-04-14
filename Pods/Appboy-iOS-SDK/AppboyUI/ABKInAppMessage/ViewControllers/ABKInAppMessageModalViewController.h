#import "ABKInAppMessageImmersiveViewController.h"

NS_ASSUME_NONNULL_BEGIN
@interface ABKInAppMessageModalViewController : ABKInAppMessageImmersiveViewController

/*!
 * This boolean determines if the modal in-app message will be dismissed when the user taps outside of the
 * in-app message.
 *
 * @discussion The default of this value is NO but can be overriden by setting the value of ABKEnableDismissModalOnOutsideTapKey in
 *             appboyOptions or in the Appboy dictionary in your Info.plist file.
 */
@property (nonatomic, assign) BOOL enableDismissOnOutsideTap;

/*!
 * The NSLayoutConstraint that specifies the height of the part of the in-app message which houses
 * the image.
 */
@property (retain, nonatomic) IBOutlet NSLayoutConstraint *iconImageHeightConstraint;

@property (retain, nonatomic) IBOutlet NSLayoutConstraint *textsViewWidthConstraint;

@property (strong, nonatomic) IBOutlet UIView *iconImageContainerView;
@property (strong, nonatomic) IBOutlet UIView *graphicImageContainerView;

@end
NS_ASSUME_NONNULL_END
