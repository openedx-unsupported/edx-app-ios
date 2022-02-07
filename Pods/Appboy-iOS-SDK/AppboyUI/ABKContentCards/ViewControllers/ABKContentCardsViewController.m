#import "ABKContentCardsViewController.h"
#import "ABKUIUtils.h"

@implementation ABKContentCardsViewController

- (instancetype)init {
  UIStoryboard *st = [UIStoryboard storyboardWithName:@"ABKContentCardsStoryboard"
                                               bundle:[ABKUIUtils bundle:[ABKContentCardsViewController class] channel:ABKContentCardChannel]];
  ABKContentCardsViewController *nf = [st instantiateViewControllerWithIdentifier:@"ABKContentCardsViewController"];
  self = nf;
  self.contentCardsViewController = self.viewControllers[0];
  [self addDoneButton];
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
