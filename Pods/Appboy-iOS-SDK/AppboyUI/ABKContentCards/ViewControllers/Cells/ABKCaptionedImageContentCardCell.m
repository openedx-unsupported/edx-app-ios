#import "ABKCaptionedImageContentCardCell.h"
#import "Appboy.h"
#import "ABKImageDelegate.h"
#import "ABKUIUtils.h"

@interface ABKCaptionedImageContentCardCell ()

@property (strong, nonatomic) NSArray *descriptionConstraints;
@property (strong, nonatomic) NSArray *linkConstraints;

@end


@implementation ABKCaptionedImageContentCardCell

static UIColor *_titleLabelColor = nil;
static UIColor *_descriptionLabelColor = nil;
static UIColor *_linkLabelColor = nil;

+ (UIColor *)titleLabelColor {
  if (_titleLabelColor == nil) {
    if (@available(iOS 13.0, *)) {
      _titleLabelColor = [UIColor labelColor];
    } else {
      _titleLabelColor = [UIColor blackColor];
    }
  }
  return _titleLabelColor;
}

+ (void)setTitleLabelColor:(UIColor *)titleLabelColor {
  _titleLabelColor = titleLabelColor;
}

+ (UIColor *)descriptionLabelColor {
  if (_descriptionLabelColor == nil) {
    if (@available(iOS 13.0, *)) {
      _descriptionLabelColor = [UIColor labelColor];
    } else {
      _descriptionLabelColor = [UIColor blackColor];
    }
  }
  return _descriptionLabelColor;
}

+ (void)setDescriptionLabelColor:(UIColor *)descriptionLabelColor {
  _descriptionLabelColor = descriptionLabelColor;
}

+ (UIColor *)linkLabelColor {
  if (_linkLabelColor == nil) {
    if (@available(iOS 13.0, *)) {
      _linkLabelColor = [UIColor linkColor];
    } else {
      _linkLabelColor = [UIColor systemBlueColor];
    }
  }
  return _linkLabelColor;
}

+ (void)setLinkLabelColor:(UIColor *)linkLabelColor{
  _linkLabelColor = linkLabelColor;
}

#pragma mark - Properties

- (UIImageView *)captionedImageView {
  if (_captionedImageView != nil) {
    return _captionedImageView;
  }

  UIImageView *captionedImageView = [[[self imageViewClass] alloc] init];
  captionedImageView.contentMode = UIViewContentModeScaleAspectFit;
  captionedImageView.translatesAutoresizingMaskIntoConstraints = NO;
  _captionedImageView = captionedImageView;
  return captionedImageView;
}

- (UILabel *)titleLabel {
  if (_titleLabel != nil) {
    return _titleLabel;
  }

  UILabel *titleLabel = [[UILabel alloc] init];
  titleLabel.font = [ABKUIUtils preferredFontForTextStyle:UIFontTextStyleCallout weight:UIFontWeightBold];
  titleLabel.textColor = [self class].titleLabelColor;
  titleLabel.text = @"Title";
  titleLabel.numberOfLines = 0;
  titleLabel.lineBreakMode = NSLineBreakByWordWrapping;
  titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
  _titleLabel = titleLabel;
  return titleLabel;
}

- (UILabel *)descriptionLabel {
  if (_descriptionLabel != nil) {
    return _descriptionLabel;
  }

  UILabel *descriptionLabel = [[UILabel alloc] init];
  descriptionLabel.font = [ABKUIUtils preferredFontForTextStyle:UIFontTextStyleFootnote weight:UIFontWeightRegular];
  descriptionLabel.textColor = [self class].descriptionLabelColor;
  descriptionLabel.text = @"Description";
  descriptionLabel.numberOfLines = 0;
  descriptionLabel.translatesAutoresizingMaskIntoConstraints = NO;
  _descriptionLabel = descriptionLabel;
  return descriptionLabel;
}

- (UILabel *)linkLabel {
  if (_linkLabel != nil) {
    return _linkLabel;
  }

  UILabel *linkLabel = [[UILabel alloc] init];
  linkLabel.font = [ABKUIUtils preferredFontForTextStyle:UIFontTextStyleFootnote weight:UIFontWeightMedium];
  linkLabel.textColor = [self class].linkLabelColor;
  linkLabel.text = @"Link";
  linkLabel.numberOfLines = 0;
  linkLabel.lineBreakMode = NSLineBreakByCharWrapping;
  linkLabel.translatesAutoresizingMaskIntoConstraints = NO;
  _linkLabel = linkLabel;
  return linkLabel;
}

#pragma mark - SetUp

