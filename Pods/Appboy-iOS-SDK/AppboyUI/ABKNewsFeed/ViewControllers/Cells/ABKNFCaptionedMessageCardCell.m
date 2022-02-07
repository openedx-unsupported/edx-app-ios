#import "ABKNFCaptionedMessageCardCell.h"
#import "Appboy.h"
#import "ABKImageDelegate.h"
#import "ABKUIUtils.h"

@implementation ABKNFCaptionedMessageCardCell

static UIColor *_titleLabelColor = nil;
static UIColor *_descriptionLabelColor = nil;
static UIColor *_linkLabelColor = nil;

+ (UIColor *)titleLabelColor {
  if (_titleLabelColor == nil) {
    _titleLabelColor = [ABKNFBaseCardCell ABKNFTitleLabelColor];
  }
  return _titleLabelColor;
}

+ (void)setTitleLabelColor:(UIColor *)titleLabelColor {
  _titleLabelColor = titleLabelColor;
}

+ (UIColor *)descriptionLabelColor {
  if (_descriptionLabelColor == nil) {
    _descriptionLabelColor = [ABKNFBaseCardCell ABKNFDescriptionLabelColor];
  }
  return _descriptionLabelColor;
}

+ (void)setDescriptionLabelColor:(UIColor *)descriptionLabelColor {
  _descriptionLabelColor = descriptionLabelColor;
}

+ (UIColor *)linkLabelColor {
  if (_linkLabelColor == nil) {
    _linkLabelColor = [ABKUIUtils dynamicColorForLightColor:[UIColor blackColor] darkColor:[UIColor whiteColor]];
  }
  return _linkLabelColor;
}

+ (void)setLinkLabelColor:(UIColor *)linkLabelColor{
  _linkLabelColor = linkLabelColor;
}

#pragma mark - SetUp

- (void)setUpUI {
  [super setUpUI];
  [self setUpTitleBackgroundView];
  [self setUpTitleLabel];
  [self setUpDescriptionLabel];
  [self setUpLinkLabel];
  [self setUpCaptionedImageView];
  [self setUpFonts];
}

- (void)setUpTitleBackgroundView {
  self.titleBackgroundView = [[UIView alloc] init];
  self.titleBackgroundView.translatesAutoresizingMaskIntoConstraints = NO;
  if (@available(iOS 13.0, *)) {
    self.titleBackgroundView.backgroundColor = [UIColor systemGroupedBackgroundColor];
  } else {
    self.titleBackgroundView.backgroundColor = [UIColor groupTableViewBackgroundColor];
  }
  [self.rootView addSubview:self.titleBackgroundView];
  [self.titleBackgroundView.leadingAnchor constraintEqualToAnchor:self.rootView.leadingAnchor].active = YES;
  [self.titleBackgroundView.trailingAnchor constraintEqualToAnchor:self.rootView.trailingAnchor].active = YES;
  [self.unreadIndicatorView removeFromSuperview];
  [self.titleBackgroundView addSubview:self.unreadIndicatorView];
  [self.unreadIndicatorView.topAnchor constraintEqualToAnchor:self.titleBackgroundView.topAnchor].active = YES;
  [self.unreadIndicatorView.trailingAnchor constraintEqualToAnchor:self.titleBackgroundView.trailingAnchor].active = YES;
}

- (void)setUpTitleLabel {
  self.titleLabel = [[UILabel alloc] init];
  self.titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
  self.titleLabel.textColor = [self class].titleLabelColor;
  self.titleLabel.text = @"Title";
  self.titleLabel.numberOfLines = 2;
  self.titleLabel.lineBreakMode = NSLineBreakByTruncatingTail;
  [self.titleBackgroundView addSubview:self.titleLabel];
  [self.titleLabel setContentCompressionResistancePriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisVertical];
  [self.titleLabel setContentHuggingPriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisVertical];
  [self.titleLabel.leadingAnchor constraintEqualToAnchor:self.titleBackgroundView.leadingAnchor constant:ABKNFLabelHorizontalSpace].active = YES;
  [self.titleBackgroundView.trailingAnchor constraintEqualToAnchor:self.titleLabel.trailingAnchor constant:ABKNFLabelHorizontalSpace].active = YES;
  [self.titleLabel.topAnchor constraintEqualToAnchor:self.titleBackgroundView.topAnchor constant:10].active = YES;
  [self.titleBackgroundView.bottomAnchor constraintEqualToAnchor:self.titleLabel.bottomAnchor constant:10].active = YES;
}

