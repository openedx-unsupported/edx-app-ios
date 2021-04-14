#import "ABKInAppMessageModalViewController.h"
#import "ABKUIUtils.h"
#import "ABKInAppMessageViewController.h"
#import "ABKInAppMessageImmersive.h"
#import "Appboy.h"
#import "ABKInAppMessageController.h"
#import "ABKImageDelegate.h"

static const CGFloat ModalViewCornerRadius = 8.0f;
static const CGFloat MaxModalViewWidth = 450.0f;
static const CGFloat MinModalViewWidth = 320.0f;
static const CGFloat MaxModalViewHeight = 720.0f;

@implementation ABKInAppMessageModalViewController

- (void)viewWillAppear:(BOOL)animated {
  [super viewWillAppear:animated];
  self.enableDismissOnOutsideTap = [Appboy sharedInstance].inAppMessageController.enableDismissModalOnOutsideTap;
  
  if (((ABKInAppMessageImmersive *)self.inAppMessage).imageStyle == ABKInAppMessageTopImage) {
    [self.view.superview addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-(>=15)-[view]-(>=15)-|"
                                                                                options:0
                                                                                metrics:nil
                                                                                  views:@{@"view" : self.view}]];
    [self.view.superview addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-(>=15)-[view]-(>=15)-|"
                                                                                options:0
                                                                                metrics:nil
                                                                                  views:@{@"view" : self.view}]];
  } else {
    @try {
      UIImage *inAppImage = [[Appboy sharedInstance].imageDelegate imageFromCacheForURL:self.inAppMessage.imageURI];
      CGFloat imageAspectRatio = 1.0;
      if (inAppImage != nil) {
        imageAspectRatio = inAppImage.size.width / inAppImage.size.height;
      }
      NSLayoutConstraint *constraint = [NSLayoutConstraint constraintWithItem:self.graphicImageView
                                                                    attribute:NSLayoutAttributeWidth
                                                                    relatedBy:NSLayoutRelationEqual
                                                                       toItem:self.graphicImageView
                                                                    attribute:NSLayoutAttributeHeight
                                                                   multiplier:imageAspectRatio
                                                                     constant:0];
      [self.graphicImageView addConstraint:constraint];
      NSArray *maxWidthConstraint = [NSLayoutConstraint constraintsWithVisualFormat:@"H:[view(<=max)]"
                                                                          options:0
                                                                          metrics:@{@"max" : @(MaxModalViewWidth)}
                                                                            views:@{@"view" : self.graphicImageView}];
      NSArray *maxHeightConstraint = [NSLayoutConstraint constraintsWithVisualFormat:@"V:[view(<=max)]"
                                                                           options:0
                                                                           metrics:@{@"max" : @(MaxModalViewHeight)}
                                                                             views:@{@"view" : self.graphicImageView}];
      [self.graphicImageView addConstraints:maxWidthConstraint];
      [self.graphicImageView addConstraints:maxHeightConstraint];
      
      [self.view.superview addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-(>=15)-[view]-(>=15)-|"
                                                                                  options:0
                                                                                  metrics:nil
                                                                                    views:@{@"view" : self.view}]];
      [self.view.superview addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-(>=15)-[view]-(>=15)-|"
                                                                                  options:0
                                                                                  metrics:nil
                                                                                    views:@{@"view" : self.view}]];
    } @catch (NSException *exception) {
      NSLog(@"Braze cannot display this message because it has a height or width of 0. The graphic image has width %f and height %f and image URI %@.",
            self.graphicImageView.image.size.width, self.graphicImageView.image.size.height,
            self.inAppMessage.imageURI.absoluteString);
      [self hideInAppMessage:NO];
    }
  }
}


- (void)viewDidAppear:(BOOL)animated {
  [super viewDidAppear:animated];
  [self.textsView flashScrollIndicators];
}

- (void)viewDidLayoutSubviews {
  [super viewDidLayoutSubviews];
  if (![self isKindOfClass:[ABKInAppMessageModalViewController class]]) {
    return;
  }

  [self drawShadows];
  if (self.iconImageView) {
    // Clips the top corners if the image is wide enough in the VC
    CAShapeLayer * maskLayer = [CAShapeLayer layer];
    UIBezierPath *maskPath = [UIBezierPath bezierPathWithRoundedRect:self.view.bounds
                                                   byRoundingCorners:(UIRectCornerTopLeft | UIRectCornerTopRight)
                                                         cornerRadii:CGSizeMake(ModalViewCornerRadius, ModalViewCornerRadius)];
    maskLayer.path = maskPath.CGPath;
    self.iconImageContainerView.layer.mask = maskLayer;
    self.iconImageContainerView.clipsToBounds = YES;
  }

  if (self.textsView && !self.textsViewWidthConstraint) {
    [self addTextViewConstraints];
  }
  [self.view layoutIfNeeded];
}

