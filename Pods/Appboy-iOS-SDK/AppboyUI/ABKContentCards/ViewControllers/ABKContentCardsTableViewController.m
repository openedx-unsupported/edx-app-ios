#import "ABKContentCardsTableViewController.h"
#import "ABKContentCardsWebViewController.h"
#import "ABKContentCardsController.h"

#import "ABKContentCard.h"

#import "ABKBannerContentCardCell.h"
#import "ABKCaptionedImageContentCardCell.h"
#import "ABKClassicContentCardCell.h"

#import "ABKUIUtils.h"
#import "ABKUIURLUtils.h"
#import <SDWebImage/SDWebImagePrefetcher.h>

static double const ABKContentCardsCacheTimeout = 1 * 60; // 1 minute
static CGFloat const ABKContentCardsCellEstimatedHeight = 400.0f;

@interface ABKContentCardsTableViewController () <ABKBaseContentCardCellDelegate>

/*!
 * This set stores the content cards IDs for which the impressions have been logged.
 */
@property (nonatomic) NSMutableSet<NSString *> *cardImpressions;

/*!
 * This set stores IDs for the content cards that are unviewed and on the screen right now.
 */
@property (nonatomic) NSMutableSet<NSString *> *unviewedOnScreenCards;

/*!
 * Stores the cell heights to provide for a smooth scrolling experience when cells need
 * to resize themselves as you scroll through the ViewController
 */
@property (nonatomic) NSMutableDictionary<NSIndexPath *, NSNumber *> *cellHeights;

- (void)logCardImpressionIfNeeded:(ABKContentCard *)card;
- (void)requestContentCardsRefresh;
- (void)contentCardsUpdated:(NSNotification *)notification;

+ (NSString *)findCellIdentifierWithCard:(ABKContentCard *)card;

- (void)cacheAllCardImages;
- (void)cancelCachingCardImages;

@end

@implementation ABKContentCardsTableViewController

#pragma mark - Initialization

- (instancetype)init {
  UIStoryboard *st = [UIStoryboard storyboardWithName:@"ABKContentCardsStoryboard"
                                               bundle:[ABKUIUtils bundle:[ABKContentCardsTableViewController class] channel:ABKContentCardChannel]];
  ABKContentCardsTableViewController *vc = [st instantiateViewControllerWithIdentifier:@"ABKContentCardsTableViewController"];
  self = vc;
  return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
  self = [super initWithCoder:aDecoder];
  if (self) {
    [self setUp];
  }
  return self;
}

- (void)setUp {
  _cacheTimeout = ABKContentCardsCacheTimeout;
  _cardImpressions = [NSMutableSet set];
  _unviewedOnScreenCards = [NSMutableSet set];
  _cellHeights = [NSMutableDictionary dictionary];
  _enableDarkTheme = YES;
  
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(contentCardsUpdated:)
                                               name:ABKContentCardsProcessedNotification
                                             object:nil];
}

- (void)dealloc {
  [[NSNotificationCenter defaultCenter] removeObserver:self];
}

# pragma mark - View Controller Life Cycle Methods

- (void)viewDidLoad {
  [super viewDidLoad];
  if (@available(iOS 13.0, *)) {
    if (self.enableDarkTheme) {
      // This value will respect the system UI style of dark or light mode
      self.overrideUserInterfaceStyle = UIUserInterfaceStyleUnspecified;
    } else {
      self.overrideUserInterfaceStyle = UIUserInterfaceStyleLight;
    }
  }
  self.emptyFeedLabel.text = [self localizedAppboyContentCardsString:@"Appboy.content-cards.no-card.text"];
}

- (void)viewWillAppear:(BOOL)animated {
  [super viewWillAppear:animated];
  
  [self requestNewCardsIfTimeout];
  [self updateAndDisplayCardsFromCache];
  [self cacheAllCardImages];
  
  dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.01 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
    [self.tableView reloadData];
  });
}

