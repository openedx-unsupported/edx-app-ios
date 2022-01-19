#import <UIKit/UIKit.h>
#import "ABKNewsFeedTableViewController.h"

@interface ABKNewsFeedViewController : UINavigationController

/*!
 * This property is the table view controller which displays all the cards. It's also the root view
 * controller.
 */
@property (nonatomic) ABKNewsFeedTableViewController *newsFeed;

@end
