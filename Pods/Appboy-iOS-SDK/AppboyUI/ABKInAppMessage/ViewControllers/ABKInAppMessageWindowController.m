#import "ABKInAppMessageWindowController.h"
#import "ABKInAppMessageWindow.h"
#import "ABKInAppMessageView.h"
#import "ABKInAppMessageModal.h"
#import "ABKInAppMessageFull.h"
#import "ABKInAppMessageHTMLFull.h"
#import "ABKInAppMessageHTML.h"
#import "ABKInAppMessageHTMLBase.h"
#import "ABKInAppMessageHTMLBaseViewController.h"
#import "ABKInAppMessageImmersiveViewController.h"
#import "ABKInAppMessageSlideupViewController.h"
#import "ABKInAppMessageModalViewController.h"
#import "ABKInAppMessageViewController.h"
#import "ABKURLDelegate.h"
#import "ABKUIURLUtils.h"
#import "ABKUIUtils.h"

static CGFloat const MinimumInAppMessageDismissVelocity = 20.0;
static CGFloat const SlideUpDragResistanceFactor = 0.055;
static NSInteger const KeyWindowRetryMaxCount = 10;

@interface ABKInAppMessageWindowController ()

@property (nonatomic, assign) NSInteger keyWindowRetryCount;

@end

@implementation ABKInAppMessageWindowController

- (instancetype)initWithInAppMessage:(ABKInAppMessage *)inAppMessage
          inAppMessageViewController:(ABKInAppMessageViewController *)inAppMessageViewController
                inAppMessageDelegate:(id<ABKInAppMessageUIDelegate>)delegate {
  if (self = [super init]) {
    _inAppMessage = inAppMessage;
    _inAppMessageViewController = inAppMessageViewController;
    _inAppMessageUIDelegate = (id<ABKInAppMessageUIDelegate>)delegate;
    
    _inAppMessageWindow = [self createInAppMessageWindow];
    _inAppMessageWindow.backgroundColor = [UIColor clearColor];
    _inAppMessageWindow.autoresizingMask = UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleRightMargin;
    _inAppMessageIsTapped = NO;
    _clickedButtonId = -1;
    _keyWindowRetryCount = 0;
  }
  return self;
}

#pragma mark - Lifecycle Methods

- (void)viewDidLoad {
  [super viewDidLoad];
  [self addChildViewController:self.inAppMessageViewController];
  [self.inAppMessageViewController didMoveToParentViewController:self];
  self.view.backgroundColor = [UIColor clearColor];

  if ([self.inAppMessage isKindOfClass:[ABKInAppMessageSlideup class]]) {
    
    // Note: this gestureRecognizer won't catch taps which occur during the animation.
    UITapGestureRecognizer *inAppSlideupTapGesture = [[UITapGestureRecognizer alloc]
                                                      initWithTarget:self
                                                              action:@selector(inAppMessageTapped:)];
    [self.inAppMessageViewController.view addGestureRecognizer:inAppSlideupTapGesture];
    UIPanGestureRecognizer *inAppSlideupPanGesture = [[UIPanGestureRecognizer alloc]
                                                      initWithTarget:self
                                                              action:@selector(inAppSlideupWasPanned:)];
    [self.inAppMessageViewController.view addGestureRecognizer:inAppSlideupPanGesture];
    // We want to detect the pan gesture first, so we only recognize a tap when the pan recognizer fails.
    [inAppSlideupTapGesture requireGestureRecognizerToFail:inAppSlideupPanGesture];
  } else if ([self.inAppMessage isKindOfClass:[ABKInAppMessageImmersive class]]) {
    UITapGestureRecognizer *inAppImmersiveInsideTapGesture = [[UITapGestureRecognizer alloc]
                                                              initWithTarget:self
                                                                      action:@selector(inAppMessageTapped:)];
    [self.inAppMessageViewController.view addGestureRecognizer:inAppImmersiveInsideTapGesture];

    if ([self.inAppMessage isKindOfClass:[ABKInAppMessageModal class]]) {
      self.inAppMessageWindow.handleAllTouchEvents = YES;
      UITapGestureRecognizer *inAppModalOutsideTapGesture = [[UITapGestureRecognizer alloc]
                                                              initWithTarget:self
                                                                      action:@selector(inAppMessageTappedOutside:)];
      [self.view addGestureRecognizer:inAppModalOutsideTapGesture];
    }
  }

  if ([self.inAppMessageViewController isKindOfClass:[ABKInAppMessageImmersiveViewController class]] ||
      [self.inAppMessageViewController isKindOfClass:[ABKInAppMessageHTMLBaseViewController class]]) {
    self.inAppMessageWindow.accessibilityViewIsModal = YES;
  }

  [self.view addSubview:self.inAppMessageViewController.view];
}

