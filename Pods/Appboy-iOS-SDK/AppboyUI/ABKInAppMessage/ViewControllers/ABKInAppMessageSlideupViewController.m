#import "ABKInAppMessageSlideupViewController.h"
#import "ABKInAppMessageSlideup.h"
#import "ABKUIUtils.h"

static CGFloat const AssetSideMargin = 20.0f;
static CGFloat const DefaultViewRadius = 15.0f;
static CGFloat const DefaultVerticalMarginHeight = 10.0f;

@interface ABKInAppMessageSlideupViewController()

@property (strong, nonatomic) NSLayoutConstraint *slideConstraint;
@property (nonatomic, readonly) BOOL animatesFromTop;
@property (nonatomic, readonly) CGFloat safeAreaOffset;

@end

@implementation ABKInAppMessageSlideupViewController

- (void)loadView {
  NSBundle *bundle = [ABKUIUtils bundle:[ABKInAppMessageSlideupViewController class] channel:ABKInAppMessageChannel];
  [bundle loadNibNamed:@"ABKInAppMessageSlideupViewController"
                 owner:self
               options:nil];
  self.inAppMessageMessageLabel.font = MessageLabelDefaultFont;
  if (self.inAppMessage.message) {
    NSMutableAttributedString *attributedStringMessage = [[NSMutableAttributedString alloc] initWithString:self.inAppMessage.message];
    NSMutableParagraphStyle *messageStyle = [[NSMutableParagraphStyle alloc] init];
    [messageStyle setLineSpacing:2];
    [messageStyle setLineBreakMode:NSLineBreakByTruncatingTail];
    [attributedStringMessage addAttribute:NSParagraphStyleAttributeName
                                    value:messageStyle
                                    range:NSMakeRange(0, self.inAppMessage.message.length)];
    self.inAppMessageMessageLabel.attributedText = attributedStringMessage;
  }
}

- (void)viewWillAppear:(BOOL)animated {
  [super viewWillAppear:animated];
  self.view.translatesAutoresizingMaskIntoConstraints = NO;

  [self setupChevron];
  [self setupImageOrLabelView];

  self.view.layer.cornerRadius = DefaultViewRadius;
  self.view.layer.masksToBounds = NO;
}

- (void)viewWillLayoutSubviews {
  [super viewWillLayoutSubviews];

  // Setup the constraints once UIKit has set the layoutMargins / safeAreaInsets
  if (!self.slideConstraint) {
    [self setupConstraintsWithSuperView];
  }
}

- (void)viewDidLayoutSubviews {
  [super viewDidLayoutSubviews];

  // Redraw the shadow when the layout is changed.
  UIBezierPath *shadowPath = [UIBezierPath bezierPathWithRoundedRect:self.view.bounds cornerRadius:DefaultViewRadius];
  self.view.layer.shadowColor = [[UIColor blackColor] colorWithAlphaComponent:InAppMessageShadowOpacity].CGColor;
  self.view.layer.shadowOffset = CGSizeMake(0.0f, 0.0f);
  self.view.layer.shadowRadius = InAppMessageShadowBlurRadius;
  self.view.layer.shadowPath = shadowPath.CGPath;

  // Make opacity of shadow match opacity of the In-App Message background
  CGFloat alpha = 0;
  [self.view.backgroundColor getRed:nil green:nil blue:nil alpha:&alpha];
  self.view.layer.shadowOpacity = alpha;
}

#pragma mark - Public methods

- (CGFloat)offset {
  return self.slideConstraint.constant - self.safeAreaOffset;
}

- (void)setOffset:(CGFloat)offset {
  self.slideConstraint.constant = offset + self.safeAreaOffset;
}

#pragma mark - Private methods

