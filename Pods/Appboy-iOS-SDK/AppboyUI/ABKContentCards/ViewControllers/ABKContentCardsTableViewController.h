#import <UIKit/UIKit.h>
#import "AppboyKit.h"
#import "ABKBaseContentCardCell.h"

@protocol ABKContentCardsTableViewControllerDelegate;

@interface ABKContentCardsTableViewController : UITableViewController

/*!
 * UI elements which are used in the Content Cards table view. You can find them in the Content Cards Storyboard.
 */
@property (strong, nonatomic) IBOutlet UIView *emptyFeedView;
@property (weak, nonatomic) IBOutlet UILabel *emptyFeedLabel;

/*!
 * The ABKContentCardsTableViewController delegate
 */
@property (weak, nonatomic) id<ABKContentCardsTableViewControllerDelegate> delegate;

/*!
 * This property stores the cards displayed in the Content Cards feed. By default, the view controller
 * updates this value when it receives an ABKContentCardsProcessedNotification notification from the Braze SDK.
 *
 * This field's value should not be set directly from a subclass; instead, it should be set from within a populateContentCards:
 * implementation.
 */
@property (nonatomic) NSMutableArray<ABKContentCard *> *cards;

/*!
 *  This property allows you to enable or disable the unread indicator on the cards. The default
 *  value is NO, which will enable the displaying of the unread indicator on cards.
 */
@property (assign, nonatomic) BOOL disableUnreadIndicator;

/*!
 * This property defines the timeout for stored Content Cards in the Braze SDK. If the cards in the
 * Braze SDK are older than this value, the Content Cards view controller will request a Content Cards update.
 *
 * The default value is 60 seconds.
 */
@property NSTimeInterval cacheTimeout;

/*!
 * If set, this property overrides the maximum width of Content Cards set by the storyboard.
 */
@property (assign, nonatomic) CGFloat maxContentCardWidth;

/*!
 * This boolean determines if the Content Card will attempt to use dark theme colors, granted the device
 * is in dark mode.
 *
 * @discussion The default of this value is YES but can be overriden before the view controller is presented
 *             to ensure that the dark theme is disabled for any Content Card displayed.
 */
@property (assign, nonatomic) BOOL enableDarkTheme;

/*!
 * @discussion This method returns an instance of ABKContentCardsTableViewController. You can call it
 * to get a Content Cards view controller for your navigation controller.
 */
+ (instancetype)getNavigationContentCardsViewController;

/*!
 * @discussion This method returns the localized string from AppboyContentCardsLocalizable.strings file.
 * You can easily override the localized string by adding the keys and the translations to your own
 * Localizable.strings file.
 *
 * To do custom handling with the Appboy localized string, you can override this method in a
 * subclass.
 */
- (NSString *)localizedAppboyContentCardsString:(NSString *)key;

/*!
 * @param tableView The table view which need the cell to diplay the card UI.
 * @param indexPath The index path of the card UI in the table view.
 * @param card The card model for the cell.
 *
 * @discussion This method dequeues and returns the corresponding card cell based on card type from
 * the given table view.
 */
+ (ABKBaseContentCardCell *)dequeueCellFromTableView:(UITableView *)tableView
                                        forIndexPath:(NSIndexPath *)indexPath
                                             forCard:(ABKContentCard *)card;

/*!
 * @discussion This method handles the user's click on the card.
 *
 * If you wish to handle card clicks yourself, refer to ABKContentCardsTableViewControllerDelegate's
 * contentCardTableViewController:shouldHandleCardClick: method.
 *
 * @warning Overriding handleCardClick: yourself might prevent
 * ABKContentCardsTableViewControllerDelegate's contentCardTableViewController:shouldHandleCardClick:
 * and contentCardTableViewController:didHandleCardClick: from firing properly.
 *
 * If you decide to override this method, you must call [card logContentCardClicked] manually inside of your
 * new method to send the click event to the Braze server.
 */
- (void)handleCardClick:(ABKContentCard *)card;

- (void)requestNewCardsIfTimeout;

/*!
 * @discussion This method is called when the cards stored in the cards property should be refreshed.
 */
- (void)populateContentCards;

@end


@protocol ABKContentCardsTableViewControllerDelegate <NSObject>

@optional

/*!
 * Asks the delegate if the Appboy SDK should handle the content card click action.
 *
 * @warning This method might not be called if you overrode handleCardClick:
 *
 * @param viewController The view controller displaying the content card.
 * @param url The content card's url.
 * @return YES to let the Appboy SDK handle the click action, NO if you wish to handle the click action
 *         yourself.
 */
- (BOOL)contentCardTableViewController:(ABKContentCardsTableViewController *)viewController
                 shouldHandleCardClick:(NSURL *)url;

/*!
 * Informs the delegate that the content card click action was handled by the Appboy SDK.
 *
 * This method is not called if the delegate method `contentCardTableViewController:shouldHandleCardClick:`
 * returns NO.
 *
 * @warning This method might not be called if you overrode handleCardClick:
 *
 * @param viewController The view controller displaying the content card.
 * @param url The content card's url.
 */
- (void)contentCardTableViewController:(ABKContentCardsTableViewController *)viewController
                    didHandleCardClick:(NSURL *)url;

@end