- (void)setUpDescriptionLabel {
  self.descriptionLabel = [[UILabel alloc] init];
  self.descriptionLabel.textColor = [self class].descriptionLabelColor;
  self.descriptionLabel.text = @"Description";
  self.descriptionLabel.translatesAutoresizingMaskIntoConstraints = NO;
  self.descriptionLabel.numberOfLines = 0;
  self.descriptionLabel.lineBreakMode = NSLineBreakByWordWrapping;
  [self.descriptionLabel setContentHuggingPriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisVertical];
  [self.rootView addSubview:self.descriptionLabel];
  [self.descriptionLabel.leadingAnchor constraintEqualToAnchor:self.rootView.leadingAnchor constant:ABKNFLabelHorizontalSpace].active = YES;
  [self.rootView.trailingAnchor constraintEqualToAnchor:self.descriptionLabel.trailingAnchor constant:ABKNFLabelHorizontalSpace].active = YES;
  [self.descriptionLabel.topAnchor constraintEqualToAnchor:self.titleBackgroundView.bottomAnchor constant:ABKNFLabelVerticalSpace].active = YES;
  [self.rootView.bottomAnchor constraintGreaterThanOrEqualToAnchor:self.descriptionLabel.bottomAnchor constant:ABKNFLabelVerticalSpace].active = YES;
}

- (void)setUpLinkLabel {
  self.linkLabel = [[UILabel alloc] init];
  self.linkLabel.textColor = [self class].linkLabelColor;
  self.linkLabel.text = @"Link";
  self.linkLabel.translatesAutoresizingMaskIntoConstraints = NO;
  self.linkLabel.numberOfLines = 0;
  self.linkLabel.lineBreakMode = NSLineBreakByCharWrapping;
  [self.rootView addSubview:self.linkLabel];
  [self.linkLabel.leadingAnchor constraintEqualToAnchor:self.rootView.leadingAnchor constant:ABKNFLabelHorizontalSpace].active = YES;
  [self.rootView.trailingAnchor constraintEqualToAnchor:self.linkLabel.trailingAnchor constant:ABKNFLabelHorizontalSpace].active = YES;
  [self.linkLabel.topAnchor constraintEqualToAnchor:self.descriptionLabel.bottomAnchor constant:ABKNFLabelVerticalSpace].active = YES;
  self.bodyAndLinkConstraint = [self.rootView.bottomAnchor constraintEqualToAnchor:self.linkLabel.bottomAnchor constant:ABKNFLabelVerticalSpace];
  self.bodyAndLinkConstraint.active = YES;
}

- (void)setUpCaptionedImageView {
  self.captionedImageView = [[[self imageViewClass] alloc] init];
  self.captionedImageView.contentMode = UIViewContentModeScaleAspectFit;
  self.captionedImageView.translatesAutoresizingMaskIntoConstraints = NO;
  [self.rootView addSubview:self.captionedImageView];
  [self.captionedImageView setContentHuggingPriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisVertical];
  [self.captionedImageView setContentCompressionResistancePriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisVertical];
  [self.captionedImageView.leadingAnchor constraintEqualToAnchor:self.rootView.leadingAnchor].active = YES;
  [self.captionedImageView.trailingAnchor constraintEqualToAnchor:self.rootView.trailingAnchor].active = YES;
  [self.captionedImageView.topAnchor constraintEqualToAnchor:self.rootView.topAnchor].active = YES;
  NSLayoutConstraint *bottom = [self.captionedImageView.bottomAnchor constraintEqualToAnchor:self.titleBackgroundView.topAnchor];
  bottom.priority = UILayoutPriorityDefaultHigh;
  bottom.active = YES;
  self.imageHeightConstraint = [self.captionedImageView.heightAnchor constraintEqualToConstant:223];
  self.imageHeightConstraint.active = YES;
}

- (void)setUpFonts {
  // DynamicType
  self.titleLabel.font = [ABKUIUtils preferredFontForTextStyle:UIFontTextStyleTitle3 weight:UIFontWeightBold];
  [ABKUIUtils enableAdjustsFontForContentSizeCategory:self.titleLabel];
  self.descriptionLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline];
  [ABKUIUtils enableAdjustsFontForContentSizeCategory:self.descriptionLabel];
  self.linkLabel.font = [ABKUIUtils preferredFontForTextStyle:UIFontTextStyleSubheadline weight:UIFontWeightBold];
  [ABKUIUtils enableAdjustsFontForContentSizeCategory:self.linkLabel];

  // Bug: On Mac Catalyst 13, allowsDefaultTighteningForTruncation defaults to YES
  // - Occurs only if numberOfLine is not 0
  // - Default value should be NO (see documentation – https://apple.co/3bZFc8q)
  // - Might be fixed in a later version
  self.titleLabel.allowsDefaultTighteningForTruncation = NO;
}

- (void)hideLinkLabel:(BOOL)hide {
  self.linkLabel.hidden = hide;
  self.bodyAndLinkConstraint.constant = hide ? 0 : ABKNFLabelVerticalSpace;
}

#pragma mark - ApplyCard

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
  self.imageHeightConstraint.constant = currImageHeightConstraint;
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
          weakSelf.imageHeightConstraint.constant = newImageHeightConstraint;
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
  
  self.imageHeightConstraint.constant = 0;
  [self setNeedsLayout];
}

- (void)awakeFromNib {
  [super awakeFromNib];
  [self setUpFonts];
}

@end