- (void)setupChevron {
  if (((ABKInAppMessageSlideup *)self.inAppMessage).hideChevron) {
    [self.arrowImage removeFromSuperview];
    self.arrowImage = nil;
    NSLayoutConstraint *inAppMessageLabelTrailingConstraint =
        [self.inAppMessageMessageLabel.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor
                                                                     constant:-AssetSideMargin];
    [self.view addConstraint:inAppMessageLabelTrailingConstraint];

  } else {
    if (((ABKInAppMessageSlideup *)self.inAppMessage).chevronColor != nil) {
      UIColor *arrowColor = ((ABKInAppMessageSlideup *)self.inAppMessage).chevronColor;
      self.arrowImage.image = [self.arrowImage.image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
      self.arrowImage.tintColor = arrowColor;
    } else {
      UIColor *defaultArrowColor = [UIColor colorWithRed:(155.0/255.0) green:(155.0/255.0) blue:(155.0/255.0) alpha:1.0];
      self.arrowImage.image = [self.arrowImage.image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
      self.arrowImage.tintColor = defaultArrowColor;
    }
  }
}

- (void)setupImageOrLabelView {
  if (![super applyImageToImageView:self.iconImageView]) {
    [self.iconImageView removeFromSuperview];
    self.iconImageView = nil;

    if (![super applyIconToLabelView:self.iconLabelView]) {
      [self.iconLabelView removeFromSuperview];
      self.iconLabelView = nil;
      NSLayoutConstraint *inAppMessageLabelLeadingConstraint =
          [self.inAppMessageMessageLabel.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor
                                                                       constant:AssetSideMargin];
      [self.view addConstraint:inAppMessageLabelLeadingConstraint];
    }
  }
}

- (void)setupConstraintsWithSuperView {
  NSLayoutConstraint *leadConstraint = [self.view.leadingAnchor constraintEqualToAnchor:self.view.superview.layoutMarginsGuide.leadingAnchor];
  NSLayoutConstraint *trailConstraint = [self.view.trailingAnchor constraintEqualToAnchor:self.view.superview.layoutMarginsGuide.trailingAnchor];
  NSLayoutConstraint *offscreenConstraint;

  if (self.animatesFromTop) {
    offscreenConstraint = [self.view.bottomAnchor constraintEqualToAnchor:self.view.superview.topAnchor];
    self.slideConstraint = [self.view.topAnchor constraintEqualToAnchor:self.view.superview.layoutMarginsGuide.topAnchor
                                                               constant:self.safeAreaOffset];
  } else {
    offscreenConstraint = [self.view.topAnchor constraintEqualToAnchor:self.view.superview.bottomAnchor];
    self.slideConstraint = [self.view.bottomAnchor constraintEqualToAnchor:self.view.superview.layoutMarginsGuide.bottomAnchor
                                                                  constant:self.safeAreaOffset];
  }

  offscreenConstraint.priority = UILayoutPriorityDefaultLow;
  [NSLayoutConstraint activateConstraints:@[leadConstraint, trailConstraint, offscreenConstraint]];
}

- (BOOL)animatesFromTop {
  return ((ABKInAppMessageSlideup *)self.inAppMessage).inAppMessageSlideupAnchor == ABKInAppMessageSlideupFromTop;
}

- (CGFloat)safeAreaOffset {
  BOOL hasSafeArea = self.animatesFromTop
    ? self.view.superview.layoutMargins.top != 0
    : self.view.superview.layoutMargins.bottom != 0;

  if (hasSafeArea) {
    return 0;
  }

  return self.animatesFromTop
    ? DefaultVerticalMarginHeight
    : -DefaultVerticalMarginHeight;
}

#pragma mark - Superclass methods

- (void)beforeMoveInAppMessageViewOnScreen {
  self.slideConstraint.active = YES;
}

- (void)moveInAppMessageViewOnScreen {
  [self.view.superview layoutIfNeeded];
}

- (void)beforeMoveInAppMessageViewOffScreen {
  self.slideConstraint.active = NO;
}

- (void)moveInAppMessageViewOffScreen {
  [self.view.superview layoutIfNeeded];
}

- (void)setInAppMessage:(ABKInAppMessage *)inAppMessage {
  if ([inAppMessage isKindOfClass:[ABKInAppMessageSlideup class]]) {
    super.inAppMessage = inAppMessage;
  } else {
    NSLog(@"ABKInAppMessageSlideupViewController only accepts in-app message with type ABKInAppMessageSlideup. Setting in-app message fails.");
  }
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
  if (self.inAppMessage.inAppMessageClickActionType != ABKInAppMessageNoneClickAction) {
    self.view.alpha = InAppMessageSelectedOpacity;
  }
}

@end
