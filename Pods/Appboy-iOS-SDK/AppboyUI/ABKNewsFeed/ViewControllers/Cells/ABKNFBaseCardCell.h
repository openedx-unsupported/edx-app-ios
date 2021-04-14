#import <UIKit/UIKit.h>
#import <SDWebImage/SDAnimatedImageView+WebCache.h>
#import "ABKCard.h"

@protocol ABKBaseNewsFeedCellDelegate <NSObject>

- (void)refreshTableViewCellHeights;

@end

@interface ABKNFBaseCardCell : UITableViewCell

/*!
 * This view displays the card contents and is the base view container for each card. To change or
 * configure the outline of the card like card width, background color board width, etc, you can
 * update this property accordingly.
 */
@property (weak, nonatomic) IBOutlet UIView *rootView;

/*!
 * This is the triangle image which shows if a card has been viewed by the user.
 */
@property (weak, nonatomic) IBOutlet UIImageView *unreadIndicatorView;

@property (weak, nonatomic) id <ABKBaseNewsFeedCellDelegate> delegate;

/*!
 * Card root view related constraints
 */
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *rootViewLeadingConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *rootViewTrailingConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *rootViewTopConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *rootViewBottomConstraint;

/*!
 * These are basic UI configuration for the News Feed. They are set to the default value in `setUp`
 * method.
 *
 * It's recommended to set the values before the view is displayed.
 */
@property CGFloat cardSidePadding;
@property CGFloat cardSpacing;
@property (nonatomic) BOOL hideUnreadIndicator;

/*!
 * @param tableView The table view which need the cell to diplay the card UI.
 * @param indexPath The index path of the card UI in the table view.
 * @param card The card model for the cell.
 *
 * @discussion This method dequeues and returns the corresponding card cell based on card type from
 * the given table view.
 */
+ (ABKNFBaseCardCell *)dequeueCellFromTableView:(UITableView *)tableView
                                   forIndexPath:(NSIndexPath *)indexPath
                                        forCard:(ABKCard *)card;

/*!
 * @param card The card model for the cell.
 *
 * @discussion Apply the data from the given card to the card cell. 
 */
- (void)applyCard:(ABKCard *)card;

/*!
 * @discussion This is a utility method to return the place holder image.
 */
- (UIImage *)getPlaceHolderImage;
@end
