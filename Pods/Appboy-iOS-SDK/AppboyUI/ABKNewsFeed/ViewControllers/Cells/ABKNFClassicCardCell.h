#import "ABKNFBaseCardCell.h"
#import "ABKClassicCard.h"
#import <SDWebImage/SDAnimatedImageView+WebCache.h>

@interface ABKNFClassicCardCell : ABKNFBaseCardCell

@property (weak, nonatomic) IBOutlet SDAnimatedImageView *classicImageView;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UILabel *descriptionLabel;
@property (weak, nonatomic) IBOutlet UILabel *linkLabel;

- (void)applyCard:(ABKClassicCard *)classicCard;

@end
