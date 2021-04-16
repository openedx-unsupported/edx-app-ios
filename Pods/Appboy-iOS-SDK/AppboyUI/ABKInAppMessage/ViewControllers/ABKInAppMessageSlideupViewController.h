#import "ABKInAppMessageViewController.h"

NS_ASSUME_NONNULL_BEGIN
@interface ABKInAppMessageSlideupViewController : ABKInAppMessageViewController

/*!
 * The UIImageView for the arrow of the in-app message.
 */
@property (weak, nonatomic, nullable) IBOutlet UIImageView *arrowImage;

/*!
 * The constraint which controls the slideup in-app message animate in and out of the screen.
 */
@property (weak, nonatomic, nullable) IBOutlet NSLayoutConstraint *slideConstraint;

@end
NS_ASSUME_NONNULL_END