- (UIViewController *)childViewControllerForStatusBarHidden {
  return self.inAppMessageViewController;
}

- (UIViewController *)childViewControllerForStatusBarStyle {
  return self.inAppMessageViewController;
}

- (void)viewWillAppear:(BOOL)animated {
  [super viewWillAppear:animated];
  
  // When the in-app message first become visible, monitor windows changes in the view hierarchy to
  // ensure that the in-app message stays visible.
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(handleWindowDidBecomeKeyNotification:)
                                               name:UIWindowDidBecomeKeyNotification
                                             object:nil];
}

- (void)viewDidDisappear:(BOOL)animated {
  [super viewDidDisappear:animated];
  
  [[NSNotificationCenter defaultCenter] removeObserver:self
                                                  name:UIWindowDidBecomeKeyNotification
                                                object:nil];
}

#pragma mark - Rotation

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
  return self.supportedOrientationMask;
}

- (BOOL)shouldAutorotate {
  if ([UIDevice currentDevice].userInterfaceIdiom != UIUserInterfaceIdiomPad &&
      self.inAppMessage.orientation != ABKInAppMessageOrientationAny &&
      !self.inAppMessageWindow.hidden) {
    return NO;
  } else {
    return YES;
  }
}

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation {
  if (self.preferredOrientation != UIInterfaceOrientationUnknown) {
    return self.preferredOrientation;
  }
  return [ABKUIUtils getInterfaceOrientation];
}

#pragma mark - Gesture Recognizers

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
  return ![touch.view isKindOfClass:[ABKInAppMessageView class]];
}

- (void)inAppSlideupWasPanned:(UIPanGestureRecognizer *)panGestureRecognizer {
  ABKInAppMessageSlideupViewController *slideupVC = (ABKInAppMessageSlideupViewController *)self.inAppMessageViewController;
  BOOL animatesFromTop = ((ABKInAppMessageSlideup *)self.inAppMessage).inAppMessageSlideupAnchor == ABKInAppMessageSlideupFromTop;
  CGFloat offset = [panGestureRecognizer translationInView:self.view].y;
  CGFloat velocity = [panGestureRecognizer velocityInView:self.view].y;
  
  switch (panGestureRecognizer.state) {
    case UIGestureRecognizerStateChanged: {
      if (animatesFromTop) {
        slideupVC.offset = offset <= 0 ? offset : (SlideUpDragResistanceFactor * offset);
      } else {
        slideupVC.offset = offset >= 0 ? offset : (SlideUpDragResistanceFactor * offset);
      }
      break;
    }
      
    case UIGestureRecognizerStateEnded:
    case UIGestureRecognizerStateCancelled: {
      // Reset position
      if ((animatesFromTop && slideupVC.offset > 0) ||
          (!animatesFromTop && slideupVC.offset < 0) ||
          (fabs(velocity) < MinimumInAppMessageDismissVelocity && fabs(offset) < 16)) {
        slideupVC.offset = 0;
        [UIView animateWithDuration:0.2 animations:^{
          [self.view layoutIfNeeded];
        }];
        return;
      }

      // Dismiss
      [self invalidateSlideAwayTimer];

      if ([self.inAppMessageUIDelegate respondsToSelector:@selector(onInAppMessageDismissed:)]) {
        [self.inAppMessageUIDelegate onInAppMessageDismissed:self.inAppMessage];
      }

      [slideupVC beforeMoveInAppMessageViewOffScreen];
      [UIView animateWithDuration:0.2
                       animations:^{
                         [slideupVC moveInAppMessageViewOffScreen];
                       }
                       completion:^(BOOL finished) {
                         if (finished) {
                           [self hideInAppMessageWindow];
                         }
                       }];
      break;
    }
      
    default:
      break;
  }
}

