#import <UIKit/UIKit.h>
#import "AppboyKit.h"
#import "ABKNFBaseCardCell.h"

@interface ABKNewsFeedTableViewController : UITableViewController <ABKBaseNewsFeedCellDelegate>

/*!
 * UI elements which are used in the News Feed table view. You can find them in the News Feed Card Storyboard.
 */
@property (strong, nonatomic) IBOutlet UIView *emptyFeedView;
@property (unsafe_unretained, nonatomic) IBOutlet UILabel *emptyFeedLabel;

/*!
 *  This property allows you to enable or disable the unread indicator on the news feed. The default
 *  value is NO, which will enable the displaying of the unread indicator on cards.
 */
@property (nonatomic) BOOL disableUnreadIndicator;

/*!
 * This property indicates which categories of cards the news feed is displaying.
 * Setting this property will automatically update the news feed page and only display cards in the given categories.
 * This method won't request refresh of cards from the Braze server, but only look into cards that are cached in the SDK.
 */
@property (nonatomic) ABKCardCategory categories;

/*!
 * This property shows the cards displayed in the News Feed. Please note that the News Feed view
 * controller listens to the ABKFeedUpdatedNotification notification from the Braze SDK, which will
 * update the value of this property.
 */
@property (nonatomic) NSArray<ABKCard *> *cards;

/*!
 * This set stores the card IDs for which the impressions have been logged.
 */
@property (nonatomic) NSMutableSet<NSString *> *cardImpressions;

/*!
 * This property defines the timeout for stored News Feed cards in the Braze SDK. If the cards in the
 * Braze SDK are older than this value, the News Feed view controller will request a News Feed update.
 *
 * The default value is 60 seconds.
 */
@property NSTimeInterval cacheTimeout;

@property id constraintWarningValue;

/*!
 * @discussion This method returns an instance of ABKNewsFeedTableViewController. You can call it
 * to get a News Feed view controller for your navigation controller.
 */
+ (instancetype)getNavigationFeedViewController;

/*!
 * @discussion This method returns the localized string from AppboyFeedLocalizable.strings file.
 * You can easily override the localized string by adding the keys and the translations to your own
 * Localizable.strings file.
 *
 * To do custom handling with the Appboy localized string, you can override this method in a
 * subclass.
 */
- (NSString *)localizedAppboyFeedString:(NSString *)key;

/*!
 * @discussion This method handles the user's click on the card.
 *
 * To do custom handling with the card clicks, you can override this method in a
 * subclass. You also need to call [card logCardClicked] manually inside of your new method
 * to send the click event to the Braze server.
 */
- (void)handleCardClick:(ABKCard *)card;

@end
