#import "ABKContentCard.h"

@interface ABKBannerContentCard : ABKContentCard <NSCoding>

/*
 * The URL of the card's image.
 */
@property (copy) NSString *image;

/*
 * This property is the aspect ratio of the card's image.
 */
@property float imageAspectRatio;

@end
