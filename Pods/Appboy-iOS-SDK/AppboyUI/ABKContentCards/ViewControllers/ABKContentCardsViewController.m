#import "ABKContentCardsViewController.h"
#import "ABKUIUtils.h"

@implementation ABKContentCardsViewController

- (instancetype)init {
  self = [super initWithRootViewController:[[ABKContentCardsTableViewController alloc] init]];
  if (self) {
    self.contentCardsViewController = self.viewControllers.firstObject;
    [self addDoneButton];
#if !TARGET_OS_TV
    if (@available(iOS 15.0, *)) {
      self.view.backgroundColor = UIColor.systemGroupedBackgroundColor;
    }
#endif
  }
  return self;
}

- (void)addDoneButton {
  UIBarButtonItem *closeBarButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                                                  target:self
                                                                                  action:@selector(dismissContentCardsViewController:)];
  [self.contentCardsViewController.navigationItem setRightBarButtonItem:closeBarButton];
}

- (IBAction)dismissContentCardsViewController:(id)sender {
  [self dismissViewControllerAnimated:YES completion:nil];
}

@end