- (void)loadView {
  NSBundle *bundle = [ABKUIUtils bundle:[ABKInAppMessageModalViewController class] channel:ABKInAppMessageChannel];
  [bundle loadNibNamed:@"ABKInAppMessageModalViewController"
                 owner:self
               options:nil];
  self.view.layer.cornerRadius = ModalViewCornerRadius;
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

#pragma mark - Private methods

- (void)drawShadows {
  UIBezierPath *dropShadowPath = [UIBezierPath bezierPathWithRoundedRect:self.view.bounds
                                                            cornerRadius:self.view.layer.cornerRadius];
  self.view.layer.masksToBounds = NO;
  self.view.layer.shadowOffset = CGSizeMake(0.0f, 0.0f);
  self.view.layer.shadowRadius = InAppMessageShadowBlurRadius;
  self.view.layer.shadowColor = [[UIColor blackColor] colorWithAlphaComponent:InAppMessageShadowOpacity].CGColor;
  self.view.layer.shadowPath = dropShadowPath.CGPath;

  // Make opacity of shadow match opacity of the In-App Message background
  CGFloat alpha = 0;
  [self.view.backgroundColor getRed:nil green:nil blue:nil alpha:&alpha];
  self.view.layer.shadowOpacity = alpha;
}

- (void)addTextViewConstraints {
  [self.view layoutIfNeeded];
  NSLayoutConstraint *widthConstraint = [NSLayoutConstraint constraintWithItem:self.textsView
                                                                     attribute:NSLayoutAttributeWidth
                                                                     relatedBy:NSLayoutRelationEqual
                                                                        toItem:nil
                                                                     attribute:NSLayoutAttributeNotAnAttribute
                                                                    multiplier:1
                                                                      constant:self.textsView.contentSize.width];
  self.textsViewWidthConstraint = widthConstraint;
  NSLayoutConstraint *heightConstraint = [NSLayoutConstraint constraintWithItem:self.textsView
                                                                      attribute:NSLayoutAttributeHeight
                                                                      relatedBy:NSLayoutRelationEqual
                                                                         toItem:nil
                                                                      attribute:NSLayoutAttributeNotAnAttribute
                                                                     multiplier:1
                                                                       constant:self.textsView.contentSize.height];
  widthConstraint.priority = 999;
  heightConstraint.priority = 999;
  [self.textsView addConstraint:widthConstraint];
  [self.textsView addConstraint:heightConstraint];
}

#pragma mark - Superclass methods

- (UIView *)bottomViewWithNoButton {
  return self.textsView;
}

- (void)setupLayoutForGraphic {
  [super applyImageToImageView:self.graphicImageView];
  self.graphicImageContainerView.layer.cornerRadius = self.view.layer.cornerRadius;
  
  [self.iconImageView removeFromSuperview];
  [self.iconImageContainerView removeFromSuperview];
  [self.iconLabelView removeFromSuperview];
  [self.textsView removeFromSuperview];
  self.iconImageView = nil;
  self.iconLabelView = nil;
  self.inAppMessageHeaderLabel = nil;
  self.inAppMessageMessageLabel = nil;
  self.textsView = nil;
}

- (void)setupLayoutForTopImage {
  self.textsView.translatesAutoresizingMaskIntoConstraints = NO;
  [self.graphicImageView removeFromSuperview];
  [self.graphicImageContainerView removeFromSuperview];
  self.graphicImageView = nil;
  
  // Set up the icon image/label view
  if ([super applyImageToImageView:self.iconImageView]) {
    [self.iconLabelView removeFromSuperview];
    self.iconLabelView = nil;
    
    @try {
      UIImage *inAppImage = [[Appboy sharedInstance].imageDelegate imageFromCacheForURL:self.inAppMessage.imageURI];
      CGFloat imageAspectRatio = 1.0;
      if (inAppImage != nil) {
        imageAspectRatio = inAppImage.size.width / inAppImage.size.height;
      }
      NSLayoutConstraint *constraint = [NSLayoutConstraint constraintWithItem:self.iconImageView
                                                                    attribute:NSLayoutAttributeWidth
                                                                    relatedBy:NSLayoutRelationEqual
                                                                       toItem:self.iconImageView
                                                                    attribute:NSLayoutAttributeHeight
                                                                   multiplier:imageAspectRatio
                                                                     constant:0];
      [self.iconImageView addConstraint:constraint];
    } @catch (NSException *exception) {
      NSLog(@"Braze cannot display this message because the image has a height or width of 0. The image has width %f and height %f and image URI %@.",
            self.iconImageView.image.size.width, self.iconImageView.image.size.height,
            self.inAppMessage.imageURI.absoluteString);
      [self hideInAppMessage:NO];
    }
  } else {
    self.iconImageView.hidden = YES;
    self.iconImageHeightConstraint.constant = self.iconLabelView.frame.size.height + 20.0f;
    
    if (![super applyIconToLabelView:self.iconLabelView]) {
      // When there is no image or icon, remove the iconLabelView to free up the space of the image view
      [self.iconLabelView removeFromSuperview];
      self.iconLabelView = nil;
      self.iconImageHeightConstraint.constant = 20.0f;
    }
  }
  
  if (![ABKUIUtils objectIsValidAndNotEmpty:((ABKInAppMessageImmersive *)self.inAppMessage).header]) {
    for (NSLayoutConstraint *constraint in self.inAppMessageHeaderLabel.constraints) {
      if (constraint.firstAttribute == NSLayoutAttributeHeight) {
        constraint.constant = 0.0f;
        break;
      }
    }
    self.headerBodySpaceConstraint.constant = 0.0f;
  }
  
  NSArray *maxWidthConstraint = [NSLayoutConstraint constraintsWithVisualFormat:@"H:[view(<=max)]"
                                                                        options:0
                                                                        metrics:@{@"max" : @(MaxModalViewWidth)}
                                                                          views:@{@"view" : self.view}];
  NSArray *minWidthConstraint = [NSLayoutConstraint constraintsWithVisualFormat:@"H:[view(>=min)]"
                                                                        options:0
                                                                        metrics:@{@"min" : @(MinModalViewWidth)}
                                                                          views:@{@"view" : self.view}];
  NSArray *maxHeightConstraint = [NSLayoutConstraint constraintsWithVisualFormat:@"V:[view(<=max)]"
                                                                         options:0
                                                                         metrics:@{@"max" : @(MaxModalViewHeight)}
                                                                           views:@{@"view" : self.view}];
  [self.view addConstraints:maxWidthConstraint];
  [self.view addConstraints:minWidthConstraint];
  [self.view addConstraints:maxHeightConstraint];
}

@end
