#import <Foundation/Foundation.h>

/*
 * Braze Public API: ABKContentCard
 */
NS_ASSUME_NONNULL_BEGIN
@interface ABKContentCard : NSObject <NSCopying, NSCoding>

/*!
 * Card's ID.
 */
@property (readonly) NSString *idString;

/*!
 * This property reflects if the card is read or unread by the user.
 */
@property (nonatomic) BOOL viewed;

/*!
 * The property is the unix timestamp of the card's creation time from Braze dashboard.
 */
@property (nonatomic, readonly) double created;

/*!
 * The property is the unix timestamp of the card's expiration time. When the value is less than 0, it means the card
 * doesn't an expire date.
 */
@property (readonly) double expiresAt;

/*!
 * This property reflects if the card can be dismissed by the user.
 */
@property (nonatomic) BOOL dismissible;

/*!
 * This property reflects if the card has been pinned by the user.
 */
@property (nonatomic) BOOL pinned;

/*!
 * This property reflects if the card has been dimissed.
 */
@property (nonatomic) BOOL dismissed;

/*!
 * This property reflects if the card has been clicked.
 */
@property (nonatomic) BOOL clicked;

/*!
 * This property carries extra data in the form of an NSDictionary which can be sent down via the Braze Dashboard.
 * You may want to design and implement a custom handler to access this data depending on your use case.
 */
@property (strong, nullable) NSDictionary *extras;

/*!
 * This property is set to YES if the instance represents a test content card 
 */
@property (nonatomic, readonly) BOOL isTest;

/*!
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

/*!
 * @param cardDictionary The dictionary for card deserialization.
 *
 * Deserializes the dictionary to a card for use by wrappers such as Braze's Unity SDK for iOS.
 * When the deserialization isn't successful, this method returns nil; otherwise, it returns the deserialized card.
 */
+ (nullable ABKContentCard *)deserializeCardFromDictionary:(nullable NSDictionary *)cardDictionary;

/*!
 * Serializes the card to binary data for use by wrappers such as Braze's Unity SDK for iOS.
 */
- (nullable NSData *)serializeToData;

/*!
 * Manually log an impression to Braze for the card.
 * This should only be used for custom content card view controllers.
 */
- (void)logContentCardImpression;

/*!
 * Manually log a click to Braze for the card.
 * This should only be used for custom contentcard view controllers.
 */
- (void)logContentCardClicked;

/*!
 * Manually dismiss a card.
 * It can be done only if the card is dismissable.
 */
- (void)logContentCardDismissed;

- (BOOL)isControlCard;

- (BOOL)hasSameId:(ABKContentCard *)card;

@end
NS_ASSUME_NONNULL_END
