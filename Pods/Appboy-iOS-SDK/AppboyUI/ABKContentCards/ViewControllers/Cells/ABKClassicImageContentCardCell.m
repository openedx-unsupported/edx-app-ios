#import "ABKClassicImageContentCardCell.h"
#import "Appboy.h"
#import "ABKImageDelegate.h"

@implementation ABKClassicImageContentCardCell

- (void)awakeFromNib {
  [super awakeFromNib];
  
  CALayer *imageLayer = self.classicImageView.layer;
  imageLayer.cornerRadius = 3.0;
  imageLayer.masksToBounds = YES;
}

- (void)applyCard:(ABKClassicContentCard *)card {
  if (![card isKindOfClass:[ABKClassicContentCard class]]) {
    return;
  }
  [super applyCard:card];
  if (![Appboy sharedInstance].imageDelegate) {
    NSLog(@"[APPBOY][WARN] %@ %s",
          @"ImageDelegate on Appboy is nil. Image loading may be disabled.",
          __PRETTY_FUNCTION__);
    return;
  }
  [[Appboy sharedInstance].imageDelegate setImageForView:self.classicImageView
                                   showActivityIndicator:NO
                                                 withURL:[NSURL URLWithString:card.image]
                                        imagePlaceHolder:[self getPlaceHolderImage]
                                               completed:nil];
}

@end