- (void)inAppMessageTapped:(id)sender {
  if ([self.inAppMessage isKindOfClass:[ABKInAppMessageImmersive class]] &&
      [ABKUIUtils objectIsValidAndNotEmpty:((ABKInAppMessageImmersive *)self.inAppMessage).buttons]) {
    return;
  }
  [self invalidateSlideAwayTimer];
  self.inAppMessageIsTapped = YES;
  
  if (![self delegateHandlesInAppMessageClick]) {
    [self inAppMessageClickedWithActionType:self.inAppMessage.inAppMessageClickActionType
                                        URL:self.inAppMessage.uri
                           openURLInWebView:self.inAppMessage.openUrlInWebView];
  }
}

- (void)inAppMessageTappedOutside:(id)sender {
  if (![self.inAppMessage isKindOfClass:[ABKInAppMessageModal class]]) {
    return;
  }
  if ([self.inAppMessageViewController isKindOfClass:ABKInAppMessageModalViewController.class]) {
    ABKInAppMessageModalViewController *viewController = (ABKInAppMessageModalViewController *)self.inAppMessageViewController;
    if (viewController.enableDismissOnOutsideTap) {
      [viewController dismissInAppMessage:self.inAppMessage];
    }
  }
}

#pragma mark - Timer

- (void)invalidateSlideAwayTimer {
  if (self.slideAwayTimer != nil) {
    [self.slideAwayTimer invalidate];
    self.slideAwayTimer = nil;
  }
}

- (void)inAppMessageTimerFired:(NSTimer *)timer {
  if ([self.inAppMessageUIDelegate respondsToSelector:@selector(onInAppMessageDismissed:)]) {
    [self.inAppMessageUIDelegate onInAppMessageDismissed:self.inAppMessage];
  }
  [self hideInAppMessageViewWithAnimation:self.inAppMessage.animateOut];
}

#pragma mark - Keyboard

- (void)keyboardWasShown {
  if (![self.inAppMessageViewController isKindOfClass:[ABKInAppMessageHTMLBaseViewController class]]
      && !self.inAppMessageWindow.hidden) {
    // If the keyboard is shown while an in-app message is on the screen, we hide the in-app message
    [self hideInAppMessageWindow];
  }
}

#pragma mark - Windows

/*!
 * React to windows changes in the view hierarchy. This is needed to ensure that the in-app message
 * stays visible in cases where the host app decides to display a window (possibly the app's main
 * window) over our in-app message.
 *
 * This method tries to make the in-app message window visible up to 10 times. The in-app message
 * is dismissed when reaching that value to prevent infinite loops when another window in the view
 * hierarchy has a similar behavior.
 *
 * e.g. Some clients have extra logic when bootstrapping their app that can lead to the app's main
 * window being made key and visible after a delay at startup. In the case of test in-app messages
 * delivered via push notifications, our in-app messages would be displayed before the host app
 * window being made key and visible. Soon after, the host app window takes over and hides our
 * in-app message.
 */
