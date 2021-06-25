#import "ABKBaseContentCardCell.h"

#import "ABKUIUtils.h"

static CGFloat AppboyCardSidePadding = 10.0;
static CGFloat AppboyCardSpacing = 32.0;
static CGFloat AppboyCardBorderWidth = 0.5;
static CGFloat AppboyCardCornerRadius = 3.0;
static CGFloat AppboyCardShadowXOffset = 0.0;
static CGFloat AppboyCardShadowYOffset = -2.0;
static CGFloat AppboyCardShadowOpacity = 0.5;
static CGFloat AppboyCardLineSpacing = 1.2;

@implementation ABKBaseContentCardCell

#pragma mark - Initialization

- (instancetype)init {
  if (self = [super init]) {
    [self setUp];
  }
  return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
  if (self = [super initWithCoder:aDecoder]) {
    [self setUp];
  }
  return self;
}

- (instancetype)initWithFrame:(CGRect)frame {
  if (self = [super initWithFrame:frame]) {
    [self setUp];
  }
  return self;
}

- (void)setUp {
  _cardSidePadding = AppboyCardSidePadding;
  _cardSpacing = AppboyCardSpacing;
}

- (void)awakeFromNib {
  [super awakeFromNib];
  
  self.contentView.autoresizingMask = UIViewAutoresizingFlexibleHeight;
  
  CALayer *rootLayer = self.rootView.layer;
  rootLayer.masksToBounds = YES;
  rootLayer.cornerRadius = AppboyCardCornerRadius;
  
  UIColor *lightBorderColor = [UIColor colorWithRed:(224.0 / 255.0) green:(224.0 / 255.0) blue:(224.0 / 255.0) alpha:1.0];
  UIColor *darkBorderColor = [UIColor colorWithRed:(85.0 / 255.0) green:(85.0 / 255.0) blue:(85.0 / 255.0) alpha:1.0];
  rootLayer.borderColor = [ABKUIUtils dynamicColorForLightColor:lightBorderColor darkColor:darkBorderColor].CGColor;
 
  rootLayer.borderWidth = AppboyCardBorderWidth;
  rootLayer.shadowColor = [UIColor colorWithRed:(178.0 / 255.0) green:(178.0 / 255.0) blue:(178.0 / 255.0) alpha:1.0].CGColor;
  rootLayer.shadowOffset =  CGSizeMake(AppboyCardShadowXOffset, AppboyCardShadowYOffset);
  rootLayer.shadowOpacity = AppboyCardShadowOpacity;
  
  self.rootView.backgroundColor = [ABKUIUtils dynamicColorForLightColor:[UIColor whiteColor] darkColor:[UIColor colorWithRed:0.172549 green:0.172549 blue:0.180392 alpha:1.0]];
  self.rootViewTopConstraint.constant = self.cardSpacing / 2.0;
  self.rootViewBottomConstraint.constant = self.cardSpacing / 2.0;
  self.rootViewLeadingConstraint.constant = self.cardSidePadding;
  self.rootViewTrailingConstraint.constant = self.cardSidePadding;

  self.pinImageView.image = [self.pinImageView.image imageFlippedForRightToLeftLayoutDirection];
}

# pragma mark - Cell UI Configuration

- (void)setHideUnreadIndicator:(BOOL)hideUnreadIndicator {
  if (_hideUnreadIndicator != hideUnreadIndicator) {
    _hideUnreadIndicator = hideUnreadIndicator;
    self.unviewedLineView.hidden = hideUnreadIndicator;
  }
}

- (void)applyCard:(ABKContentCard *)card {
  if ([card isControlCard]) {
    self.pinImageView.hidden = YES;
    self.unviewedLineView.hidden = YES;
  } else {
    if (self.hideUnreadIndicator) {
      self.unviewedLineView.hidden = YES;
    } else {
      self.unviewedLineView.hidden = card.viewed;
    }
    self.pinImageView.hidden = !card.pinned;
  }
}

#pragma mark - Utiliy Methods

- (UIImage *)getPlaceHolderImage {
  return [ABKUIUtils getImageWithName:@"appboy_cc_noimage_lrg"
                                 type:@"png"
                       inAppboyBundle:[ABKUIUtils bundle:[ABKBaseContentCardCell class] channel:ABKContentCardChannel]];
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
