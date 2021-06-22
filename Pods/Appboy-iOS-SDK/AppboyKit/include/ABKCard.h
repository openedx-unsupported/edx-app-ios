#import <Foundation/Foundation.h>
#import "ABKFeedController.h"

/*
 * Braze Public API: ABKCard
 */
NS_ASSUME_NONNULL_BEGIN
@interface ABKCard : NSObject <NSCopying, NSCoding>

/*
 * Card's ID.
 */
@property (readonly) NSString *idString;

/*
 * This property reflects if the card is read or unread by the user.
 */
@property (nonatomic) BOOL viewed;

/*
 * The property is the unix timestamp of the card's creation time from Braze dashboard.
 */
@property (nonatomic, readonly) double created;

/*
 * The property is the unix timestamp of the card's latest update time from Braze dashboard.
 */
@property (nonatomic, readonly) double updated;

/*
 * The categories assigned to the card.
 */
@property ABKCardCategory categories;

/*
 * The property is the unix timestamp of the card's expiration time. When the value is less than 0, it means the card
 * doesn't an expire date.
 */
@property (readonly) double expiresAt;

/*!
 * This property carries extra data in the form of an NSDictionary which can be sent down via the Braze Dashboard.
 * You may want to design and implement a custom handler to access this data depending on your use case.
 */
@property (strong, nullable) NSDictionary *extras;

//Optional:
/*
 * The URL string that will be opened after the card is clicked on.
 */
@property (copy, nullable) NSString *urlString;

/*!
 * When the card's urlString is not nil, if the property is set to YES, the URL will be opened in a modal WKWebView
 * inside the app. If this property is set to NO, the URL will be opened by the OS and web URLs will be opened in
 * an external web browser app.
 *
 * This property defaults to NO.
 */
@property BOOL openUrlInWebView;

/*
 * @param cardDictionary The dictionary for card deserialization.
 *
 * Deserializes the dictionary to a card for use by wrappers such as Braze's Unity SDK for iOS.
 * When the deserialization isn't successful, this method returns nil; otherwise, it returns the deserialized card.
 */
+ (nullable ABKCard *)deserializeCardFromDictionary:(nullable NSDictionary *)cardDictionary;

/*
 * Serializes the card to binary data for use by wrappers such as Braze's Unity SDK for iOS.
 */
- (nullable NSData *)serializeToData;

/*
 * Manually log an impression to Braze for the card.
 * This should only be used for custom news feed view controller. ABKFeedViewController already has card impression logging.
 */
- (void)logCardImpression;

/*
 * Manually log a click to Braze for the card.
 * This should only be used for custom news feed view controller. ABKFeedViewController already has card click logging.
 * The SDK will only log a card click when the card has the url property with a valid url.
 */
- (void)logCardClicked;

- (BOOL)hasSameId:(ABKCard *)card;

@end
NS_ASSUME_NONNULL_END
