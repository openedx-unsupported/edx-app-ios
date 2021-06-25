#import "ABKNFBaseCardCell.h"
#import "ABKBannerCard.h"
#import "ABKTextAnnouncementCard.h"
#import "ABKCaptionedImageCard.h"
#import "ABKClassicCard.h"
#import "ABKUIUtils.h"

static CGFloat AppboyCardSidePadding = 10.0;
static CGFloat AppboyCardSpacing = 20.0;
static CGFloat AppboyCardBorderWidth = 0.5;
static CGFloat AppboyCardCornerRadius = 3.0;

@implementation ABKNFBaseCardCell

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
  
  self.rootView.layer.cornerRadius = AppboyCardCornerRadius;
  self.rootView.layer.masksToBounds = YES;
  self.rootView.layer.borderColor = [UIColor colorWithWhite:0.75f alpha:1.0].CGColor;
  self.rootView.layer.borderWidth = AppboyCardBorderWidth;
  
  self.rootViewTopConstraint.constant = AppboyCardSpacing / 2.0;
  self.rootViewBottomConstraint.constant = AppboyCardSpacing / 2.0;
  self.rootViewLeadingConstraint.constant = AppboyCardSidePadding;
  self.rootViewTrailingConstraint.constant = AppboyCardSidePadding;

  self.unreadIndicatorView.image = [self.unreadIndicatorView.image imageFlippedForRightToLeftLayoutDirection];
}

# pragma mark - Cell UI Configuration

- (void)setHideUnreadIndicator:(BOOL)hideUnreadIndicator {
  if(self.hideUnreadIndicator != hideUnreadIndicator) {
    _hideUnreadIndicator = hideUnreadIndicator;
    self.unreadIndicatorView.hidden = hideUnreadIndicator;
  }
}

- (void)applyCard:(ABKCard *)card {
  if(!self.hideUnreadIndicator) {
    self.unreadIndicatorView.highlighted = !card.viewed;
  }
}

#pragma mark - Utiliy Methods

+ (ABKNFBaseCardCell *)dequeueCellFromTableView:(UITableView *)tableView
                                   forIndexPath:(NSIndexPath *)indexPath
                                        forCard:(ABKCard *)card {
  NSString *CellIdentifier = [self findCellIdentifierWithCard:card];
  return [tableView dequeueReusableCellWithIdentifier:CellIdentifier
                                         forIndexPath:indexPath];
}

+ (NSString *)findCellIdentifierWithCard:(ABKCard *)card {
  if ([card isKindOfClass:[ABKBannerCard class]]) {
    return @"ABKBannerCardCell";
  } else if ([card isKindOfClass:[ABKCaptionedImageCard class]]) {
    return @"ABKNFCaptionedMessageCardCell";
  } else if ([card isKindOfClass:[ABKClassicCard class]]) {
    return @"ABKNFNewsCardCell";
  } else if ([card isKindOfClass:[ABKTextAnnouncementCard class]]) {
    return @"ABKNFCaptionedMessageCardCell";
  }
  return nil;
}

- (UIImage *)getPlaceHolderImage {
  return [ABKUIUtils getImageWithName:@"img-noimage-lrg"
                                 type:@"png"
                       inAppboyBundle:[ABKUIUtils bundle:[ABKNFBaseCardCell class] channel:ABKNewsFeedChannel]];
}

@end
