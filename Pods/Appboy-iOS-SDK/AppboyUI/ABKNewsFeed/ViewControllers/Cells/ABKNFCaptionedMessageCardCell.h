#import "ABKNFBaseCardCell.h"
#import "ABKCaptionedImageCard.h"
#import "ABKTextAnnouncementCard.h"

@interface ABKNFCaptionedMessageCardCell : ABKNFBaseCardCell

@property (class, nonatomic) UIColor *titleLabelColor;
@property (class, nonatomic) UIColor *descriptionLabelColor;
@property (class, nonatomic) UIColor *linkLabelColor;

@property (nonatomic) IBOutlet UIImageView *captionedImageView;
@property (nonatomic) IBOutlet UILabel *titleLabel;
@property (nonatomic) IBOutlet UILabel *descriptionLabel;
@property (nonatomic) IBOutlet UIView *titleBackgroundView;
@property (nonatomic) IBOutlet UILabel *linkLabel;
@property (nonatomic) IBOutlet NSLayoutConstraint *imageHeightConstraint;
@property (nonatomic) IBOutlet NSLayoutConstraint *bodyAndLinkConstraint;

/*!
 * @discussion Programmatic initialization and layout of the title background view, grey bar that the title label is in.
 * Exposed for customization.
 */
- (void)setUpTitleBackgroundView;

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
 * @discussion Programmatic initialization and layout of image view. Exposed for customization.
 */
- (void)setUpCaptionedImageView;

/*!
 * @discussion Configures fonts of labels with dynamic type on supported versions of iOS uses older font style
 * on earlier versions. Exposed for customization.
 */
- (void)setUpFonts;

/*!
 * This method adjusts the bodyAndLinkConstraint and hides or shows the link label.
 */
- (void)hideLinkLabel:(BOOL)hide;
- (void)applyCard:(ABKCaptionedImageCard *)captionedImageCard;

@end
