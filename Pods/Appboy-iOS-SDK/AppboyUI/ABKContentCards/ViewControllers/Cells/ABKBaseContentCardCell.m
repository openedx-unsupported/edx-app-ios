#import "ABKBaseContentCardCell.h"
#import "ABKUIUtils.h"
#import "Appboy.h"
#import "ABKImageDelegate.h"

static CGFloat AppboyCardSidePadding = 10.0;
static CGFloat AppboyCardSpacing = 32.0;
static CGFloat AppboyCardBorderWidth = 0.5;
static CGFloat AppboyCardCornerRadius = 3.0;
static CGFloat AppboyCardShadowXOffset = 0.0;
static CGFloat AppboyCardShadowYOffset = -2.0;
static CGFloat AppboyCardShadowOpacity = 0.5;
static CGFloat AppboyCardLineSpacing = 1.2;

@implementation ABKBaseContentCardCell

#pragma mark - Properties

- (UIView *)rootView {
  if (_rootView != nil) {
    return _rootView;
  }

  // View
  UIView *rootView = [[UIView alloc] init];
  rootView.translatesAutoresizingMaskIntoConstraints = NO;
  if (@available(iOS 13.0, *)) {
    rootView.backgroundColor = [UIColor systemBackgroundColor];
  } else {
    rootView.backgroundColor = [UIColor whiteColor];
  }

  // - Border
  UIColor *lightBorderColor = [UIColor colorWithWhite:(224.0 / 255.0) alpha:1.0];
  UIColor *darkBorderColor = [UIColor colorWithWhite:(85.0 / 255.0) alpha:1.0];

  CALayer *rootLayer = rootView.layer;
  rootLayer.masksToBounds = YES;
  rootLayer.cornerRadius = AppboyCardCornerRadius;
  rootLayer.borderWidth = AppboyCardBorderWidth;
  rootLayer.borderColor = [ABKUIUtils dynamicColorForLightColor:lightBorderColor
                                                      darkColor:darkBorderColor].CGColor;

  // - Shadow
  UIColor *shadowColor = [UIColor colorWithWhite:(178.0 / 255.0) alpha:1.0];
  rootLayer.shadowColor = shadowColor.CGColor;
  rootLayer.shadowOffset = CGSizeMake(AppboyCardShadowXOffset, AppboyCardShadowYOffset);
  rootLayer.shadowOpacity = AppboyCardShadowOpacity;

  _rootView = rootView;
  return rootView;
}

- (UIImageView *)pinImageView {
  if (_pinImageView != nil) {
    return _pinImageView;
  }

  NSBundle *bundle = [ABKUIUtils bundle:[ABKBaseContentCardCell class]
                                channel:ABKContentCardChannel];
  UIImage *pinImage = [UIImage imageNamed:@"appboy_cc_icon_pinned"
                                 inBundle:bundle
            compatibleWithTraitCollection:nil];
  pinImage = [pinImage imageFlippedForRightToLeftLayoutDirection];

  UIImageView *pinImageView = [[UIImageView alloc] initWithImage:pinImage];
  pinImageView.contentMode = UIViewContentModeScaleToFill;
  pinImageView.translatesAutoresizingMaskIntoConstraints = NO;
  _pinImageView = pinImageView;
  return pinImageView;
}

- (UIView *)unviewedLineView {
  if (_unviewedLineView != nil) {
    return _unviewedLineView;
  }

  UIView *unviewedLineView = [[UIView alloc] init];
  unviewedLineView.backgroundColor = self.unviewedLineViewColor;
  unviewedLineView.translatesAutoresizingMaskIntoConstraints = NO;
  _unviewedLineView = unviewedLineView;
  return unviewedLineView;
}

#pragma mark - Initialization

- (instancetype)initWithStyle:(UITableViewCellStyle)style
              reuseIdentifier:(NSString *)reuseIdentifier {
  self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
  if (self) {
    [self setUp];
    [self setUpUI];
  }

  return  self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
  if (self = [super initWithCoder:aDecoder]) {
    [self setUp];
  }
  return self;
}

#pragma mark - SetUp

- (void)setUp {
  self.backgroundColor = [UIColor clearColor];
  self.contentView.backgroundColor = [UIColor clearColor];
  self.selectionStyle = UITableViewCellSelectionStyleNone;

  self.unviewedLineViewColor = self.tintColor;

  self.cardSidePadding = AppboyCardSidePadding;
  self.cardSpacing = AppboyCardSpacing;
}