- (void)setUpUI {
  [super setUpUI];

  // Views
  [self.rootView addSubview:self.captionedImageView];
  [self.rootView addSubview:self.titleLabel];
  [self.rootView addSubview:self.descriptionLabel];
  [self.rootView addSubview:self.linkLabel];

  // - Remove / add pinImageView to reset it
  [self.pinImageView removeFromSuperview];
  [self.rootView addSubview:self.pinImageView];

  // AutoLayout

  self.imageRatioConstraint = [self.captionedImageView.heightAnchor constraintEqualToAnchor:self.captionedImageView.widthAnchor];
  self.imageRatioConstraint.priority = UILayoutPriorityDefaultHigh;

  NSArray *constraints = @[
    // Captioned Image
    [self.captionedImageView.topAnchor constraintEqualToAnchor:self.rootView.topAnchor],
    [self.captionedImageView.leadingAnchor constraintEqualToAnchor:self.rootView.leadingAnchor],
    [self.captionedImageView.trailingAnchor constraintEqualToAnchor:self.rootView.trailingAnchor],
    self.imageRatioConstraint,

    // Pin Image
    [self.pinImageView.topAnchor constraintEqualToAnchor:self.captionedImageView.bottomAnchor],
    [self.pinImageView.trailingAnchor constraintEqualToAnchor:self.rootView.trailingAnchor],
    [self.pinImageView.widthAnchor constraintEqualToConstant:20],
    [self.pinImageView.heightAnchor constraintEqualToConstant:20],

    // Title
    [self.titleLabel.topAnchor constraintEqualToAnchor:self.captionedImageView.bottomAnchor
                                              constant:17],
    [self.titleLabel.leadingAnchor constraintEqualToAnchor:self.rootView.leadingAnchor
                                                  constant:25],
    [self.titleLabel.trailingAnchor constraintEqualToAnchor:self.rootView.trailingAnchor
                                                   constant:-25],

    // Description
    [self.descriptionLabel.topAnchor constraintEqualToAnchor:self.titleLabel.bottomAnchor
                                                    constant:6],
    [self.descriptionLabel.leadingAnchor constraintEqualToAnchor:self.titleLabel.leadingAnchor],
    [self.descriptionLabel.trailingAnchor constraintEqualToAnchor:self.titleLabel.trailingAnchor],

    // Link
    [self.linkLabel.leadingAnchor constraintEqualToAnchor:self.titleLabel.leadingAnchor],
    [self.linkLabel.trailingAnchor constraintEqualToAnchor:self.titleLabel.trailingAnchor]
  ];
  [NSLayoutConstraint activateConstraints:constraints];

  self.descriptionConstraints = @[
    [self.descriptionLabel.bottomAnchor constraintEqualToAnchor:self.rootView.bottomAnchor
                                                       constant:-25]
  ];

  self.linkConstraints = @[
    [self.linkLabel.topAnchor constraintEqualToAnchor:self.descriptionLabel.bottomAnchor
                                             constant:8],
    [self.linkLabel.bottomAnchor constraintEqualToAnchor:self.rootView.bottomAnchor
                                                constant:-25]
  ];
}

#pragma mark - ApplyCard

- (void)applyCard:(ABKCaptionedImageContentCard *)card {
  if (![card isKindOfClass:[ABKCaptionedImageContentCard class]]) {
    return;
  }
  
  [super applyCard:card];
  [self applyAppboyAttributedTextStyleFrom:card.title forLabel:self.titleLabel];
  [self applyAppboyAttributedTextStyleFrom:card.cardDescription forLabel:self.descriptionLabel];
  [self applyAppboyAttributedTextStyleFrom:card.domain forLabel:self.linkLabel];
  self.linkLabel.hidden = card.domain.length == 0;

  [self updateConstraintsForCard:card];
  [self updateImageConstraintIfNeededWithAspectRatio:card.imageAspectRatio];
  
  if (![Appboy sharedInstance].imageDelegate) {
    NSLog(@"[APPBOY][WARN] %@ %s",
          @"ABKImageDelegate on Appboy is nil. Image loading may be disabled.",
          __PRETTY_FUNCTION__);
    return;
  }
  typeof(self) __weak weakSelf = self;
  [[Appboy sharedInstance].imageDelegate setImageForView:self.captionedImageView
                                   showActivityIndicator:NO
                                                 withURL:[NSURL URLWithString:card.image]
                                        imagePlaceHolder:[self getPlaceHolderImage]
                                               completed:^(UIImage * _Nullable image,
                                                           NSError * _Nullable error,
                                                           NSInteger cacheType,
                                                           NSURL * _Nullable imageURL) {
    dispatch_async(dispatch_get_main_queue(), ^{
      typeof(self) __strong strongSelf = weakSelf;
      if (strongSelf == nil) {
        return;
      }

      if (image == nil) {
        strongSelf.captionedImageView.image = [strongSelf getPlaceHolderImage];
        return;
      }

      CGFloat aspectRatio = image.size.width / image.size.height;
      card.imageAspectRatio = aspectRatio;
      [strongSelf updateImageConstraintIfNeededWithAspectRatio:aspectRatio];
    });
  }];
}

- (void)updateConstraintsForCard:(ABKCaptionedImageContentCard *)card {
  if (card.domain.length == 0) {
    [NSLayoutConstraint deactivateConstraints:self.linkConstraints];
    [NSLayoutConstraint activateConstraints:self.descriptionConstraints];
  } else {
    [NSLayoutConstraint deactivateConstraints:self.descriptionConstraints];
    [NSLayoutConstraint activateConstraints:self.linkConstraints];
  }
}

- (void)updateImageConstraintIfNeededWithAspectRatio:(CGFloat)aspectRatio {
  if (aspectRatio == 0 || ABK_CGFLT_EQ(self.imageRatioConstraint.multiplier, 1 / aspectRatio)) {
    return;
  }

  self.imageRatioConstraint.active = NO;
  self.imageRatioConstraint = [self.captionedImageView.heightAnchor constraintEqualToAnchor:self.captionedImageView.widthAnchor
                                                                                multiplier:1 / aspectRatio];
  self.imageRatioConstraint.priority = UILayoutPriorityDefaultHigh;
  self.imageRatioConstraint.active = YES;
  [self.delegate cellRequestSizeUpdate:self];
}

@end