- (void)handleWindowDidBecomeKeyNotification:(NSNotification *)notification {
  UIWindow *window = notification.object;

  // Skip for any in-app message window
  if ([window isKindOfClass:[ABKInAppMessageWindow class]]) {
    return;
  }
  // Skip if the new key window is meant to be displayed above the in-app message (alert, sheet,
  // host app toast)
  if (window.windowLevel > UIWindowLevelNormal) {
    return;
  }

  // Dismiss in-app message if we can't guarantee its visibility.
  self.keyWindowRetryCount += 1;
  if (self.keyWindowRetryCount >= KeyWindowRetryMaxCount) {
    NSLog(@"Error: Failed to make in-app message window key and visible %ld times, dismissing the in-app message.", (long)self.keyWindowRetryCount);
    [self hideInAppMessageViewWithAnimation:YES];
    return;
  }
  
  // Force in-app message window to be displayed
  [self.inAppMessageWindow makeKeyAndVisible];
}

#pragma mark - Display and Hide In-app Message

- (void)displayInAppMessageViewWithAnimation:(BOOL)withAnimation {
  dispatch_async(dispatch_get_main_queue(), ^{
    // Set the root view controller after the inAppMessagewindow becomes the key window so it gets the
    // correct window size during and after rotation.
    self.keyWindowRetryCount = 0;
    [self.inAppMessageWindow makeKeyWindow];
    self.inAppMessageWindow.rootViewController = self;
    self.inAppMessageWindow.hidden = NO;

    if (self.inAppMessage.inAppMessageDismissType == ABKInAppMessageDismissAutomatically) {
      self.slideAwayTimer = [NSTimer scheduledTimerWithTimeInterval:self.inAppMessage.duration + InAppMessageAnimationDuration
                                                             target:self
                                                           selector:@selector(inAppMessageTimerFired:)
                                                           userInfo:nil repeats:NO];
    }
    [self.view layoutIfNeeded];
    [self.inAppMessageViewController beforeMoveInAppMessageViewOnScreen];
    if (withAnimation) {
      [UIView animateWithDuration:InAppMessageAnimationDuration
                            delay:0
                          options:UIViewAnimationOptionBeginFromCurrentState
                       animations:^{
                         [self.inAppMessageViewController moveInAppMessageViewOnScreen];
                       }
                       completion:^(BOOL finished){
                         [self.inAppMessage logInAppMessageImpression];
                       }];
    } else {
      [self.inAppMessageViewController moveInAppMessageViewOnScreen];
      [self.inAppMessage logInAppMessageImpression];
    }
  });
}

- (void)hideInAppMessageViewWithAnimation:(BOOL)withAnimation {
  [self hideInAppMessageViewWithAnimation:withAnimation completionHandler:nil];
}

- (void)hideInAppMessageViewWithAnimation:(BOOL)withAnimation
                        completionHandler:(void (^ __nullable)(void))completionHandler {
  [self.slideAwayTimer invalidate];
  self.slideAwayTimer = nil;
  [self.view layoutIfNeeded];
  [self.inAppMessageViewController beforeMoveInAppMessageViewOffScreen];
  if (withAnimation) {
    [UIView animateWithDuration:InAppMessageAnimationDuration
                          delay:0
                        options:UIViewAnimationOptionBeginFromCurrentState
                     animations:^{
                       [self.inAppMessageViewController moveInAppMessageViewOffScreen];
                     }
                     completion:^(BOOL finished){
                       if (completionHandler) {
                         completionHandler();
                       }
                       [self hideInAppMessageWindow];
                     }];
  } else {
    [self.inAppMessageViewController moveInAppMessageViewOffScreen];
    [self hideInAppMessageWindow];
  }
}

- (void)hideInAppMessageWindow {
  [self.slideAwayTimer invalidate];
  self.slideAwayTimer = nil;

  self.inAppMessageWindow.rootViewController = nil;
  self.inAppMessageWindow = nil;
  [[NSNotificationCenter defaultCenter] postNotificationName:ABKNotificationInAppMessageWindowDismissed
                                                      object:self
                                                    userInfo:nil];
  if (self.clickedButtonId >= 0) {
    [(ABKInAppMessageImmersive *)self.inAppMessage logInAppMessageClickedWithButtonID:self.clickedButtonId];
  } else if (self.inAppMessageIsTapped) {
    [self.inAppMessage logInAppMessageClicked];
  } else if ([ABKUIUtils objectIsValidAndNotEmpty:self.clickedHTMLButtonId]) {
    [(ABKInAppMessageHTMLBase *)self.inAppMessage logInAppMessageHTMLClickWithButtonID:self.clickedHTMLButtonId];
  }
}

