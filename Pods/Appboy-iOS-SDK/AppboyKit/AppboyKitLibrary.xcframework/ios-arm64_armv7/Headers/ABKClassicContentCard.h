#import "ABKContentCard.h"

NS_ASSUME_NONNULL_BEGIN
@interface ABKClassicContentCard : ABKContentCard <NSCoding>

/*
 * The URL of the card's image.
 */
@property (copy, nullable) NSString *image;

/*
 * The news title text for the card.
 */
@property (copy) NSString *title;

/*
 * The description text for the card.
 */
@property (copy) NSString *cardDescription;

/*
 * The link text for the property url, like @"blog.appboy.com". It can be displayed on the card's
 * UI to indicate the action/direction of clicking on the card.
 */
@property (copy, nullable) NSString *domain;

@end
NS_ASSUME_NONNULL_END
