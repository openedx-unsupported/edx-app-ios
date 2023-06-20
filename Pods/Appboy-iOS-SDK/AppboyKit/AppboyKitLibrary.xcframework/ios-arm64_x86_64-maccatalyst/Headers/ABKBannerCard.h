#import "ABKCard.h"

/*
 * Braze Public API: ABKBannerCard
 */
NS_ASSUME_NONNULL_BEGIN
@interface ABKBannerCard : ABKCard <NSCoding>

/* 
 * This property is the URL of the card's image.
 */
@property (copy) NSString *image;

/*
 * The link text for the property url, like @"blog.appboy.com". It can be displayed on the card's
 * UI to indicate the action/direction of clicking on the card.
 */
@property (copy, nullable) NSString *domain;

/*
 * This property is the aspect ratio of the card's image. It is meant to serve as a hint before
 * image loading completes. Note that the property may not be supplied in certain circumstances.
 */
@property float imageAspectRatio;

@end
NS_ASSUME_NONNULL_END
