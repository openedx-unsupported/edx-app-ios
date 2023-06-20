#import "ABKContentCard.h"

@interface ABKBannerContentCard : ABKContentCard <NSCoding>

/*
 * The URL of the card's image.
 */
@property (copy) NSString *image;

/*
 * This property is the aspect ratio of the card's image. It is meant to serve as a hint before
 * image loading completes. Note that the property may not be supplied in certain circumstances.
 */
@property float imageAspectRatio;

@end