- (void)setUpUI {
  // View Hierarchy
  [self.contentView addSubview:self.rootView];
  [self.rootView addSubview:self.pinImageView];
  [self.rootView addSubview:self.unviewedLineView];

  // AutoLayout
  // - Root
  self.rootViewLeadingConstraint = [self.rootView.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor
                                                                               constant:self.cardSidePadding];
  self.rootViewTrailingConstraint = [self.rootView.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor
                                                                                 constant:-self.cardSidePadding];
  self.rootViewTopConstraint = [self.rootView.topAnchor constraintEqualToAnchor:self.contentView.topAnchor
                                                                       constant:self.cardSidePadding];
  self.rootViewBottomConstraint = [self.rootView.bottomAnchor constraintEqualToAnchor:self.contentView.bottomAnchor
                                                                             constant:-self.cardSidePadding];
  self.cardWidthConstraint = [self.rootView.widthAnchor constraintLessThanOrEqualToConstant:380];
  self.rootViewLeadingConstraint.priority = ABKContentCardPriorityLayoutRequiredBelowAppleRequired;
  self.rootViewTrailingConstraint.priority = ABKContentCardPriorityLayoutRequiredBelowAppleRequired;

  // - All constraints
  NSArray *constraints = @[
    // Root view
    self.rootViewLeadingConstraint,
    self.rootViewTrailingConstraint,
    self.rootViewTopConstraint,
    self.rootViewBottomConstraint,
    self.cardWidthConstraint,
    [self.rootView.centerXAnchor constraintEqualToAnchor:self.contentView.centerXAnchor],
    // PinImage
    [self.pinImageView.trailingAnchor constraintEqualToAnchor:self.rootView.trailingAnchor],
    [self.pinImageView.topAnchor constraintEqualToAnchor:self.rootView.topAnchor],
    [self.pinImageView.widthAnchor constraintEqualToConstant:20],
    [self.pinImageView.heightAnchor constraintEqualToConstant:20],
    // UnviewedLine
    [self.unviewedLineView.leadingAnchor constraintEqualToAnchor:self.rootView.leadingAnchor],
    [self.unviewedLineView.trailingAnchor constraintEqualToAnchor:self.rootView.trailingAnchor],
    [self.unviewedLineView.bottomAnchor constraintEqualToAnchor:self.rootView.bottomAnchor],
    [self.unviewedLineView.heightAnchor constraintEqualToConstant:8]
  ];
  [NSLayoutConstraint activateConstraints:constraints];
}

# pragma mark - Cell UI Configuration

- (void)setUnviewedLineViewColor:(UIColor*)bgColor {
  _unviewedLineViewColor = bgColor;
  if (self.unviewedLineView) {
    self.unviewedLineView.backgroundColor = self.unviewedLineViewColor;
  }
}

- (void)setHideUnreadIndicator:(BOOL)hideUnreadIndicator {
  if (_hideUnreadIndicator != hideUnreadIndicator) {
    _hideUnreadIndicator = hideUnreadIndicator;
    self.unviewedLineView.hidden = hideUnreadIndicator;
  }
}

- (void)setCardSidePadding:(CGFloat)sidePadding {
  _cardSidePadding = sidePadding;
  if (self.rootViewLeadingConstraint && self.rootViewTrailingConstraint) {
    self.rootViewLeadingConstraint.constant = self.cardSidePadding;
    self.rootViewTrailingConstraint.constant = self.cardSidePadding;
  }
}

- (void)setCardSpacing:(CGFloat)spacing {
  _cardSpacing = spacing;
  if (self.rootViewTopConstraint && self.rootViewBottomConstraint) {
    self.rootViewTopConstraint.constant = self.cardSpacing / 2.0;
    self.rootViewBottomConstraint.constant = self.cardSpacing / 2.0;
  }
}

#pragma mark - ApplyCard

- (void)applyCard:(ABKContentCard *)card {
  if ([card isControlCard]) {
    self.pinImageView.hidden = YES;
    self.unviewedLineView.hidden = YES;
    return;
  }

  self.unviewedLineView.hidden = self.hideUnreadIndicator || card.viewed;
  self.pinImageView.hidden = !card.pinned;
}

#pragma mark - Utiliy Methods

- (UIImage *)getPlaceHolderImage {
  return [ABKUIUtils imageNamed:@"appboy_cc_noimage_lrg"
                         bundle:[ABKBaseContentCardCell class]
                        channel:ABKContentCardChannel];
}

- (Class)imageViewClass {
  if ([Appboy sharedInstance].imageDelegate) {
    return [[Appboy sharedInstance].imageDelegate imageViewClass];
  }
  return [UIImageView class];
}

- (void)applyAppboyAttributedTextStyleFrom:(NSString *)text forLabel:(UILabel *)label {
  UIColor *color = label.textColor;
  NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
  paragraphStyle.lineSpacing = AppboyCardLineSpacing;
  UIFont *font = label.font;
  NSDictionary *attributes = @{NSFontAttributeName: font,
                               NSForegroundColorAttributeName: color,
                               NSParagraphStyleAttributeName: paragraphStyle};
  // Convert to empty string to fail gracefully if given null from backend
  text = text ?: @"";
  label.attributedText = [[NSAttributedString alloc] initWithString:text attributes:attributes];
}

@end
