#import "ABKNewsFeedViewController.h"
#import "ABKNewsFeedTableViewController.h"
#import "ABKUIUtils.h"

@implementation ABKNewsFeedViewController

- (instancetype)init {
  self = [super init];
  if (self) {
    self.newsFeed = [[ABKNewsFeedTableViewController alloc] init];
    [self pushViewController:self.newsFeed animated:NO];
    [self addDoneButton];
#if !TARGET_OS_TV
    if (@available(iOS 15.0, *)) {
      self.view.backgroundColor = UIColor.systemGroupedBackgroundColor;
    }
#endif
  }
  return self;
}

- (void)awakeFromNib {
  [super awakeFromNib];
  self.newsFeed = self.viewControllers.firstObject;
  [self addDoneButton];
}

- (void)addDoneButton {
  UIBarButtonItem *closeBarButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                                                  target:self
                                                                                  action:@selector(dismissNewsFeed:)];
  [self.newsFeed.navigationItem setRightBarButtonItem:closeBarButton];
}

- (IBAction)dismissNewsFeed:(id)sender {
  [self dismissViewControllerAnimated:YES completion:nil];
}

@end
