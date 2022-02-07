#import "ABKClassicContentCardCell.h"
#import "ABKUIUtils.h"

@implementation ABKClassicContentCardCell

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
  descriptionLabel.lineBreakMode = NSLineBreakByWordWrapping;
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

- (void)setUp {
  [super setUp];
  self.padding = 25;
}

- (void)setUpUI {
  [super setUpUI];

  // Views
  [self.rootView addSubview:self.titleLabel];
  [self.rootView addSubview:self.descriptionLabel];
  [self.rootView addSubview:self.linkLabel];

  NSLayoutConstraint *titleTrailingConstraint = [self.titleLabel.trailingAnchor constraintEqualToAnchor:self.rootView.trailingAnchor
                                                                                               constant:-self.padding];
  titleTrailingConstraint.priority = ABKContentCardPriorityLayoutRequiredBelowAppleRequired;

  // AutoLayout
  NSArray *constraints = @[
    // Title
    // - Top
    [self.titleLabel.topAnchor constraintEqualToAnchor:self.rootView.topAnchor
                                              constant:17],
    // - Horizontal
    [self.titleLabel.leadingAnchor constraintEqualToAnchor:self.rootView.leadingAnchor
                                                  constant:self.padding],
    titleTrailingConstraint,
    // Description
    // - Top
    [self.descriptionLabel.topAnchor constraintEqualToAnchor:self.titleLabel.bottomAnchor
                                                    constant:6],
    // - Horizontal
    [self.descriptionLabel.leadingAnchor constraintEqualToAnchor:self.titleLabel.leadingAnchor],
    [self.descriptionLabel.trailingAnchor constraintEqualToAnchor:self.titleLabel.trailingAnchor],
    // Link
    // - Horizontal
    [self.linkLabel.leadingAnchor constraintEqualToAnchor:self.titleLabel.leadingAnchor],
    [self.linkLabel.trailingAnchor constraintEqualToAnchor:self.titleLabel.trailingAnchor]
  ];
  [NSLayoutConstraint activateConstraints:constraints];

  self.descriptionConstraints = @[
    [self.descriptionLabel.bottomAnchor constraintEqualToAnchor:self.rootView.bottomAnchor
                                                       constant:-self.padding]
  ];

  self.linkConstraints = @[
    [self.linkLabel.topAnchor constraintEqualToAnchor:self.descriptionLabel.bottomAnchor
                                             constant:8],
    [self.linkLabel.bottomAnchor constraintEqualToAnchor:self.rootView.bottomAnchor
                                                constant:-self.padding]
  ];
}

#pragma mark - ApplyCard

- (void)applyCard:(ABKClassicContentCard *)card {
  if (![card isKindOfClass:[ABKClassicContentCard class]]) {
    return;
  }
  
  [super applyCard:card];
  
  [self applyAppboyAttributedTextStyleFrom:card.title forLabel:self.titleLabel];
  [self applyAppboyAttributedTextStyleFrom:card.cardDescription forLabel:self.descriptionLabel];
  [self applyAppboyAttributedTextStyleFrom:card.domain forLabel:self.linkLabel];
  self.linkLabel.hidden = card.domain.length == 0;

  [self updateConstraintsForCard:card];
}

- (void)updateConstraintsForCard:(ABKClassicContentCard *)card {
  if (card.domain.length == 0) {
    [NSLayoutConstraint deactivateConstraints:self.linkConstraints];
    [NSLayoutConstraint activateConstraints:self.descriptionConstraints];
  } else {
    [NSLayoutConstraint deactivateConstraints:self.descriptionConstraints];
    [NSLayoutConstraint activateConstraints:self.linkConstraints];
  }
}

@end
