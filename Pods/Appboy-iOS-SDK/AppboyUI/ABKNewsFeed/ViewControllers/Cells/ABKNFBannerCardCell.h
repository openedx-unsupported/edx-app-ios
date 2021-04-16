#import "ABKNFBaseCardCell.h"
#import "ABKBannerCard.h"

@interface ABKNFBannerCardCell : ABKNFBaseCardCell

@property (weak, nonatomic) IBOutlet SDAnimatedImageView *bannerImageView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *imageRatioConstraint;

- (void)applyCard:(ABKCard *)bannerCard;

@end
