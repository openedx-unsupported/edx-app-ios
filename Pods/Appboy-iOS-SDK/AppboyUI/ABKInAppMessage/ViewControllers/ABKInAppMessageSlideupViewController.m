#import "ABKInAppMessageSlideupViewController.h"
#import "ABKInAppMessageSlideup.h"
#import "ABKUIUtils.h"
#import <QuartzCore/QuartzCore.h>

static CGFloat const SlideupAssetRightMargin = 20.0f;
static CGFloat const SlideupAssetLeftMargin = 20.0f;

static CGFloat const DefaultViewRadius = 15.0f;
static CGFloat const DefaultVerticalMarginHeight = 10.0f;
static CGFloat const DefaultSideMarginWidth = 15.0f;
static CGFloat const NotchedPhoneLandscapeBottomMarginHeight = 21.0f;
static CGFloat const NotchedPhoneLandscapeSideMarginWidth = 44.0f;
static CGFloat const NotchedPhonePortraitTopMarginHeight = 44.0f;
static CGFloat const NotchedPhonePortraitBottomMarginHeight = 34.0f;

static NSString *const InAppMessageSlideupLabelKey = @"inAppMessageMessageLabel";

@interface ABKInAppMessageSlideupViewController()

@property (strong, nonatomic) NSLayoutConstraint *leadConstraint;
@property (strong, nonatomic) NSLayoutConstraint *trailConstraint;

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
  [self setupConstraintsWithSuperView];

  self.view.layer.cornerRadius = DefaultViewRadius;
  self.view.layer.masksToBounds = NO;
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

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
  [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];

  CGFloat sidePadding = [self sideMarginsForPhoneAndOrientation];
  self.leadConstraint.constant = sidePadding;
  self.trailConstraint.constant = sidePadding;
}

#pragma mark - Private methods

- (void)setupChevron {
  if (((ABKInAppMessageSlideup *)self.inAppMessage).hideChevron) {
    [self.arrowImage removeFromSuperview];
    self.arrowImage = nil;
    NSDictionary *inAppMessageLabelDictionary = @{ InAppMessageSlideupLabelKey : self.inAppMessageMessageLabel };
    NSArray *inAppMessageLabelTrailingConstraint = [NSLayoutConstraint constraintsWithVisualFormat:@"H:[inAppMessageMessageLabel]-RightMargin-|"
                                                                                           options:0
                                                                                           metrics:@{@"RightMargin" : @(SlideupAssetRightMargin)}
                                                                                             views:inAppMessageLabelDictionary];
    [self.view addConstraints:inAppMessageLabelTrailingConstraint];
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
      NSDictionary *inAppMessageLabelDictionary = @{ InAppMessageSlideupLabelKey : self.inAppMessageMessageLabel };
      NSArray *inAppMessageLabelLeadingConstraint = [NSLayoutConstraint constraintsWithVisualFormat:@"H:|-LeftMargin-[inAppMessageMessageLabel]"
                                                                                            options:0
                                                                                            metrics:@{@"LeftMargin" : @(SlideupAssetLeftMargin)}
                                                                                              views:inAppMessageLabelDictionary];
      [self.view addConstraints:inAppMessageLabelLeadingConstraint];
    }
  }
}

- (void)setupConstraintsWithSuperView {
  CGFloat sidePadding = [self sideMarginsForPhoneAndOrientation];
  self.leadConstraint = [NSLayoutConstraint constraintWithItem:self.view
                                                     attribute:NSLayoutAttributeLeading
                                                     relatedBy:NSLayoutRelationEqual
                                                        toItem:self.view.superview
                                                     attribute:NSLayoutAttributeLeading
                                                    multiplier:1
                                                      constant:sidePadding];
  self.trailConstraint = [NSLayoutConstraint constraintWithItem:self.view.superview
                                                      attribute:NSLayoutAttributeTrailing
                                                      relatedBy:NSLayoutRelationEqual
                                                         toItem:self.view
                                                      attribute:NSLayoutAttributeTrailing
                                                     multiplier:1
                                                       constant:sidePadding];

  NSLayoutConstraint *slideConstraint = nil;
  if (((ABKInAppMessageSlideup *)self.inAppMessage).inAppMessageSlideupAnchor == ABKInAppMessageSlideupFromTop) {
    slideConstraint = [NSLayoutConstraint constraintWithItem:self.view
                                                   attribute:NSLayoutAttributeTop
                                                   relatedBy:NSLayoutRelationEqual
                                                      toItem:self.view.superview
                                                   attribute:NSLayoutAttributeTop
                                                  multiplier:1
                                                    constant:- self.view.frame.size.height];
  } else {
    slideConstraint =  [NSLayoutConstraint constraintWithItem:self.view.superview
                                                    attribute:NSLayoutAttributeBottom
                                                    relatedBy:NSLayoutRelationEqual
                                                       toItem:self.view
                                                    attribute:NSLayoutAttributeBottom
                                                   multiplier:1
                                                     constant:- self.view.frame.size.height];
  }
  self.slideConstraint = slideConstraint;
  [self.view.superview addConstraints:@[self.leadConstraint, self.trailConstraint, slideConstraint]];
}

- (CGFloat)sideMarginsForPhoneAndOrientation {
  if ([ABKUIUtils isNotchedPhone] && UIInterfaceOrientationIsLandscape([ABKUIUtils getInterfaceOrientation])) {
    return NotchedPhoneLandscapeSideMarginWidth;
  }
  return DefaultSideMarginWidth;
}

- (CGFloat)slideupAnimationDistance {
  BOOL animatesFromTop = ((ABKInAppMessageSlideup *)self.inAppMessage).inAppMessageSlideupAnchor == ABKInAppMessageSlideupFromTop;

  if ([ABKUIUtils isNotchedPhone]) {
    if ([ABKUIUtils getInterfaceOrientation] == UIInterfaceOrientationPortrait) {
      if (animatesFromTop) {
        return NotchedPhonePortraitTopMarginHeight;
      } else {
        return NotchedPhonePortraitBottomMarginHeight;
      }
    } else if (!animatesFromTop) {
      // Is landscape and animates from bottom
      return NotchedPhoneLandscapeBottomMarginHeight;
    }
  } else if (animatesFromTop) {
    // Non-notched that animates from top, add status bar height
    return DefaultVerticalMarginHeight + [ABKUIUtils getStatusBarSize].height;
  }
  return DefaultVerticalMarginHeight;
}

#pragma mark - Superclass methods

- (void)beforeMoveInAppMessageViewOnScreen {
  self.slideConstraint.constant = [self slideupAnimationDistance];
}

- (void)moveInAppMessageViewOnScreen {
  [self.view.superview layoutIfNeeded];
}

- (void)beforeMoveInAppMessageViewOffScreen {
  self.slideConstraint.constant = - self.view.frame.size.height;
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
