#import "ABKInAppMessageWindow.h"
#import "ABKInAppMessageView.h"
#import "ABKInAppMessageWindowController.h"
#import "ABKInAppMessageHTMLBase.h"
#import "ABKUIUtils.h"

@implementation ABKInAppMessageWindow

// Touches handled by ABKInAppMessageWindow:
// - all if `handleAllTouchEvents == YES`
// - in `ABKInAppMessageView` or one of its subviews
// - all if displaying an HTML in-app message
- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {

  // Get the view in the hierarchy that contains the point
  UIView *hitTestResult = [super hitTest:point withEvent:event];

  // Always returns the view for HTML in-app messages
  if ([self.rootViewController isKindOfClass:[ABKInAppMessageWindowController class]]) {
    ABKInAppMessageWindowController *controller = (ABKInAppMessageWindowController *)self.rootViewController;
    if ([controller.inAppMessage isKindOfClass:[ABKInAppMessageHTMLBase class]]) {
      return hitTestResult;
    }
  }

  // Handles the touch event
  if (self.handleAllTouchEvents ||
      [ABKUIUtils responderChainOf:hitTestResult hasKindOfClass:[ABKInAppMessageView class]]) {
    return hitTestResult;
  }

  return nil;
}

@end
