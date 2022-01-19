#import "ABKBaseContentCardCell.h"
#import "ABKBannerContentCard.h"

@interface ABKBannerContentCardCell : ABKBaseContentCardCell

@property (strong, nonatomic) IBOutlet UIImageView *bannerImageView;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *imageRatioConstraint;

- (void)applyCard:(ABKBannerContentCard *)bannerCard;

@end
