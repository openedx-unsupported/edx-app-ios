#import <Foundation/Foundation.h>

/* ------------------------------------------------------------------------------------------------------
 * Notifications
 */

/*!
 * When the news feed is updated, Appboy will post a notification through the NSNotificationCenter.
 * The name of the notification is the string constant referred to by ABKFeedUpdatedNotification. The
 * userInfo dictionary associated with the notification will has one object, with key the same string
 * as ABKFeedUpdatedIsSuccessfulKey, to indicate whether the update is successful or not.
 *
 * To listen for this notification, you would register an object as an observer of the notification
 * using something like:
 *
 * <pre>
 *   [[NSNotificationCenter defaultCenter] addObserver:self
 *                                            selector:@selector(feedUpdatedNotificationReceived:)
 *                                                name:ABKFeedUpdatedNotification
 *                                              object:nil];
 * </pre>
 *
 * where "feedUpdatedNotificationReceived:" is your callback method for handling the notification:
 *
 * <pre>
 *   - (void)feedUpdatedNotificationReceived:(NSNotification *)notification {
 *     BOOL updateIsSuccessful = [notification.userInfo[ABKFeedUpdatedIsSuccessfulKey] boolValue];
 *     < Do something in response to the notification >
 *   }
 * </pre>
 */
NS_ASSUME_NONNULL_BEGIN
extern NSString *const ABKFeedUpdatedNotification;
extern NSString *const ABKFeedUpdatedIsSuccessfulKey;

/* ------------------------------------------------------------------------------------------------------
 * Enums
 */

/*!
* Values representing the news feed cards' categories recognized by the SDK.
*/
typedef NS_OPTIONS(NSUInteger, ABKCardCategory) {
  ABKCardCategoryNoCategory = 1 << 0,
  ABKCardCategoryNews = 1 << 1,
  ABKCardCategoryAdvertising = 1 << 2,
  ABKCardCategoryAnnouncements = 1 << 3,
  ABKCardCategorySocial = 1 << 4,
  ABKCardCategoryAll = 1 << 0 | 1 << 1 | 1 << 2 | 1 << 3 | 1 << 4
};

/*
 * Braze Public API: ABKFeedController
 */
@interface ABKFeedController : NSObject

/*!
 * The latest cards of Appboy news feed that is saved in memory and disk. Right now the available card types are ABKBannerCard,
 * ABKCaptionedImageCard, ABKClassicCard and ABKTextAnnouncementCard. They are all subclasses
 * of ABKCard.
 */
@property (readonly, getter=getNewsFeedCards) NSArray *newsFeedCards;

/*!
 * The NSDate object that indicates the last time the newsFeedCards property was updated from Appboy server.
 */
@property (readonly, nullable) NSDate *lastUpdate;

/*!
 * This method returns the number of currently active cards which have not been viewed in the given categories.
 * A "view" happens when a card becomes visible in the feed view.  This differentiates
 * between cards which are off-screen in the scrolling view, and those which
 * are on-screen; when a card scrolls onto the screen, it's counted as viewed.
 *
 * Cards are counted as viewed only once -- if a card scrolls off the screen and
 * back on, it's not re-counted.
 *
 * Cards are counted only once even if they appear in multiple feed views or across multiple devices.
 */
- (NSInteger)unreadCardCountForCategories:(ABKCardCategory)categories;

/*!
 * This method returns the total number of currently active cards belongs to given categories. Cards are
 * counted only once even if they appear in multiple feed views.
 */
- (NSInteger)cardCountForCategories:(ABKCardCategory)categories;

/*!
 * @param categories An ABKCardCategory indicating the categories that you want to get. You can pass more than one category
 * at one time by using "|" to separate categories like: ABKCardCategoryNews | ABKCardCategoryAnnouncements | ABKCardCategorySocial
 * @return An array of cards of the given categories.
 *
 * @discussion This method will find the cards of given categories and return them.
 * When the given categories don't exist in any card, this method will return an empty array.
 */
- (NSArray *)getCardsInCategories:(ABKCardCategory)categories;

@end
NS_ASSUME_NONNULL_END
