#import "ABKInAppMessageViewController.h"

NS_ASSUME_NONNULL_BEGIN
@interface ABKInAppMessageSlideupViewController : ABKInAppMessageViewController

/*!
 * The UIImageView for the arrow of the in-app message.
 */
@property (weak, nonatomic, nullable) IBOutlet UIImageView *arrowImage;

/*!
 * The offset which controls the slideup in-app message vertical position once visible.
 */
@property (assign, nonatomic) CGFloat offset;

@end
NS_ASSUME_NONNULL_END
