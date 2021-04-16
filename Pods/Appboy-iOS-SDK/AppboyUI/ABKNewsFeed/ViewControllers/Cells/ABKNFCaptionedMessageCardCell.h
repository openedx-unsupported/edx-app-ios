#import "ABKNFBaseCardCell.h"
#import "ABKCaptionedImageCard.h"
#import "ABKTextAnnouncementCard.h"

@interface ABKNFCaptionedMessageCardCell : ABKNFBaseCardCell

@property (weak, nonatomic) IBOutlet SDAnimatedImageView *captionedImageView;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UILabel *descriptionLabel;
@property (weak, nonatomic) IBOutlet UIView *TitleBackgroundView;
@property (weak, nonatomic) IBOutlet UILabel *linkLabel;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *imageHeightContraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *bodyAndLinkConstraint;

/*!
 * This method adjusts the bodyAndLinkConstraint and hides or shows the link label.
 */
- (void)hideLinkLabel:(BOOL)hide;
- (void)applyCard:(ABKCaptionedImageCard *)captionedImageCard;

@end
