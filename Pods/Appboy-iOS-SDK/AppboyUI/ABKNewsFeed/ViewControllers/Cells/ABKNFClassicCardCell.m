#import "ABKNFClassicCardCell.h"
#import "Appboy.h"
#import "ABKImageDelegate.h"
#import "ABKUIUtils.h"

@implementation ABKNFClassicCardCell

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
    _linkLabelColor = [ABKNFBaseCardCell ABKNFDescriptionLabelColor];
  }
  return _linkLabelColor;
}

+ (void)setLinkLabelColor:(UIColor *)linkLabelColor{
  _linkLabelColor = linkLabelColor;
}

#pragma mark - SetUp

- (void)setUpUI {
  [super setUpUI];
  [self setUpClassicImageView];
  [self setUpTitleLabel];
  [self setUpDescriptionLabel];
  [self setUpLinkLabel];
  [self setUpFonts];
}

- (void)setUpClassicImageView {
  self.classicImageView = [[[self imageViewClass] alloc] init];
  self.classicImageView.translatesAutoresizingMaskIntoConstraints = NO;
  [self.rootView addSubview:self.classicImageView];
  [self.classicImageView.heightAnchor constraintEqualToAnchor:self.classicImageView.widthAnchor multiplier:1.0].active = YES;
  [self.classicImageView.leadingAnchor constraintEqualToAnchor:self.rootView.leadingAnchor constant:ABKNFLabelHorizontalSpace].active = YES;
  [self.classicImageView.topAnchor constraintEqualToAnchor:self.rootView.topAnchor constant:ABKNFLabelVerticalSpace].active = YES;
  [self.rootView.bottomAnchor constraintGreaterThanOrEqualToAnchor:self.classicImageView.bottomAnchor constant:ABKNFLabelVerticalSpace].active = YES;
  [self.classicImageView.widthAnchor constraintEqualToAnchor:self.rootView.widthAnchor multiplier:0.177].active = YES;
}

- (void)setUpTitleLabel {
  self.titleLabel = [[UILabel alloc] init];
  self.titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
  self.titleLabel.numberOfLines = 0;
  self.titleLabel.lineBreakMode = NSLineBreakByWordWrapping;
  self.titleLabel.textColor =  [self class].titleLabelColor;
  self.titleLabel.text = @"Title";
  [self.rootView addSubview:self.titleLabel];
  [self.titleLabel.leadingAnchor constraintEqualToAnchor:self.classicImageView.trailingAnchor constant:ABKNFLabelHorizontalSpace].active = YES;
  [self.rootView.trailingAnchor constraintEqualToAnchor:self.titleLabel.trailingAnchor constant:ABKNFLabelHorizontalSpace].active = YES;
  [self.titleLabel.topAnchor constraintEqualToAnchor:self.rootView.topAnchor constant:ABKNFTopSpace].active = YES;
}

- (void)setUpDescriptionLabel {
  self.descriptionLabel = [[UILabel alloc] init];
  self.descriptionLabel.translatesAutoresizingMaskIntoConstraints = NO;
  self.descriptionLabel.numberOfLines = 0;
  self.descriptionLabel.lineBreakMode = NSLineBreakByWordWrapping;
  self.descriptionLabel.textColor = [self class].descriptionLabelColor;
  self.descriptionLabel.text = @"Description";
  [self.rootView addSubview:self.descriptionLabel];
  [self.titleLabel.bottomAnchor constraintEqualToAnchor:self.descriptionLabel.topAnchor].active = YES;
  
  [self.descriptionLabel.leadingAnchor constraintEqualToAnchor:self.titleLabel.leadingAnchor].active = YES;
  [self.descriptionLabel.trailingAnchor constraintEqualToAnchor:self.titleLabel.trailingAnchor].active = YES;
}

- (void)setUpLinkLabel {
  self.linkLabel = [[UILabel alloc] init];
  self.linkLabel.translatesAutoresizingMaskIntoConstraints = NO;
  self.linkLabel.numberOfLines = 0;
  self.linkLabel.lineBreakMode = NSLineBreakByCharWrapping;
  self.linkLabel.textColor = [self class].linkLabelColor;
  self.linkLabel.text = @"Link";
  [self.rootView addSubview:self.linkLabel];
  [self.linkLabel.leadingAnchor constraintEqualToAnchor:self.titleLabel.leadingAnchor].active = YES;
  [self.linkLabel.trailingAnchor constraintEqualToAnchor:self.titleLabel.trailingAnchor].active = YES;
  [self.linkLabel.topAnchor constraintGreaterThanOrEqualToAnchor:self.descriptionLabel.bottomAnchor constant:5].active = YES;
  [self.rootView.bottomAnchor constraintEqualToAnchor:self.linkLabel.bottomAnchor constant:ABKNFTopSpace].active = YES;
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

#pragma mark - ApplyCard

- (void)applyCard:(ABKCard *)card {
  [super applyCard:card];
  if (![card isKindOfClass:[ABKClassicCard class]]) {
    return;
  }
  ABKClassicCard *classicCard = (ABKClassicCard *)card;
  self.titleLabel.text = classicCard.title;
  self.descriptionLabel.text = classicCard.cardDescription;
  self.linkLabel.text = classicCard.domain;
  
  if (![Appboy sharedInstance].imageDelegate) {
    NSLog(@"[APPBOY][WARN] %@ %s",
          @"ABKImageDelegate on Appboy is nil. Image loading may be disabled.",
          __PRETTY_FUNCTION__);
    return;
  }
  [[Appboy sharedInstance].imageDelegate setImageForView:self.classicImageView
                                   showActivityIndicator:NO
                                                 withURL:[NSURL URLWithString:classicCard.image]
                                        imagePlaceHolder:[self getPlaceHolderImage]
                                               completed:nil];
}

- (void)awakeFromNib {
  [super awakeFromNib];
  [self setUpFonts];
}

@end
