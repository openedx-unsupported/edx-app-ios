#import <UIKit/UIKit.h>
#import "ABKContentCard.h"

@protocol ABKBaseContentCardCellDelegate <NSObject>

- (void)cellRequestSizeUpdate:(UITableViewCell *)cell;

@end

@interface ABKBaseContentCardCell : UITableViewCell

/*!
 * This view displays the card contents and is the base view container for each card. To change or
 * configure the outline of the card like card width, background color board width, etc, you can
 * update this property accordingly.
 */
@property (nonatomic) IBOutlet UIView *rootView;

/*!
 * This is the triangle image which shows if a card has been viewed by the user.
 */
@property (nonatomic) IBOutlet UIImageView *pinImageView;

/*!
 * This is the blue line under unviewed cards.
 */
@property (nonatomic) IBOutlet UIView *unviewedLineView;
@property (nonatomic) UIColor *unviewedLineViewColor;

/*!
 * Card root view related constraints
 */
@property (nonatomic) IBOutlet NSLayoutConstraint *rootViewLeadingConstraint;
@property (nonatomic) IBOutlet NSLayoutConstraint *rootViewTrailingConstraint;
@property (nonatomic) IBOutlet NSLayoutConstraint *rootViewTopConstraint;
@property (nonatomic) IBOutlet NSLayoutConstraint *rootViewBottomConstraint;

@property (nonatomic) IBOutlet NSLayoutConstraint *cardWidthConstraint;

/*!
 * These are basic UI configuration for the Content Cards feed. They are set to the default values in the
 * `setUp` method.
 *
 * It's recommended to set the values before the view is displayed.
 */
@property (nonatomic, assign) CGFloat cardSidePadding;
@property (nonatomic, assign) CGFloat cardSpacing;
@property (nonatomic, assign) BOOL hideUnreadIndicator;

/*!
 * To communicate back after any cell updates occur
 */
@property (weak, nonatomic) id <ABKBaseContentCardCellDelegate> delegate;

/*!
 * @param card The card model for the cell.
 *
 * @discussion Apply the data from the given card to the card cell. 
 */
- (void)applyCard:(ABKContentCard *)card;

/*!
 * @discussion This is a utility method to return the place holder image.
 */
- (UIImage *)getPlaceHolderImage;

- (Class)imageViewClass;

/*!
 * @discussion initialization that always occurs for the content card cells
 */
- (void)setUp;

/*!
 * @discussion Initialization that is in place of Storyboard or XIB initialization.
 *             This method should call all the property specific setUp methods.
 */
- (void)setUpUI;

/*!
 * @discussion This is a utility method to make text styled.
 */
- (void)applyAppboyAttributedTextStyleFrom:(NSString *)text forLabel:(UILabel *)label;

@end

static const UILayoutPriority ABKContentCardPriorityLayoutRequiredBelowAppleRequired = UILayoutPriorityRequired - 1;

