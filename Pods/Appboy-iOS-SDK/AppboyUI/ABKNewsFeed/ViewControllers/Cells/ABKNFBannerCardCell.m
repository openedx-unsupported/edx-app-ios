#import "ABKNFBannerCardCell.h"
#import "Appboy.h"
#import "ABKImageDelegate.h"

@implementation ABKNFBannerCardCell

- (void)applyCard:(ABKCard *)card {
  if (![card isKindOfClass:[ABKBannerCard class]]) {
    return;
  }
  
  [super applyCard:card];
  ABKBannerCard *bannerCard = (ABKBannerCard *)card;
  
  [self updateImageRatioConstraintToRatio:bannerCard.imageAspectRatio];
  [self setNeedsUpdateConstraints];
  [self setNeedsDisplay];

  if (![Appboy sharedInstance].imageDelegate) {
    NSLog(@"[APPBOY][WARN] %@ %s",
          @"ABKImageDelegate on Appboy is nil. Image loading may be disabled.",
          __PRETTY_FUNCTION__);
    return;
  }
  typeof(self) __weak weakSelf = self;
  [[Appboy sharedInstance].imageDelegate setImageForView:self.bannerImageView
                                   showActivityIndicator:NO
                                                 withURL:[NSURL URLWithString:bannerCard.image]
                                        imagePlaceHolder:nil
                                               completed:^(UIImage * _Nullable image,
                                                           NSError * _Nullable error,
                                                           NSInteger cacheType,
                                                           NSURL * _Nullable imageURL) {
    if (weakSelf == nil) {
      return;
    }
    if (image) {
      dispatch_async(dispatch_get_main_queue(), ^{
        CGFloat newRatio = image.size.width / image.size.height;
        if (fabs(newRatio - weakSelf.imageRatioConstraint.multiplier) > 0.1f) {
          [weakSelf updateImageRatioConstraintToRatio:newRatio];
          [weakSelf setNeedsUpdateConstraints];
          [weakSelf setNeedsDisplay];
        }
      });
    } else {
      dispatch_async(dispatch_get_main_queue(), ^{
        weakSelf.bannerImageView.image = [weakSelf getPlaceHolderImage];
      });
    }
  }];
}

- (void)updateImageRatioConstraintToRatio:(CGFloat)newRatio {
  if (self.imageRatioConstraint) {
    [self.bannerImageView removeConstraint:self.imageRatioConstraint];
  }
  self.imageRatioConstraint = [NSLayoutConstraint constraintWithItem:self.bannerImageView
                                                           attribute:NSLayoutAttributeWidth
                                                           relatedBy:NSLayoutRelationEqual
                                                              toItem:self.bannerImageView
                                                           attribute:NSLayoutAttributeHeight
                                                          multiplier:newRatio
                                                            constant:0];
  [self.bannerImageView addConstraint:self.imageRatioConstraint];
}

@end
