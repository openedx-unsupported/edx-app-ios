#import <UIKit/UIKit.h>
#import <SDWebImage/SDAnimatedImageView+WebCache.h>
#import "ABKCard.h"

@protocol ABKBaseNewsFeedCellDelegate <NSObject>

- (void)refreshTableViewCellHeights;

@end

extern CGFloat ABKNFLabelHorizontalSpace;
extern CGFloat ABKNFLabelVerticalSpace;
extern CGFloat ABKNFTopSpace;

@interface ABKNFBaseCardCell : UITableViewCell

+ (UIColor *)ABKNFDescriptionLabelColor;
+ (UIColor *)ABKNFTitleLabelColor;
+ (UIColor *)ABKNFTitleLabelColorOnGray;

/*!
 * This view displays the card contents and is the base view container for each card. To change or
 * configure the outline of the card like card width, background color board width, etc, you can
 * update this property accordingly.
 */
@property (nonatomic) IBOutlet UIView *rootView;

/*!
 * This is the triangle image which shows if a card has been viewed by the user.
 */
@property (nonatomic) IBOutlet UIImageView *unreadIndicatorView;

@property (nonatomic) id <ABKBaseNewsFeedCellDelegate> delegate;

/*!
 * Card root view related constraints
 */
@property (nonatomic) IBOutlet NSLayoutConstraint *rootViewLeadingConstraint;
@property (nonatomic) IBOutlet NSLayoutConstraint *rootViewTrailingConstraint;
@property (nonatomic) IBOutlet NSLayoutConstraint *rootViewTopConstraint;
@property (nonatomic) IBOutlet NSLayoutConstraint *rootViewBottomConstraint;

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
 * @discussion Initialization of cell called even with storyboard/XIB, exposed for customization.
 */
- (void)setUp;

/*!
 * @discussion Programmatic initialization and layout cell, exposed for customization.
 */
- (void)setUpUI;

/*!
 * @discussion Programmatic initialization and layout of cell rootView, exposed for customization.
 */
- (void)setUpRootView;

/*!
 * @discussion Programmatic initialization and layout of cell border, exposed for customization.
 */
- (void)setUpRootViewBorder;

/*!
 * @discussion Programmatic initialization and layout of unread indicator image, exposed for customization.
 */
- (void)setUpUnreadIndicatorView;

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

/*!
 * @discussion This is a utility method to return the image view class from the ABKImageDelegate.
 */
- (Class)imageViewClass;

@end
