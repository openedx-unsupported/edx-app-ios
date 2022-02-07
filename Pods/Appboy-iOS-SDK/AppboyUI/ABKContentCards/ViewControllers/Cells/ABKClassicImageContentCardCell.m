#import "ABKClassicImageContentCardCell.h"
#import "Appboy.h"
#import "ABKImageDelegate.h"
#import "ABKUIUtils.h"

@implementation ABKClassicImageContentCardCell

#pragma mark - Properties

- (UIImageView *)classicImageView {
  if (_classicImageView != nil) {
    return _classicImageView;
  }

  UIImageView *classicImageView = [[[self imageViewClass] alloc] init];
  classicImageView.contentMode = UIViewContentModeScaleAspectFit;
  classicImageView.translatesAutoresizingMaskIntoConstraints = NO;
  classicImageView.clipsToBounds = YES;
  _classicImageView = classicImageView;
  return classicImageView;
}

#pragma mark - SetUp

- (void)setUpUI {
  [super setUpUI];

  // Reset
  [self.titleLabel removeFromSuperview];
  [self.descriptionLabel removeFromSuperview];
  [self.linkLabel removeFromSuperview];

  // Views
  [self.rootView addSubview:self.classicImageView];
  [self.rootView addSubview:self.titleLabel];
  [self.rootView addSubview:self.descriptionLabel];
  [self.rootView addSubview:self.linkLabel];

  NSLayoutConstraint *titleTrailingConstraint = [self.titleLabel.trailingAnchor constraintEqualToAnchor:self.rootView.trailingAnchor
                                                                                               constant:-self.padding];
  titleTrailingConstraint.priority = ABKContentCardPriorityLayoutRequiredBelowAppleRequired;

  // AutoLayout
  NSArray *constraints = @[
    // ClassicImage
    [self.classicImageView.topAnchor constraintEqualToAnchor:self.rootView.topAnchor
                                                    constant:17],
    [self.classicImageView.leadingAnchor constraintEqualToAnchor:self.rootView.leadingAnchor
                                                        constant:self.padding],
    [self.classicImageView.heightAnchor constraintEqualToConstant:57.5],
    [self.classicImageView.widthAnchor constraintEqualToConstant:57.5],
    // Title
    [self.titleLabel.topAnchor constraintEqualToAnchor:self.rootView.topAnchor
                                              constant:17],
    [self.titleLabel.leadingAnchor constraintEqualToAnchor:self.classicImageView.trailingAnchor constant:12],
    titleTrailingConstraint,
    // Description
    // - Top
    [self.descriptionLabel.topAnchor constraintEqualToAnchor:self.titleLabel.bottomAnchor
                                                    constant:6],
    // - Horizontal
    [self.descriptionLabel.leadingAnchor constraintEqualToAnchor:self.titleLabel.leadingAnchor],
    [self.descriptionLabel.trailingAnchor constraintEqualToAnchor:self.titleLabel.trailingAnchor],
    // Link
    // - Horizontal
    [self.linkLabel.leadingAnchor constraintEqualToAnchor:self.titleLabel.leadingAnchor],
    [self.linkLabel.trailingAnchor constraintEqualToAnchor:self.titleLabel.trailingAnchor]
  ];
  [NSLayoutConstraint activateConstraints:constraints];

  self.descriptionConstraints = @[
    [self.descriptionLabel.bottomAnchor constraintEqualToAnchor:self.rootView.bottomAnchor
                                                       constant:-self.padding]
  ];

  self.linkConstraints = @[
    [self.linkLabel.topAnchor constraintEqualToAnchor:self.descriptionLabel.bottomAnchor
                                             constant:8],
    [self.linkLabel.bottomAnchor constraintEqualToAnchor:self.rootView.bottomAnchor
                                                constant:-self.padding]
  ];
}

#pragma mark - ApplyCard

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
