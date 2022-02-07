#import "ABKBannerContentCardCell.h"
#import "ABKBannerCard.h"
#import "Appboy.h"
#import "ABKImageDelegate.h"
#import "ABKUIUtils.h"

@implementation ABKBannerContentCardCell

#pragma mark - Properties

- (UIImageView *)bannerImageView {
  if (_bannerImageView != nil) {
    return _bannerImageView;
  }

  UIImageView *bannerImageView = [[[self imageViewClass] alloc] init];
  bannerImageView.contentMode = UIViewContentModeScaleAspectFit;
  bannerImageView.translatesAutoresizingMaskIntoConstraints = NO;
  _bannerImageView = bannerImageView;
  return bannerImageView;
}

#pragma mark - SetUp

- (void)setUpUI {
  [super setUpUI];

  // Views
  [self.rootView addSubview:self.bannerImageView];
  [self.rootView bringSubviewToFront:self.pinImageView];
  [self.rootView bringSubviewToFront:self.unviewedLineView];

  // AutoLayout
  self.imageRatioConstraint = [self.bannerImageView.heightAnchor constraintEqualToAnchor:self.bannerImageView.widthAnchor];
  self.imageRatioConstraint.priority = UILayoutPriorityDefaultHigh;

  NSArray *constraints = @[
    [self.bannerImageView.topAnchor constraintEqualToAnchor:self.rootView.topAnchor],
    [self.bannerImageView.bottomAnchor constraintEqualToAnchor:self.rootView.bottomAnchor],
    [self.bannerImageView.leadingAnchor constraintEqualToAnchor:self.rootView.leadingAnchor],
    [self.bannerImageView.trailingAnchor constraintEqualToAnchor:self.rootView.trailingAnchor],
    self.imageRatioConstraint
  ];
  [NSLayoutConstraint activateConstraints:constraints];
}

#pragma mark - ApplyCard

- (void)applyCard:(ABKBannerContentCard *)card {
  if (![card isKindOfClass:[ABKBannerContentCard class]]) {
    return;
  }
  
  [super applyCard:card];
  [self updateImageConstraintIfNeededWithAspectRatio:card.imageAspectRatio];
  
  if (![Appboy sharedInstance].imageDelegate) {
    NSLog(@"[APPBOY][WARN] %@ %s",
          @"ABKImageDelegate on Appboy is nil. Image loading may be disabled.",
          __PRETTY_FUNCTION__);
    return;
  }
  typeof(self) __weak weakSelf = self;
  [[Appboy sharedInstance].imageDelegate setImageForView:self.bannerImageView
                                   showActivityIndicator:NO
                                                 withURL:[NSURL URLWithString:card.image]
                                        imagePlaceHolder:[self getPlaceHolderImage]
                                               completed:^(UIImage * _Nullable image,
                                                           NSError * _Nullable error,
                                                           NSInteger cacheType,
                                                           NSURL * _Nullable imageURL) {
    dispatch_async(dispatch_get_main_queue(), ^{
      typeof(self) __strong strongSelf = weakSelf;
      if (strongSelf == nil) {
        return;
      }

      UIImage *finalImage = image != nil ? image : [strongSelf getPlaceHolderImage];
      strongSelf.bannerImageView.image = finalImage;

      CGFloat aspectRatio = finalImage.size.width / finalImage.size.height;
      card.imageAspectRatio = aspectRatio;
      [strongSelf updateImageConstraintIfNeededWithAspectRatio:aspectRatio];
    });
  }];
}

- (void)updateImageConstraintIfNeededWithAspectRatio:(CGFloat)aspectRatio {
  if (aspectRatio == 0 || ABK_CGFLT_EQ(self.imageRatioConstraint.multiplier, 1 / aspectRatio)) {
    return;
  }

  self.imageRatioConstraint.active = NO;
  self.imageRatioConstraint = [self.bannerImageView.heightAnchor constraintEqualToAnchor:self.bannerImageView.widthAnchor
                                                                                multiplier:1 / aspectRatio];
  self.imageRatioConstraint.priority = UILayoutPriorityDefaultHigh;
  self.imageRatioConstraint.active = YES;
  [self.delegate cellRequestSizeUpdate:self];
}

@end
