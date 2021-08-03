#import "ABKNFClassicCardCell.h"
#import "Appboy.h"
#import "ABKImageDelegate.h"
#import "ABKUIUtils.h"

@implementation ABKNFClassicCardCell

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

@end