- (void)viewDidAppear:(BOOL)animated {
  [super viewDidAppear:animated];
  [[Appboy sharedInstance] logContentCardsDisplayed];
}

- (void)viewWillDisappear:(BOOL)animated {
  [super viewWillDisappear:animated];
  
  [self cancelCachingCardImages];
}

- (void)viewWillTransitionToSize:(CGSize)size
       withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
  [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
  [coordinator animateAlongsideTransition:nil completion:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
    [self.tableView reloadData];
  }];
}

#pragma mark - Update And Display Cached Cards

- (void)populateContentCards {
  self.cards = [NSMutableArray arrayWithArray:[Appboy.sharedInstance.contentCardsController getContentCards]];
}

- (void)requestContentCardsRefresh {
  [Appboy.sharedInstance requestContentCardsRefresh];
}

- (IBAction)refreshContentCards:(UIRefreshControl *)sender {
  // Remove visible cards from unviewedOnScreenCards
  NSArray *visibleIndexPaths = [self.tableView indexPathsForVisibleRows];
  for (NSIndexPath *indexPath in visibleIndexPaths) {
    ABKContentCard *card = self.cards[indexPath.row];
    [self.unviewedOnScreenCards removeObject:card.idString];
  }
  
  [self requestContentCardsRefresh];
}

- (void)requestNewCardsIfTimeout {
  NSTimeInterval passedTime = fabs(Appboy.sharedInstance.contentCardsController.lastUpdate.timeIntervalSinceNow);
  if (passedTime > self.cacheTimeout) {
    [self requestContentCardsRefresh];
  } else {
    // timeout is not passed, so we don't send a request for new content cards
    [self.refreshControl endRefreshing];
  }
}

- (void)contentCardsUpdated:(NSNotification *)notification {
  BOOL isSuccessful = [notification.userInfo[ABKContentCardsProcessedIsSuccessfulKey] boolValue];
  if (isSuccessful) {
    [self updateAndDisplayCardsFromCache];
  }
  [self.refreshControl endRefreshing];
}

- (void)updateAndDisplayCardsFromCache {
  [self populateContentCards];
  if (self.cards == nil || self.cards.count == 0) {
    [self hideTableViewAndShowViewInHeader:self.emptyFeedView];
  } else {
    [self showTableViewAndHideHeaderViews];
  }
  [self.tableView reloadData];
}

- (void)logCardImpressionIfNeeded:(ABKContentCard *)card {
  if ([self.cardImpressions containsObject:card.idString]) {
    // do nothing if we have already logged an impression
    return;
  }
  
  if (![card isControlCard]) {
    if (card.viewed == NO) {
      [self.unviewedOnScreenCards addObject:card.idString];
    }
  }
  [card logContentCardImpression];
  [self.cardImpressions addObject:card.idString];
}

#pragma mark - Table view header view

- (void)hideTableViewAndShowViewInHeader:(UIView *)view {
  view.hidden = NO;
  view.frame = self.view.bounds;
  [view layoutIfNeeded];
  self.tableView.sectionHeaderHeight = self.tableView.frame.size.height;
  self.tableView.tableHeaderView = view;
  self.tableView.scrollEnabled = NO;
}

- (void)showTableViewAndHideHeaderViews {
  self.emptyFeedView.hidden = YES;
  self.tableView.tableHeaderView = nil;
  self.tableView.sectionHeaderHeight = 0;
  self.tableView.scrollEnabled = YES;
}

#pragma mark - Configuration Update

- (void)setDisableUnreadIndicator:(BOOL)disableUnreadIndicator {
  if (disableUnreadIndicator != _disableUnreadIndicator) {
    _disableUnreadIndicator = disableUnreadIndicator;
    [self updateAndDisplayCardsFromCache];
  }
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.cards.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
  if ([self.cards[indexPath.row] isControlCard]) {
    return 0;
  }
   return UITableViewAutomaticDimension;
}

