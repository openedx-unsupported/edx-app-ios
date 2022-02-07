#import "ABKNFCaptionedMessageCardCell.h"
#import "Appboy.h"
#import "ABKImageDelegate.h"
#import "ABKUIUtils.h"

@implementation ABKNFCaptionedMessageCardCell

- (void)awakeFromNib {
  [super awakeFromNib];

  // DynamicType
  self.titleLabel.font = [ABKUIUtils preferredFontForTextStyle:UIFontTextStyleTitle3 weight:UIFontWeightBold];
  self.titleLabel.adjustsFontForContentSizeCategory = YES;
  self.descriptionLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline];
  self.descriptionLabel.adjustsFontForContentSizeCategory = YES;
  self.linkLabel.font = [ABKUIUtils preferredFontForTextStyle:UIFontTextStyleSubheadline weight:UIFontWeightBold];
  self.linkLabel.adjustsFontForContentSizeCategory = YES;

  // Bug: On Mac Catalyst 13, allowsDefaultTighteningForTruncation defaults to YES
  // - Occurs only if numberOfLine is not 0
  // - Default value should be NO (see documentation – https://apple.co/3bZFc8q)
  // - Might be fixed in a later version
  self.titleLabel.allowsDefaultTighteningForTruncation = NO;
}

- (void)hideLinkLabel:(BOOL)hide {
  self.linkLabel.hidden = hide;
  self.bodyAndLinkConstraint.constant = hide ? 0 : 13;
}

- (void)applyCard:(ABKCard *)card {
  [super applyCard:card];
  if ([card isKindOfClass:[ABKCaptionedImageCard class]]) {
    [self applyCaptionedImageCard:(ABKCaptionedImageCard *)card];
  } else if ([card isKindOfClass:[ABKTextAnnouncementCard class]]) {
    [self applyTextAnnouncementCard:(ABKTextAnnouncementCard *)card];
  }
}

- (void)applyCaptionedImageCard:(ABKCaptionedImageCard *)captionedImageCard {
  self.titleLabel.text = captionedImageCard.title;
  self.descriptionLabel.text = captionedImageCard.cardDescription;
  self.linkLabel.text = captionedImageCard.domain;
  BOOL shouldHideLink = captionedImageCard.domain == nil || captionedImageCard.domain.length == 0;
  [self hideLinkLabel:shouldHideLink];
  
  CGFloat currImageHeightConstraint = self.captionedImageView.frame.size.width / captionedImageCard.imageAspectRatio;
  
  self.imageHeightContraint.constant = currImageHeightConstraint;
  [self setNeedsUpdateConstraints];
  [self setNeedsDisplay];
  
  if (![Appboy sharedInstance].imageDelegate) {
    NSLog(@"[APPBOY][WARN] %@ %s",
          @"ABKImageDelegate on Appboy is nil. Image loading may be disabled.",
          __PRETTY_FUNCTION__);
    return;
  }
  typeof(self) __weak weakSelf = self;
  [[Appboy sharedInstance].imageDelegate setImageForView:self.captionedImageView
                                   showActivityIndicator:NO
                                                 withURL:[NSURL URLWithString:captionedImageCard.image]
                                        imagePlaceHolder:nil
                                               completed:^(UIImage * _Nullable image,
                                                           NSError * _Nullable error,
                                                           NSInteger cacheType,
                                                           NSURL * _Nullable imageURL) {
    if (weakSelf == nil) {
      return;
    }
    if (image) {
      dispatch_async(dispatch_get_main_queue(), ^{
        CGFloat newImageHeightConstraint = weakSelf.captionedImageView.frame.size.width * image.size.height / image.size.width;
        if (fabs(newImageHeightConstraint - currImageHeightConstraint) > 5e-1) {
          weakSelf.imageHeightContraint.constant = newImageHeightConstraint;
          [weakSelf setNeedsUpdateConstraints];
          [weakSelf setNeedsDisplay];
          // Force a redraw, as SDWebImage 5+ consistently gets the original constraint wrong.
          [weakSelf.delegate refreshTableViewCellHeights];
        }
      });
    } else {
      dispatch_async(dispatch_get_main_queue(), ^{
        weakSelf.captionedImageView.image = [weakSelf getPlaceHolderImage];
      });
    }
  }];
}

- (void)applyTextAnnouncementCard:(ABKTextAnnouncementCard *)textAnnouncementCard {
  self.titleLabel.text = textAnnouncementCard.title;
  self.descriptionLabel.text = textAnnouncementCard.cardDescription;
  self.linkLabel.text = textAnnouncementCard.domain;
  BOOL shouldHideLink = textAnnouncementCard.domain == nil || textAnnouncementCard.domain.length == 0;
  [self hideLinkLabel:shouldHideLink];
  
  self.imageHeightContraint.constant = 0;
  [self setNeedsLayout];
}

@end
