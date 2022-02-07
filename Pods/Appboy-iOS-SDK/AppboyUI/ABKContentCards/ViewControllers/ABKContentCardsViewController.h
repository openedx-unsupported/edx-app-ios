#import <UIKit/UIKit.h>
#import "ABKContentCardsTableViewController.h"

@interface ABKContentCardsViewController : UINavigationController

/*!
 * This property is the table view controller which displays all the content cards. It's also the root view
 * controller.
 */
@property (strong, nonatomic) ABKContentCardsTableViewController *contentCardsViewController;

@end