// Overrides the storyboard to get accurate cell height estimates to prevent from having
// the scrollView jump if a cell needs to resize itself
- (CGFloat)tableView:(UITableView *)tableView
estimatedHeightForRowAtIndexPath:(nonnull NSIndexPath *)indexPath {
  NSNumber *height = self.cellHeights[indexPath];
  if (height) {
    return [height floatValue];
  }
  return ABKContentCardsCellEstimatedHeight;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
  if (self.maxContentCardWidth > 0.0 && [cell isKindOfClass:[ABKBaseContentCardCell class]]) {
    ABKBaseContentCardCell *contentCardCell = (ABKBaseContentCardCell*)cell;
    contentCardCell.cardWidthConstraint.constant = self.maxContentCardWidth;
  }
  self.cellHeights[indexPath] = @(cell.frame.size.height);
  BOOL cellVisible = [[tableView indexPathsForVisibleRows] containsObject:indexPath];
  if (cellVisible) {
    ABKContentCard *card = self.cards[indexPath.row];
    [self logCardImpressionIfNeeded:card];
  }
}

- (void)tableView:(UITableView *)tableView
    didEndDisplayingCell:(UITableViewCell *)cell
       forRowAtIndexPath:(NSIndexPath *)indexPath {
  // We mark a cell as read only if it's not visible already.
  // But this method might be called for visible cells too because of dynamic heights.
  BOOL cellIsVisible = [[tableView indexPathsForVisibleRows] containsObject:indexPath];
  if (!cellIsVisible && indexPath.row < self.cards.count) {
    // indexPath.row is out of bounds if the card did end displaying due to its deletion
    
    ABKContentCard *card = self.cards[indexPath.row];
    [self.unviewedOnScreenCards removeObject:card.idString];
  }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  ABKContentCard *card = self.cards[indexPath.row];
  ABKBaseContentCardCell *cell = [ABKContentCardsTableViewController dequeueCellFromTableView:tableView
                                                                                 forIndexPath:indexPath
                                                                                      forCard:card];
  BOOL viewedSetting = card.viewed;
  if ([self.unviewedOnScreenCards containsObject:card.idString]) {
    card.viewed = NO;
  }
  cell.delegate = self;
  [cell applyCard:card];
  card.viewed = viewedSetting;
  cell.hideUnreadIndicator = self.disableUnreadIndicator;
  [cell layoutIfNeeded];
  return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  ABKContentCard *card = self.cards[indexPath.row];
  [self handleCardClick:card];
  
  // Remove card from unviewedOnScreenCards
  [self.unviewedOnScreenCards removeObject:card.idString];
  [tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
  ABKContentCard *card = self.cards[indexPath.row];
  return card.dismissible;
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
  return UITableViewCellEditingStyleDelete;
}

- (void)tableView:(UITableView *)tableView
    commitEditingStyle:(UITableViewCellEditingStyle)editingStyle
     forRowAtIndexPath:(NSIndexPath *)indexPath {
  if (editingStyle == UITableViewCellEditingStyleDelete) {
    ABKContentCard *card = self.cards[indexPath.row];
    [card logContentCardDismissed];
    [self.cards removeObjectAtIndex:indexPath.row];
    [self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
  }
}

#pragma mark - Dequeue cells

+ (ABKBaseContentCardCell *)dequeueCellFromTableView:(UITableView *)tableView
                                   forIndexPath:(NSIndexPath *)indexPath
                                        forCard:(ABKContentCard *)card {
  return [tableView dequeueReusableCellWithIdentifier:[self findCellIdentifierWithCard:card]
                                         forIndexPath:indexPath];
}

+ (NSString *)findCellIdentifierWithCard:(ABKContentCard *)card {
  if ([card isControlCard]) {
    return @"ABKControlCardCell";
  }
  if ([card isKindOfClass:[ABKBannerContentCard class]]) {
    return @"ABKBannerContentCardCell";
  } else if ([card isKindOfClass:[ABKCaptionedImageContentCard class]]) {
    return @"ABKCaptionedImageContentCardCell";
  } else if ([card isKindOfClass:[ABKClassicContentCard class]]) {
    NSString *imageURL = [((ABKClassicContentCard *)card) image];
    if (imageURL.length > 0) {
      return @"ABKClassicImageCardCell";
    } else {
      return @"ABKClassicCardCell";
    }
  }
  return nil;
}

#pragma mark - Card Click Actions

- (void)handleCardClick:(ABKContentCard *)card {
  // Log a card click only when the card has the url property with a valid url.
  if (card.urlString.length <= 0) {
    return;
  }
  
  [card logContentCardClicked];
  NSURL *cardURL = [ABKUIURLUtils getEncodedURIFromString:card.urlString];
  
  // Delegate handles card click action
  if ([self.delegate respondsToSelector:@selector(contentCardTableViewController:shouldHandleCardClick:)] &&
      ![self.delegate contentCardTableViewController:self shouldHandleCardClick:cardURL]) {
    return;
  }
  
  // Handles card click action
  if ([ABKUIURLUtils URL:cardURL shouldOpenInWebView:card.openUrlInWebView]) {
    [self openURLInWebView:cardURL];
  } else {
    [ABKUIURLUtils openURLWithSystem:cardURL fromChannel:ABKContentCardChannel];
  }
  
  // Delegate inform card click action
  if ([self.delegate respondsToSelector:@selector(contentCardTableViewController:didHandleCardClick:)]) {
    [self.delegate contentCardTableViewController:self didHandleCardClick:cardURL];
  }
}

- (void)openURLInWebView:(NSURL *)url {
  ABKContentCardsWebViewController *webVC = [ABKContentCardsWebViewController new];
  webVC.url = url;
  webVC.showDoneButton = (self.navigationItem.rightBarButtonItem != nil);
  [self.navigationController pushViewController:webVC animated:YES];
}

#pragma mark - Image Caching

- (void)cacheAllCardImages {
  NSMutableArray *images = [NSMutableArray arrayWithCapacity:self.cards.count];
  for (ABKCard *card in self.cards) {
    if ([card respondsToSelector:@selector(image)]) {
      NSString *imageUrlString = [[card performSelector:@selector(image)] copy];
      NSURL *imageUrl = [ABKUIURLUtils getEncodedURIFromString:imageUrlString];
      if ([ABKUIUtils objectIsValidAndNotEmpty:imageUrl]) {
        [images addObject:imageUrl];
      }
    }
  }
  [[SDWebImagePrefetcher sharedImagePrefetcher] prefetchURLs:images];
}

- (void)cancelCachingCardImages {
  [[SDWebImagePrefetcher sharedImagePrefetcher] cancelPrefetching];
}

#pragma mark - Utility Methods

+ (instancetype)getNavigationContentCardsViewController {
  UIStoryboard *st = [UIStoryboard storyboardWithName:@"ABKContentCardsStoryboard"
                                               bundle:[ABKUIUtils bundle:[ABKContentCardsTableViewController class] channel:ABKContentCardChannel]];
  ABKContentCardsTableViewController *vc = [st instantiateViewControllerWithIdentifier:@"ABKContentCardsTableViewController"];
  return vc;
}

- (NSString *)localizedAppboyContentCardsString:(NSString *)key {
  return [ABKUIUtils getLocalizedString:key
                         inAppboyBundle:[ABKUIUtils bundle:[ABKContentCardsTableViewController class] channel:ABKContentCardChannel]
                                  table:@"AppboyContentCardsLocalizable"];
}

#pragma mark - ABKBaseContentCardCellDelegate

- (void)refreshTableViewCellHeights {
  [UIView performWithoutAnimation:^{
    [self.tableView beginUpdates];
    [self.tableView endUpdates];
  }];
}

@end