#pragma mark - In-app Message and Button Clicks

- (BOOL)delegateHandlesInAppMessageClick {
  if ([self.inAppMessageUIDelegate respondsToSelector:@selector(onInAppMessageClicked:)]) {
    if ([self.inAppMessageUIDelegate onInAppMessageClicked:self.inAppMessage]) {
      NSLog(@"No in-app message click action will be performed by Braze as inAppMessageDelegate %@ returned YES in onInAppMessageClicked:", self.inAppMessageUIDelegate);
      return YES;
    }
  }
  return NO;
}

- (void)inAppMessageClickedWithActionType:(ABKInAppMessageClickActionType)actionType
                                      URL:(NSURL *)url
                         openURLInWebView:(BOOL)openUrlInWebView {
  [self invalidateSlideAwayTimer];
  switch (actionType) {
    case ABKInAppMessageNoneClickAction:
      break;
    case ABKInAppMessageDisplayNewsFeed:
      [self displayModalFeedView];
      break;
    case ABKInAppMessageRedirectToURI:
      if ([ABKUIUtils objectIsValidAndNotEmpty:url]) {
        [self handleInAppMessageURL:url inWebView:openUrlInWebView];
      }
      break;
  }
  [self hideInAppMessageViewWithAnimation:self.inAppMessage.animateOut];
}

#pragma mark - Display News Feed

- (void)displayModalFeedView {
  Class ModalFeedViewControllerClass = [ABKUIUtils getModalFeedViewControllerClass];
  if (ModalFeedViewControllerClass != nil) {
    UIViewController *topmostViewController =
      [ABKUIURLUtils topmostViewControllerWithRootViewController:ABKUIUtils.activeApplicationViewController];
    [topmostViewController presentViewController:[[ModalFeedViewControllerClass alloc] init]
                                                 animated:YES
                                               completion:nil];
  }
}

#pragma mark - URL Handling

- (void)handleInAppMessageURL:(NSURL *)url inWebView:(BOOL)openUrlInWebView {
  // URL Delegate
  if ([ABKUIURLUtils URLDelegate:Appboy.sharedInstance.appboyUrlDelegate
                      handlesURL:url
                     fromChannel:ABKInAppMessageChannel
                      withExtras:self.inAppMessage.extras]) {
    return;
  }

  // WebView
  if ([ABKUIURLUtils URL:url shouldOpenInWebView:openUrlInWebView]) {
    UIViewController *topmostViewController =
    [ABKUIURLUtils topmostViewControllerWithRootViewController:ABKUIUtils.activeApplicationViewController];
    [ABKUIURLUtils displayModalWebViewWithURL:url topmostViewController:topmostViewController];
    return;
  }

  // System
  [ABKUIURLUtils openURLWithSystem:url];
}

#pragma mark - Helpers

/*!
 * Creates and setups the ABKInAppMessageWindow used to display the in-app message
 *
 * @discussion First tries to create the window with the current UIWindowScene if available, then fallbacks
 *             to create the window with a frame.
 */
- (ABKInAppMessageWindow *)createInAppMessageWindow {
  ABKInAppMessageWindow *window;
  
  if (@available(iOS 13.0, *)) {
    UIWindowScene *windowScene = ABKUIUtils.activeWindowScene;
    if (windowScene) {
      window = [[ABKInAppMessageWindow alloc] initWithWindowScene:windowScene];
    }
  }
  
  if (!window) {
    window = [[ABKInAppMessageWindow alloc] initWithFrame:UIScreen.mainScreen.bounds];
  }
  
  window.backgroundColor = UIColor.clearColor;
  window.autoresizingMask = UIViewAutoresizingFlexibleWidth |
                            UIViewAutoresizingFlexibleHeight;
  
  return window;
}

@end
