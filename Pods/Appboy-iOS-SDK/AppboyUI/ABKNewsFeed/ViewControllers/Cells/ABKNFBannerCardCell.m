#import "ABKNFBannerCardCell.h"
#import "Appboy.h"
#import "ABKImageDelegate.h"

@implementation ABKNFBannerCardCell

#pragma mark - SetUp

- (void)setUpUI {
  [super setUpUI];
  [self setUpBannerImageView];
}

- (void)setUpBannerImageView {
  self.bannerImageView =  [[[self imageViewClass] alloc] init];
  self.bannerImageView.contentMode = UIViewContentModeScaleAspectFit;
  self.bannerImageView.translatesAutoresizingMaskIntoConstraints = NO;
  [self.bannerImageView setContentHuggingPriority:UILayoutPriorityDefaultHigh forAxis:UILayoutConstraintAxisVertical];
  [self.bannerImageView setContentHuggingPriority:UILayoutPriorityDefaultHigh forAxis:UILayoutConstraintAxisHorizontal];
  [self.bannerImageView setContentCompressionResistancePriority:UILayoutPriorityDefaultHigh forAxis:UILayoutConstraintAxisVertical];
  [self.rootView addSubview:self.bannerImageView];
  [self.bannerImageView.leadingAnchor constraintEqualToAnchor:self.rootView.leadingAnchor].active = YES;
  [self.bannerImageView.trailingAnchor constraintEqualToAnchor:self.rootView.trailingAnchor].active = YES;
  [self.bannerImageView.topAnchor constraintEqualToAnchor:self.rootView.topAnchor].active = YES;
  [self.bannerImageView.bottomAnchor constraintEqualToAnchor:self.rootView.bottomAnchor].active = YES;

  NSLayoutConstraint *estimatedWidth = [self.bannerImageView.widthAnchor constraintEqualToAnchor:self.rootView.widthAnchor];
  estimatedWidth.priority = UILayoutPriorityDefaultHigh;
  estimatedWidth.active = YES;
  self.imageRatioConstraint = [self.bannerImageView.widthAnchor constraintEqualToAnchor:self.bannerImageView.heightAnchor multiplier:355.0/79.0];
  self.imageRatioConstraint.priority = UILayoutPriorityRequired-1;
  self.imageRatioConstraint.active = YES;
  NSLayoutConstraint *estimatedHeight = [self.rootView.heightAnchor constraintGreaterThanOrEqualToConstant:100];
  estimatedHeight.priority = UILayoutPriorityDefaultLow;
  estimatedHeight.active = YES;
}

#pragma mark - ApplyCard

- (void)applyCard:(ABKCard *)card {
  if (![card isKindOfClass:[ABKBannerCard class]]) {
    return;
  }
  
  [super applyCard:card];
  ABKBannerCard *bannerCard = (ABKBannerCard *)card;
  
  [self updateImageRatioConstraintToRatio:bannerCard.imageAspectRatio];
  [self setNeedsUpdateConstraints];
  [self setNeedsLayout];

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
          [weakSelf setNeedsLayout];
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
    self.imageRatioConstraint.active = NO;
  }
  self.imageRatioConstraint = [self.bannerImageView.widthAnchor constraintEqualToAnchor:self.bannerImageView.heightAnchor multiplier:newRatio];
  self.imageRatioConstraint.priority = UILayoutPriorityRequired-1;
  NSLayoutConstraint *estimatedHeight = [self.rootView.heightAnchor constraintGreaterThanOrEqualToConstant:ceil(self.rootView.frame.size.width/self.imageRatioConstraint.multiplier)];
  estimatedHeight.priority = UILayoutPriorityDefaultLow;
  estimatedHeight.active = YES;
  self.imageRatioConstraint.active = YES;
}

@end
