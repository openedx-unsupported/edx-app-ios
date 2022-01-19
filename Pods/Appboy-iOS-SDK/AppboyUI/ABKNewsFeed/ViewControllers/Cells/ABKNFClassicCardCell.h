#import "ABKNFBaseCardCell.h"
#import "ABKClassicCard.h"

@interface ABKNFClassicCardCell : ABKNFBaseCardCell

@property (class, nonatomic) UIColor *titleLabelColor;
@property (class, nonatomic) UIColor *descriptionLabelColor;
@property (class, nonatomic) UIColor *linkLabelColor;

@property (nonatomic) IBOutlet UIImageView *classicImageView;
@property (nonatomic) IBOutlet UILabel *titleLabel;
@property (nonatomic) IBOutlet UILabel *descriptionLabel;
@property (nonatomic) IBOutlet UILabel *linkLabel;

/*!
 * @discussion Programmatic initialization and layout of image view. Exposed for customization.
 */
- (void)setUpClassicImageView;

/*!
 * @discussion Programmatic initialization and layout of the title label. Exposed for customization.
 */
- (void)setUpTitleLabel;

/*!
 * @discussion Programmatic initialization and layout of the description label. Exposed for customization.
 */
- (void)setUpDescriptionLabel;

/*!
 * @discussion Programmatic initialization and layout of the link label. Exposed for customization.
 */
- (void)setUpLinkLabel;

/*!
 * @discussion Configures fonts of labels with dynamic type on supported versions of iOS uses older font style
 * on earlier versions. Exposed for customization.
 */
- (void)setUpFonts;

- (void)applyCard:(ABKClassicCard *)classicCard;

@end
