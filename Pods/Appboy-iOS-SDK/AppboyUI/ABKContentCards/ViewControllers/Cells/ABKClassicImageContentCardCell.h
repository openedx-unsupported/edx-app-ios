#import "ABKClassicContentCardCell.h"
#import <SDWebImage/SDAnimatedImageView+WebCache.h>

/*!
 * The ABKClassicContentCard has an optional image property.
 * Use this view controller for a classic card with an image and ABKClassicContentCardCell for a
 * classic card without an image.
 */
@interface ABKClassicImageContentCardCell : ABKClassicContentCardCell

@property (weak, nonatomic) IBOutlet SDAnimatedImageView *classicImageView;

- (void)applyCard:(ABKClassicContentCard *)classicCard;

@end
