#import "ABKBaseContentCardCell.h"
#import "ABKBannerContentCard.h"
#import <SDWebImage/SDAnimatedImageView+WebCache.h>

@interface ABKBannerContentCardCell : ABKBaseContentCardCell

@property (weak, nonatomic) IBOutlet SDAnimatedImageView *bannerImageView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *imageRatioConstraint;

- (void)applyCard:(ABKBannerContentCard *)bannerCard;

- (void)updateImageConstraintsWithRatio:(CGFloat)newRatio;

@end
