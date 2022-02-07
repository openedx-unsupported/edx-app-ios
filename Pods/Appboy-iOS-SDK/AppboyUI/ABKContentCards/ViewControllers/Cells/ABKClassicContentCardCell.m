#import "ABKClassicContentCardCell.h"

@implementation ABKClassicContentCardCell

- (void)applyCard:(ABKClassicContentCard *)card {
  if (![card isKindOfClass:[ABKClassicContentCard class]]) {
    return;
  }
  
  [super applyCard:card];
  
  [self applyAppboyAttributedTextStyleFrom:card.title forLabel:self.titleLabel];
  [self applyAppboyAttributedTextStyleFrom:card.cardDescription forLabel:self.descriptionLabel];
  [self applyAppboyAttributedTextStyleFrom:card.domain forLabel:self.linkLabel];
  
  BOOL shouldHideLink = (card.domain.length == 0);
  [self hideLinkLabel:shouldHideLink];
}

- (void)hideLinkLabel:(BOOL)hide {
  self.linkLabel.hidden = hide;
  if (hide) {
    if ((self.linkBottomConstraint.priority != UILayoutPriorityDefaultLow)
        || (self.descriptionBottomConstraint.priority != UILayoutPriorityDefaultHigh)) {
      self.linkBottomConstraint.priority = UILayoutPriorityDefaultLow;
      self.descriptionBottomConstraint.priority = UILayoutPriorityDefaultHigh;
      [self setNeedsLayout];
    }
  } else {
    if ((self.linkBottomConstraint.priority != UILayoutPriorityDefaultHigh)
        || (self.descriptionBottomConstraint.priority != UILayoutPriorityDefaultLow)) {
      self.linkBottomConstraint.priority = UILayoutPriorityDefaultHigh;
      self.descriptionBottomConstraint.priority = UILayoutPriorityDefaultLow;
      [self setNeedsLayout];
    }
  }
}

@end
