#import "ABKNFBaseCardCell.h"
#import "ABKBannerCard.h"
#import "ABKTextAnnouncementCard.h"
#import "ABKCaptionedImageCard.h"
#import "ABKClassicCard.h"
#import "ABKUIUtils.h"
#import "ABKImageDelegate.h"

CGFloat ABKNFLabelHorizontalSpace = 22.0;
CGFloat ABKNFLabelVerticalSpace = 13.0;
CGFloat ABKNFTopSpace = 7.0;

static CGFloat AppboyCardSidePadding = 10.0;
static CGFloat AppboyCardSpacing = 20.0;
static CGFloat AppboyCardBorderWidth = 0.5;
static CGFloat AppboyCardCornerRadius = 3.0;

@implementation ABKNFBaseCardCell

+ (UIColor *)ABKNFDescriptionLabelColor {
  return [ABKUIUtils dynamicColorForLightColor:[UIColor colorWithRed:0.1747547901  green:0.1760663777 blue:0.1758382755 alpha:1] darkColor:[UIColor lightTextColor]];
}

+ (UIColor *)ABKNFTitleLabelColor {
  return [ABKUIUtils dynamicColorForLightColor:[UIColor colorWithRed:0.25098039220000001 green:0.27657390510000002 blue:0.32259352190000001 alpha:1] darkColor:[UIColor lightTextColor]];
}

+ (UIColor *)ABKNFTitleLabelColorOnGray {
  return [ABKUIUtils dynamicColorForLightColor:[UIColor colorWithRed:0.25327896900000002 green:0.28065123180000001 blue:0.32005588499999998 alpha:1] darkColor:[UIColor lightTextColor]];
}

#pragma mark - Initialization

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
  self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
  if (self) {
    [self setUp];
    [self setUpUI];
  }
  return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
  if (self = [super initWithCoder:aDecoder]) {
    [self setUp];
  }
  return self;
}

#pragma mark - SetUp

- (void)setUp {
  _cardSidePadding = AppboyCardSidePadding;
  _cardSpacing = AppboyCardSpacing;
}

- (void)setUpUI {
  [self setUpRootView];
  [self setUpRootViewBorder];
  [self setUpUnreadIndicatorView];
}

- (void)setUpRootView {
  self.backgroundColor = [UIColor clearColor];
  self.contentView.backgroundColor = [UIColor clearColor];
  self.contentView.autoresizingMask = UIViewAutoresizingFlexibleHeight;
  self.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
  self.selectionStyle = UITableViewCellSelectionStyleNone;

  self.rootView = [[UIView alloc] init];
  self.rootView.translatesAutoresizingMaskIntoConstraints = NO;
  [[self contentView] addSubview:self.rootView];
  if (@available(iOS 13.0, *)) {
    self.rootView.backgroundColor = [UIColor systemBackgroundColor];
  } else {
    self.rootView.backgroundColor = [UIColor whiteColor];
  }

  self.rootViewTopConstraint = [self.rootView.topAnchor constraintEqualToAnchor:self.contentView.topAnchor constant:AppboyCardSpacing / 2.0];
  self.rootViewBottomConstraint = [self.contentView.bottomAnchor constraintEqualToAnchor:self.rootView.bottomAnchor constant:AppboyCardSpacing / 2.0];
  self.rootViewLeadingConstraint = [self.rootView.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor constant:AppboyCardSidePadding];
  self.rootViewTrailingConstraint = [self.contentView.trailingAnchor constraintEqualToAnchor:self.rootView.trailingAnchor constant:AppboyCardSidePadding];
  [NSLayoutConstraint activateConstraints:@[self.rootViewTopConstraint,
                          self.rootViewBottomConstraint,
                          self.rootViewLeadingConstraint,
                          self.rootViewTrailingConstraint]];
}

- (void)setUpRootViewBorder {
  self.rootView.layer.cornerRadius = AppboyCardCornerRadius;
  self.rootView.layer.masksToBounds = YES;
  self.rootView.layer.borderColor = [UIColor colorWithWhite:0.75f alpha:1.0].CGColor;
  self.rootView.layer.borderWidth = AppboyCardBorderWidth;
  
  self.rootViewTopConstraint.constant = AppboyCardSpacing / 2.0;
  self.rootViewBottomConstraint.constant = AppboyCardSpacing / 2.0;
  self.rootViewLeadingConstraint.constant = AppboyCardSidePadding;
  self.rootViewTrailingConstraint.constant = AppboyCardSidePadding;
}

- (void)setUpUnreadIndicatorView {
  self.unreadIndicatorView = [[UIImageView alloc] initWithImage:[ABKUIUtils imageNamed:@"Icons_Read"
                                                                                bundle:[ABKNFBaseCardCell class]
                                                                               channel:ABKNewsFeedChannel]];
  self.unreadIndicatorView.translatesAutoresizingMaskIntoConstraints = NO;
  self.unreadIndicatorView.highlightedImage = [ABKUIUtils imageNamed:@"Icons_Unread"
                                                              bundle:[ABKNFBaseCardCell class]
                                                             channel:ABKNewsFeedChannel];
  [self.rootView addSubview:self.unreadIndicatorView];

  [self.unreadIndicatorView.heightAnchor constraintEqualToConstant:20].active = YES;
  [self.unreadIndicatorView.widthAnchor constraintEqualToConstant:20].active = YES;
  [self.unreadIndicatorView.topAnchor constraintEqualToAnchor:self.rootView.topAnchor].active = YES;
  [self.rootView.trailingAnchor constraintEqualToAnchor:self.unreadIndicatorView.trailingAnchor].active = YES;
  self.unreadIndicatorView.image = [self.unreadIndicatorView.image imageFlippedForRightToLeftLayoutDirection];
}

# pragma mark - Cell UI Configuration

- (void)setHideUnreadIndicator:(BOOL)hideUnreadIndicator {
  if(self.hideUnreadIndicator != hideUnreadIndicator) {
    _hideUnreadIndicator = hideUnreadIndicator;
    self.unreadIndicatorView.hidden = hideUnreadIndicator;
  }
}

#pragma mark - ApplyCard

- (void)applyCard:(ABKCard *)card {
  if(!self.hideUnreadIndicator) {
    self.unreadIndicatorView.highlighted = !card.viewed;
  }
}

#pragma mark - Utiliy Methods

- (UIImage *)getPlaceHolderImage {
  return [ABKUIUtils imageNamed:@"img-noimage-lrg"
                         bundle:[ABKNFBaseCardCell class]
                        channel:ABKNewsFeedChannel];
}

- (Class)imageViewClass {
   if ([Appboy sharedInstance].imageDelegate) {
     return [[Appboy sharedInstance].imageDelegate imageViewClass];
   }
   return [UIImageView class];
 }

- (void)awakeFromNib {
  [super awakeFromNib];
  [self setUpRootViewBorder];
  self.unreadIndicatorView.image = [self.unreadIndicatorView.image imageFlippedForRightToLeftLayoutDirection];
}

@end
