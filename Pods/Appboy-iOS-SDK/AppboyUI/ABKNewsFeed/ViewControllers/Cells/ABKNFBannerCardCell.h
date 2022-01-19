#import "ABKNFBaseCardCell.h"
#import "ABKBannerCard.h"

@interface ABKNFBannerCardCell : ABKNFBaseCardCell

@property (nonatomic) IBOutlet UIImageView *bannerImageView;
@property (nonatomic) IBOutlet NSLayoutConstraint *imageRatioConstraint;

/*!
 * @discussion Programmatic initialization and layout of the banner imageView, exposed for customization.
 */
- (void)setUpBannerImageView;

- (void)applyCard:(ABKCard *)bannerCard;

@end
