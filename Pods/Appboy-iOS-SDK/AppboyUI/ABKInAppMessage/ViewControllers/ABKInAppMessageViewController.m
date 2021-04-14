#import <CoreText/CoreText.h>
#import "ABKInAppMessageViewController.h"
#import "ABKInAppMessageView.h"
#import "ABKInAppMessageWindowController.h"
#import "ABKUIUtils.h"
#import "Appboy.h"

static const float InAppMessageIconLabelCornerRadius_iPhone = 10.0f;
static const float InAppMessageIconLabelCornerRadius_iPad = 15.0f;
static NSString *const FontAwesomeName = @"FontAwesome";

@implementation ABKInAppMessageViewController

- (instancetype)initWithInAppMessage:(ABKInAppMessage *)inAppMessage {
  if (self = [super init]) {
    _inAppMessage = inAppMessage;
    _isiPad = [UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad;
    return self;
  } else {
    return nil;
  }
}

#pragma mark - Lifecycle Methods

- (void)viewWillAppear:(BOOL)animated {
  [super viewWillAppear:animated];
  [ABKInAppMessageView class];

  // Set colors of the IAM view at display time
  self.inAppMessageMessageLabel.text = self.inAppMessage.message;
  self.inAppMessageMessageLabel.textAlignment = self.inAppMessage.messageTextAlignment;
  if (self.inAppMessage.backgroundColor != nil) {
    self.view.backgroundColor = self.inAppMessage.backgroundColor;
  }
  if (self.inAppMessage.textColor != nil) {
    [self.inAppMessageMessageLabel setTextColor:self.inAppMessage.textColor];
  }
  self.iconImageView.contentMode = self.inAppMessage.imageContentMode;
}

- (void)viewDidAppear:(BOOL)animated {
  [super viewDidAppear:animated];
  UIAccessibilityPostNotification(UIAccessibilityScreenChangedNotification,
                                  self.inAppMessageMessageLabel);
}

- (void)viewDidDisappear:(BOOL)animated {
  [super viewDidDisappear:animated];
  UIAccessibilityPostNotification(UIAccessibilityScreenChangedNotification,
                                  nil);
}

- (BOOL)prefersStatusBarHidden {
  return ABKUIUtils.applicationStatusBarHidden;
}

- (UIStatusBarStyle)preferredStatusBarStyle {
  return ABKUIUtils.applicationStatusBarStyle;
}

#pragma mark - UIViewController Methods

// Inherit the supported orientations from the currently active application view
// controller (the one immediately under the in-app message window)
- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
  return ABKUIUtils.activeApplicationViewController.supportedInterfaceOrientations;
}

#pragma mark - In-app Message Initialization

- (BOOL)applyIconToLabelView:(UILabel *)iconLabelView {
  if ([ABKUIUtils objectIsValidAndNotEmpty:self.inAppMessage.icon]) {
    // Check if font awesome is already registered in the application. If not, register it.
    // The size can be any number here.
    if ([UIFont fontWithName:FontAwesomeName size:30] == nil) {
      NSString *fontPath = [[ABKUIUtils bundle:[ABKInAppMessageViewController class] channel:ABKInAppMessageChannel]
                                     pathForResource:FontAwesomeName
                                              ofType:@"otf"];
      NSData *fontData = [NSData dataWithContentsOfFile:fontPath];
      CFErrorRef error;
      CGDataProviderRef provider = CGDataProviderCreateWithCFData((__bridge CFDataRef)fontData);
      CGFontRef font = CGFontCreateWithDataProvider(provider);
      BOOL failedToRegisterFont = NO;
      if (!CTFontManagerRegisterGraphicsFont(font, &error)) {
        CFStringRef errorDescription = CFErrorCopyDescription(error);
        NSLog(@"Error: Cannot load Font Awesome");
        CFBridgingRelease(errorDescription);
        failedToRegisterFont = YES;
      }
      CFRelease(font);
      CFRelease(provider);
      if (failedToRegisterFont) {
        return NO;
      }
    }
    iconLabelView.font = [UIFont fontWithName:FontAwesomeName size:self.iconLabelView.font.pointSize];
    // The icon here is a Unicode string, so we use a text label instead of an image view
    iconLabelView.text = self.inAppMessage.icon;
    iconLabelView.textColor = self.inAppMessage.iconColor == nil ? [UIColor whiteColor] : self.inAppMessage.iconColor;
    iconLabelView.backgroundColor = self.inAppMessage.iconBackgroundColor == nil ?
      [UIColor colorWithRed:RedValueOfDefaultIconColorAndButtonBgColor
                      green:GreenValueOfDefaultIconColorAndButtonBgColor
                       blue:BlueValueOfDefaultIconColorAndButtonBgColor
                      alpha:AlphaValueOfDefaultIconColorAndButtonBgColor]
      : self.inAppMessage.iconBackgroundColor;
    iconLabelView.layer.cornerRadius = self.isiPad ? InAppMessageIconLabelCornerRadius_iPad :
      InAppMessageIconLabelCornerRadius_iPhone;
    iconLabelView.layer.masksToBounds = YES;
    return YES;
  }
  return NO;
}

// Here we try to find the icon image and set it to the given image view. We will first try to find if the icon image
// is one of the default Braze icon images. If not, we try to check the icon URI and download the image
// asynchronously.
// This method returns YES if we can find a default icon image, or there is a valid icon image URL. It returns NO when
// we cannot find any icon from the in-app message, and won't do anything to the given image view.
- (BOOL)applyImageToImageView:(UIImageView *)iconImageView {
  if ([ABKUIUtils objectIsValidAndNotEmpty:self.inAppMessage.imageURI]) {
    if ([Appboy sharedInstance].imageDelegate) {
      [[Appboy sharedInstance].imageDelegate setImageForView:iconImageView
                      showActivityIndicator:NO
                                    withURL:self.inAppMessage.imageURI
                           imagePlaceHolder:nil
                                  completed:nil];
      return YES;
    } else {
      [self hideInAppMessage:NO];
      return NO;
    }
  }
  return NO;
}

#pragma mark - Animation

- (void)hideInAppMessage:(BOOL)animated {
  ABKInAppMessageWindowController *parentInAppMessageWindowController = (ABKInAppMessageWindowController *)self.parentViewController;
  [parentInAppMessageWindowController hideInAppMessageViewWithAnimation:animated];
}

- (void)beforeMoveInAppMessageViewOnScreen {}

- (void)moveInAppMessageViewOnScreen {}

- (void)beforeMoveInAppMessageViewOffScreen {}

- (void)moveInAppMessageViewOffScreen {}

@end
