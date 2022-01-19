#import <Foundation/Foundation.h>

/* ------------------------------------------------------------------------------------------------------
 * Notifications
 */

/*!
 * When Content Cards are updated, Braze will post a notification through the NSNotificationCenter.
 * The name of the notification is the string constant referred to by ABKContentCardsProcessedNotification. The
 * userInfo dictionary associated with the notification will has one object, with key the same string
 * as ABKContentCardsProcessedIsSuccessfulKey, to indicate whether the update is successful or not.
 *
 * To listen for this notification, you would register an object as an observer of the notification
 * using something like:
 *
 * <pre>
 *   [[NSNotificationCenter defaultCenter] addObserver:self
 *                                            selector:@selector(contentCardsUpdatedNotificationReceived:)
 *                                                name:ABKContentCardsProcessedNotification
 *                                              object:nil];
 * </pre>
 *
 * where "contentCardsUpdatedNotificationReceived:" is your callback method for handling the notification:
 *
 * <pre>
 *   - (void)contentCardsUpdatedNotificationReceived:(NSNotification *)notification {
 *     BOOL updateIsSuccessful = [notification.userInfo[ABKContentCardsProcessedIsSuccessfulKey] boolValue];
 *     < Check if update was successful and do something in response to the notification >
 *   }
 * </pre>
 */
NS_ASSUME_NONNULL_BEGIN

extern NSString *const ABKContentCardsProcessedNotification;
extern NSString *const ABKContentCardsProcessedIsSuccessfulKey;

/*
 * Braze Public API: ABKContentCardsController
 */
@interface ABKContentCardsController : NSObject

/*!
 * The latest content cards that are saved in memory and disk.
 */
@property (readonly, getter=getContentCards) NSArray *contentCards;

/*!
 * The NSDate object that indicates the last time the contentCards property was updated from Braze server.
 */
@property (readonly, nullable) NSDate *lastUpdate;

/*!
 * Returns the count of unviewed cards, excluding control cards.
 * A "view" happens when a card becomes visible in the Content Cards view.  This differentiates
 * between cards which are off-screen in the scrolling view, and those which
 * are on-screen; when a card scrolls onto the screen, it's counted as viewed.
 *
 * Cards are counted as viewed only once -- if a card scrolls off the screen and
 * back on, it's not re-counted.
 *
 * Cards are counted only once even if they appear in multiple Content Cards views or across multiple devices.
 */
- (NSInteger)unviewedContentCardCount;

/*!
 * Returns the count of available cards, including control cards.
 * Cards are counted only once even if they appear in multiple Content Cards views.
 */
- (NSInteger)contentCardCount;

@end

NS_ASSUME_NONNULL_END
