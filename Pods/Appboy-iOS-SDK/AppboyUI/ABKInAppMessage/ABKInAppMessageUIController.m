#import "ABKInAppMessageUIController.h"
#import "AppboyKit.h"
#import "ABKInAppmessageWindowController.h"
#import "ABKUIUtils.h"
#import "ABKInAppMessageSlideupViewController.h"
#import "ABKInAppMessageModalViewController.h"
#import "ABKInAppMessageHTMLFullViewController.h"
#import "ABKInAppMessageHTMLViewController.h"
#import "ABKInAppMessageFullViewController.h"

@implementation ABKInAppMessageUIController

- (instancetype)init {
  if (self = [super init]) {
    _supportedOrientationMask = UIInterfaceOrientationMaskAll;
    _preferredOrientation = UIInterfaceOrientationUnknown;
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(receiveKeyboardWasShownNotification:)
                                                 name:UIKeyboardWillShowNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(receiveKeyboardDidHideNotification:)
                                                 name:UIKeyboardDidHideNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(inAppMessageWindowDismissed:)
                                                 name:ABKNotificationInAppMessageWindowDismissed
                                               object:nil];
  }
  return self;
}

#pragma mark - Show and Hide In-app Message

- (void)showInAppMessage:(ABKInAppMessage *)inAppMessage {
  if ([UIDevice currentDevice].userInterfaceIdiom != UIUserInterfaceIdiomPad) {
    // Check the device orientation before displaying the in-app message
    UIInterfaceOrientation statusBarOrientation = [ABKUIUtils getInterfaceOrientation];
    NSString *errorMessage = @"The in-app message %@ with %@ orientation shouldn't be displayed in %@, disregarding this in-app message.";
    if (inAppMessage.orientation == ABKInAppMessageOrientationPortrait &&
        !UIInterfaceOrientationIsPortrait(statusBarOrientation)) {
      NSLog(errorMessage, inAppMessage, @"portrait", @"landscape");
      return;
    }
    if (inAppMessage.orientation == ABKInAppMessageOrientationLandscape &&
        !UIInterfaceOrientationIsLandscape(statusBarOrientation)) {
      NSLog(errorMessage, inAppMessage, @"landscape", @"portrait");
      return;
    }
  }
  
  if ([inAppMessage isKindOfClass:[ABKInAppMessageImmersive class]]) {
    ABKInAppMessageImmersive *immersiveInAppMessage = (ABKInAppMessageImmersive *)inAppMessage;
    if (immersiveInAppMessage.imageStyle == ABKInAppMessageGraphic &&
        ![ABKUIUtils objectIsValidAndNotEmpty:immersiveInAppMessage.imageURI]) {
      NSLog(@"The in-app message has graphic image style but no image, discard this in-app message.");
      return;
    }
    if ([immersiveInAppMessage isKindOfClass:[ABKInAppMessageFull class]] &&
        ![ABKUIUtils objectIsValidAndNotEmpty:immersiveInAppMessage.imageURI]) {
      NSLog(@"The in-app message is a full in-app message without an image, discard this in-app message.");
      return;
    }
  }
  
  if (inAppMessage.inAppMessageClickActionType == ABKInAppMessageNoneClickAction &&
      [inAppMessage isKindOfClass:[ABKInAppMessageSlideup class]]) {
    ((ABKInAppMessageSlideup *)inAppMessage).hideChevron = YES;
  }
  
  ABKInAppMessageViewController *inAppMessageViewController = nil;
  if ([self.uiDelegate respondsToSelector:@selector(inAppMessageViewControllerWithInAppMessage:)]) {
    inAppMessageViewController = [self.uiDelegate inAppMessageViewControllerWithInAppMessage:inAppMessage];
  } else {
    if ([inAppMessage isKindOfClass:[ABKInAppMessageSlideup class]]) {
      inAppMessageViewController = [[ABKInAppMessageSlideupViewController alloc]
                                    initWithInAppMessage:inAppMessage];
    } else if ([inAppMessage isKindOfClass:[ABKInAppMessageModal class]]) {
      inAppMessageViewController = [[ABKInAppMessageModalViewController alloc]
                                    initWithInAppMessage:inAppMessage];
    } else if ([inAppMessage isKindOfClass:[ABKInAppMessageFull class]]) {
      inAppMessageViewController = [[ABKInAppMessageFullViewController alloc]
                                    initWithInAppMessage:inAppMessage];
    } else if ([inAppMessage isKindOfClass:[ABKInAppMessageHTMLFull class]]) {
      inAppMessageViewController = [[ABKInAppMessageHTMLFullViewController alloc]
                                    initWithInAppMessage:inAppMessage];
    } else if ([inAppMessage isKindOfClass:[ABKInAppMessageHTML class]]) {
      inAppMessageViewController = [[ABKInAppMessageHTMLViewController alloc]
                                    initWithInAppMessage:inAppMessage];
    }
  }
  if (inAppMessageViewController) {
    ABKInAppMessageWindowController *windowController = [[ABKInAppMessageWindowController alloc]
                                                         initWithInAppMessage:inAppMessage
                                                   inAppMessageViewController:inAppMessageViewController
                                                         inAppMessageDelegate:self.uiDelegate];
    windowController.supportedOrientationMask = self.supportedOrientationMask;
    windowController.preferredOrientation = self.preferredOrientation;
    self.inAppMessageWindowController = windowController;
    if (@available(iOS 13.0, *)) {
      inAppMessageViewController.overrideUserInterfaceStyle = inAppMessage.overrideUserInterfaceStyle;
    }
    [self.inAppMessageWindowController displayInAppMessageViewWithAnimation:inAppMessage.animateIn];
  }
}

