#import "ABKBaseContentCardCell.h"
#import "ABKClassicContentCard.h"

@interface ABKClassicContentCardCell : ABKBaseContentCardCell

@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UILabel *descriptionLabel;
@property (weak, nonatomic) IBOutlet UILabel *linkLabel;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *descriptionBottomConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *linkBottomConstraint;

/*!
 * This method adjusts the constraints and hides or shows the link label.
 */
- (void)hideLinkLabel:(BOOL)hide;

- (void)applyCard:(ABKClassicContentCard *)classicCard;

@end
