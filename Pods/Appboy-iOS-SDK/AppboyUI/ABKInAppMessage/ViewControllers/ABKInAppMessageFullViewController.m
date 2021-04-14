#import "ABKInAppMessageFullViewController.h"
#import "ABKInAppMessageViewController.h"
#import "ABKInAppMessageImmersive.h"
#import "ABKUIUtils.h"

static const CGFloat FullViewInIPadCornerRadius = 8.0f;
static const CGFloat MaxLongEdge = 720.0f;
static const CGFloat MaxShortEdge = 450.0f;
static const CGFloat CloseXPadding = 15.0f;

@implementation ABKInAppMessageFullViewController

- (void)viewWillAppear:(BOOL)animated {
  [super viewWillAppear:animated];
  
  CGFloat maxWidth = MaxShortEdge;
  CGFloat maxHeight = MaxLongEdge;
  if (self.inAppMessage.orientation == ABKInAppMessageOrientationLandscape) {
    maxWidth = MaxLongEdge;
    maxHeight = MaxShortEdge;
  }
  if (self.isiPad) {
    NSArray *widthConstraints = [NSLayoutConstraint constraintsWithVisualFormat:@"H:[view(<=max)]"
                                                                        options:0
                                                                        metrics:@{@"max" : @(maxWidth)}
                                                                          views:@{@"view" : self.view}];
    NSArray *heightConstraints = [NSLayoutConstraint constraintsWithVisualFormat:@"V:[view(<=max)]"
                                                                         options:0
                                                                         metrics:@{@"max" : @(maxHeight)}
                                                                           views:@{@"view" : self.view}];
    [self.view addConstraints:widthConstraints];
    [self.view addConstraints:heightConstraints];
    self.view.layer.cornerRadius = FullViewInIPadCornerRadius;
    self.view.layer.masksToBounds = YES;
    
    [self.view.superview addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-(>=0)-[view]-(>=0)-|"
                                                                                options:0
                                                                                metrics:nil
                                                                                  views:@{@"view" : self.view}]];
  } else {
    NSLayoutConstraint *leadConstraint = [NSLayoutConstraint constraintWithItem:self.view
                                                                      attribute:NSLayoutAttributeLeading
                                                                      relatedBy:NSLayoutRelationEqual
                                                                         toItem:self.view.superview
                                                                      attribute:NSLayoutAttributeLeading
                                                                     multiplier:1
                                                                       constant:0.0];
    NSLayoutConstraint *trailConstraint = [NSLayoutConstraint constraintWithItem:self.view.superview
                                                                       attribute:NSLayoutAttributeTrailing
                                                                       relatedBy:NSLayoutRelationEqual
                                                                          toItem:self.view
                                                                       attribute:NSLayoutAttributeTrailing
                                                                      multiplier:1
                                                                        constant:0.0];
    [self.view.superview addConstraints:@[leadConstraint, trailConstraint]];
  }
  
  NSString *heightVisualFormat = self.isiPad? @"V:|-(>=0)-[view]-(>=0)-|" : @"V:|[view]|";
  NSArray *heightConstraints = [NSLayoutConstraint constraintsWithVisualFormat:heightVisualFormat
                                                                       options:0
                                                                       metrics:nil
                                                                         views:@{@"view" : self.view}];
  [self.view.superview addConstraints:heightConstraints];
}

- (void)viewDidLayoutSubviews {
  [super viewDidLayoutSubviews];
  // Close X should be equidistant from top and right in notched phones despite presence of (hidden) status bar
  if (![ABKUIUtils isNotchedPhone]) {
    if (!self.isiPad) {
      CGSize statusBarSize = [ABKUIUtils getStatusBarSize];
      self.closeXButtonTopConstraint.constant = CloseXPadding - statusBarSize.height;
    }
  } else {
    // Move close x button slightly higher for notched phones in portrait
    BOOL isPortrait = UIInterfaceOrientationIsPortrait([ABKUIUtils getInterfaceOrientation]);
    self.closeXButtonTopConstraint.constant = isPortrait ? 0.0f : CloseXPadding;
  }
}

- (void)viewDidAppear:(BOOL)animated {
  [super viewDidAppear:animated];
  [self.textsView flashScrollIndicators];
}

- (void)loadView {
  NSBundle *bundle = [ABKUIUtils bundle:[ABKInAppMessageFullViewController class] channel:ABKInAppMessageChannel];
  [bundle loadNibNamed:@"ABKInAppMessageFullViewController"
                 owner:self
               options:nil];
  self.inAppMessageHeaderLabel.font = HeaderLabelDefaultFont;
  self.inAppMessageMessageLabel.font = MessageLabelDefaultFont;
  
  if (self.inAppMessage.message) {
    NSMutableAttributedString *attributedStringMessage = [[NSMutableAttributedString alloc] initWithString:self.inAppMessage.message];
    NSMutableParagraphStyle *messageStyle = [[NSMutableParagraphStyle alloc] init];
    [messageStyle setLineSpacing:2];
    [attributedStringMessage addAttribute:NSParagraphStyleAttributeName
                                    value:messageStyle
                                    range:NSMakeRange(0, self.inAppMessage.message.length)];
    self.inAppMessageMessageLabel.attributedText = attributedStringMessage;
  }
  if ([self.inAppMessage isKindOfClass:[ABKInAppMessageImmersive class]]) {
    if (((ABKInAppMessageImmersive *)self.inAppMessage).header) {
      NSMutableAttributedString *attributedStringHeader = [[NSMutableAttributedString alloc] initWithString:((ABKInAppMessageImmersive *)self.inAppMessage).header];
      NSMutableParagraphStyle *headerStyle = [[NSMutableParagraphStyle alloc] init];
      [headerStyle setLineSpacing:2];
      [attributedStringHeader addAttribute:NSParagraphStyleAttributeName
                                     value:headerStyle
                                     range:NSMakeRange(0, ((ABKInAppMessageImmersive *)self.inAppMessage).header.length)];
      self.inAppMessageMessageLabel.attributedText = attributedStringHeader;
    }
  }
}

#pragma mark - Superclass methods

- (BOOL)prefersStatusBarHidden {
  return YES;
}

- (UIView *)bottomViewWithNoButton {
  return self.textsView;
}

- (void)setupLayoutForGraphic {
  [super applyImageToImageView:self.graphicImageView];
  [self.iconImageView removeFromSuperview];
  [self.textsView removeFromSuperview];
  self.iconImageView = nil;
  self.textsView = nil;
}

- (void)setupLayoutForTopImage {
  [self.graphicImageView removeFromSuperview];
  self.graphicImageView = nil;
  self.inAppMessageMessageLabel.translatesAutoresizingMaskIntoConstraints = NO;
  self.textsView.translatesAutoresizingMaskIntoConstraints = NO;
  
  // When there is no header, we set following two things to 0:
  // (1) the header label's height
  // (2) the constraint's height between header label and the message label
  // so that the space is collapsed.
  if (![ABKUIUtils objectIsValidAndNotEmpty:((ABKInAppMessageImmersive *)self.inAppMessage).header]) {
    for (NSLayoutConstraint *constraint in self.inAppMessageHeaderLabel.constraints) {
      if (constraint.firstAttribute == NSLayoutAttributeHeight) {
        constraint.constant = 0.0f;
        break;
      }
    }
    self.headerBodySpaceConstraint.constant = 0.0f;
  }
  [super applyImageToImageView:self.iconImageView];
}

@end