- (ABKInAppMessageDisplayChoice)getCurrentDisplayChoiceForInAppMessage:(ABKInAppMessage *)inAppMessage {
  ABKInAppMessageDisplayChoice inAppMessageDisplayChoice = self.keyboardVisible ?
    ABKDisplayInAppMessageLater : ABKDisplayInAppMessageNow;
  if (inAppMessageDisplayChoice == ABKDisplayInAppMessageLater) {
    NSLog(@"Initially setting in-app message display choice to ABKDisplayInAppMessageLater due to visible keyboard.");
  }
  if ([self.uiDelegate respondsToSelector:@selector(beforeInAppMessageDisplayed:withKeyboardIsUp:)]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    // ignore deprecation warning to support client integrations using the deprecated method
    inAppMessageDisplayChoice = [self.uiDelegate beforeInAppMessageDisplayed:inAppMessage
                                                        withKeyboardIsUp:self.keyboardVisible];
#pragma clang diagnostic pop
  } else if ([[Appboy sharedInstance].inAppMessageController.delegate
              respondsToSelector:@selector(beforeInAppMessageDisplayed:)]) {
    inAppMessageDisplayChoice = [[Appboy sharedInstance].inAppMessageController.delegate
                                 beforeInAppMessageDisplayed:inAppMessage];
  }
  return inAppMessageDisplayChoice;
}

- (ABKInAppMessageDisplayChoice)getCurrentDisplayChoiceForControlInAppMessage:(ABKInAppMessage *)controlInAppMessage {
  ABKInAppMessageDisplayChoice inAppMessageDisplayChoice = self.keyboardVisible ? ABKDisplayInAppMessageLater : ABKDisplayInAppMessageNow;
  if (inAppMessageDisplayChoice == ABKDisplayInAppMessageLater) {
    NSLog(@"Initially setting in-app message display choice to ABKDisplayInAppMessageLater due to visible keyboard.");
  }
  if ([[Appboy sharedInstance].inAppMessageController.delegate
              respondsToSelector:@selector(beforeControlMessageImpressionLogged:)]) {
    inAppMessageDisplayChoice = [Appboy.sharedInstance.inAppMessageController.delegate beforeControlMessageImpressionLogged:controlInAppMessage];
  }
  return inAppMessageDisplayChoice;
}

- (BOOL)inAppMessageCurrentlyVisible {
  if (self.inAppMessageWindowController) {
    return YES;
  }
  return NO;
}

- (void)hideCurrentInAppMessage:(BOOL)animated {
  @try {
    if (self.inAppMessageWindowController) {
      [self.inAppMessageWindowController hideInAppMessageViewWithAnimation:animated];
    }
  }
  @catch (NSException *exception) {
    NSLog(@"An error occured and this in-app message couldn't be hidden.");
  }
}

- (void)inAppMessageWindowDismissed:(NSNotification *)notification {
  // We listen to this notification so that we know when the screen is clear of in-app messages
  // and a new in-app message can be shown.
  self.inAppMessageWindowController = nil;
}

#pragma mark - Keyboard

- (void)receiveKeyboardDidHideNotification:(NSNotification *)notification {
  self.keyboardVisible = NO;
}

- (void)receiveKeyboardWasShownNotification:(NSNotification *)notification {
  self.keyboardVisible = YES;
  [self.inAppMessageWindowController keyboardWasShown];
}

#pragma mark - Set UIDelegate

- (void)setInAppMessageUIDelegate:(id)uiDelegate {
  _uiDelegate = uiDelegate;
}

#pragma mark - Dealloc

- (void)dealloc {
  [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
