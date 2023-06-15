#import "ABKContentCardsTableViewController.h"
#import "ABKContentCardsWebViewController.h"
#import "ABKContentCardsController.h"

#import "ABKContentCard.h"

#import "ABKBannerContentCardCell.h"
#import "ABKCaptionedImageContentCardCell.h"
#import "ABKClassicContentCardCell.h"
#import "ABKClassicImageContentCardCell.h"
#import "ABKControlTableViewCell.h"

#import "ABKUIUtils.h"
#import "ABKUIURLUtils.h"

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
 *  There is some initialization such as associating which cell class to use in the table view that
 *  is the responsibility of the storyboard if one is provided. If no story board is used then
 *  the code in viewDidLoad will handle it. We can tell based on which init method is used.
 */
@property (nonatomic) BOOL usesStoryboard;

- (void)logCardImpressionIfNeeded:(ABKContentCard *)card;
- (void)requestContentCardsRefresh;
- (void)contentCardsUpdated:(NSNotification *)notification;

@end

@implementation ABKContentCardsTableViewController

#pragma mark - Initialization

- (instancetype)init {
  self = [super init];
  if (self) {
    self.usesStoryboard = NO;
    [self setUp];
    [self setUpUI];
  }

  return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
  self = [super initWithCoder:aDecoder];
  if (self) {
    self.usesStoryboard = YES;
    [self setUp];
  }
  return self;
}

#pragma mark - SetUp

- (void)setUp {
  _cacheTimeout = ABKContentCardsCacheTimeout;
  _cardImpressions = [NSMutableSet set];
  _unviewedOnScreenCards = [NSMutableSet set];
  _enableDarkTheme = YES;
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(contentCardsUpdated:)
                                               name:ABKContentCardsProcessedNotification
                                             object:nil];
}

- (void)setUpUI {
  [self setUpEmptyFeedLabel];
  [self setUpEmptyFeedView];
}

- (void)setUpEmptyFeedLabel {
  self.emptyFeedLabel = [[UILabel alloc] init];
  self.emptyFeedLabel.font = [ABKUIUtils preferredFontForTextStyle:UIFontTextStyleBody weight:UIFontWeightRegular];
  self.emptyFeedLabel.adjustsFontSizeToFitWidth = YES;
  self.emptyFeedLabel.adjustsFontForContentSizeCategory = YES;
  self.emptyFeedLabel.textAlignment = NSTextAlignmentCenter;
  self.emptyFeedLabel.numberOfLines = 0;
  self.emptyFeedLabel.translatesAutoresizingMaskIntoConstraints = NO;
}

- (void)setUpEmptyFeedView {
  self.emptyFeedView = [[UIView alloc] init];
  self.emptyFeedView.backgroundColor = [UIColor clearColor];
  [self.emptyFeedView addSubview:self.emptyFeedLabel];
  self.edgesForExtendedLayout = UIRectEdgeNone;

  NSLayoutConstraint *centerXConstraint = [self.emptyFeedLabel.centerXAnchor constraintEqualToAnchor:self.emptyFeedView.centerXAnchor];
  NSLayoutConstraint *centerYConstraint = [self.emptyFeedLabel.centerYAnchor constraintEqualToAnchor:self.emptyFeedView.centerYAnchor];
  NSLayoutConstraint *leadingConstraint = [self.emptyFeedLabel.leadingAnchor constraintEqualToAnchor:self.emptyFeedView.layoutMarginsGuide.leadingAnchor];
  NSLayoutConstraint *trailingConstraint = [self.emptyFeedLabel.trailingAnchor constraintEqualToAnchor:self.emptyFeedView.layoutMarginsGuide.trailingAnchor];
  NSLayoutConstraint *topConstraint = [self.emptyFeedLabel.topAnchor constraintEqualToAnchor:self.emptyFeedView.layoutMarginsGuide.topAnchor];
  NSLayoutConstraint *bottomConstraint = [self.emptyFeedLabel.bottomAnchor constraintEqualToAnchor:self.emptyFeedView.layoutMarginsGuide.bottomAnchor];
  [NSLayoutConstraint activateConstraints:@[centerXConstraint, centerYConstraint,
                                            leadingConstraint, trailingConstraint,
                                            topConstraint, bottomConstraint]];
}

- (void)dealloc {
  [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)registerTableViewCellClasses {
  [self.tableView registerClass:[ABKCaptionedImageContentCardCell class]
         forCellReuseIdentifier:@"ABKCaptionedImageContentCardCell"];
  [self.tableView registerClass:[ABKBannerContentCardCell class]
         forCellReuseIdentifier:@"ABKBannerContentCardCell"];
  [self.tableView registerClass:[ABKClassicContentCardCell class]
         forCellReuseIdentifier:@"ABKClassicCardCell"];
  [self.tableView registerClass:[ABKControlTableViewCell class]
         forCellReuseIdentifier:@"ABKControlCardCell"];
  [self.tableView registerClass:[ABKClassicImageContentCardCell class]
         forCellReuseIdentifier:@"ABKClassicImageCardCell"];
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

  if (!self.usesStoryboard) {
    self.emptyFeedLabel.text = [self localizedAppboyContentCardsString:@"Appboy.content-cards.no-card.text"];

    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    
    if (@available(iOS 13.0, *)) {
      self.view.backgroundColor = [UIColor systemGroupedBackgroundColor];
    } else {
      self.view.backgroundColor = [UIColor groupTableViewBackgroundColor];
    }

    [self registerTableViewCellClasses];

    UIRefreshControl *refreshControl = [[UIRefreshControl alloc] init];
    [refreshControl addTarget:self action:@selector(refreshContentCards:)
             forControlEvents:UIControlEventValueChanged];
    self.refreshControl = refreshControl;
  }
}

- (void)viewWillAppear:(BOOL)animated {
  [super viewWillAppear:animated];

  [self requestNewCardsIfTimeout];
  [self updateAndDisplayCardsFromCache];

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
    [self hideTableViewAndShowViewInBackground:self.emptyFeedView];
  } else {
    [self showTableViewAndHideBackgroundViews];
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

- (void)hideTableViewAndShowViewInBackground:(UIView *)view {
  view.hidden = NO;
  view.frame = self.view.bounds;
  [view layoutIfNeeded];
  self.tableView.backgroundView = view;
}

- (void)showTableViewAndHideBackgroundViews {
  self.emptyFeedView.hidden = YES;
  self.tableView.backgroundView = nil;
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
  return ABKContentCardsCellEstimatedHeight;
}

- (void)tableView:(UITableView *)tableView
  willDisplayCell:(UITableViewCell *)cell
forRowAtIndexPath:(NSIndexPath *)indexPath {
  ABKContentCard *card = self.cards[indexPath.row];
  BOOL cellVisible = [[tableView indexPathsForVisibleRows] containsObject:indexPath];
  if (cellVisible) {
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
  ABKBaseContentCardCell *cell = [self dequeueCellFromTableView:tableView
                                                   forIndexPath:indexPath
                                                        forCard:card];
  if (self.maxContentCardWidth > 0.0) {
    cell.cardWidthConstraint.constant = self.maxContentCardWidth;
  }

  BOOL viewedSetting = card.viewed;
  if ([self.unviewedOnScreenCards containsObject:card.idString]) {
    card.viewed = NO;
  }
  cell.delegate = self;
  [cell applyCard:card];
  card.viewed = viewedSetting;
  cell.hideUnreadIndicator = self.disableUnreadIndicator;
  return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  ABKContentCard *card = self.cards[indexPath.row];
  [self handleCardClick:card];

  // Remove card from unviewedOnScreenCards
  [self.unviewedOnScreenCards removeObject:card.idString];
  // Hide unviewed indicator
  ABKBaseContentCardCell *cell = [tableView cellForRowAtIndexPath:indexPath];
  cell.unviewedLineView.hidden = YES;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
  ABKContentCard *card = self.cards[indexPath.row];
  return card.dismissible;
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
  return UITableViewCellEditingStyleDelete;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
  if (editingStyle == UITableViewCellEditingStyleDelete) {
    ABKContentCard *card = self.cards[indexPath.row];
    [card logContentCardDismissed];
    [self.cards removeObjectAtIndex:indexPath.row];
    [self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];

    if (self.cards.count == 0) {
      [self hideTableViewAndShowViewInBackground:self.emptyFeedView];
    }
  }
}

#pragma mark - Dequeue cells

- (ABKBaseContentCardCell *)dequeueCellFromTableView:(UITableView *)tableView
                                        forIndexPath:(NSIndexPath *)indexPath
                                             forCard:(ABKContentCard *)card {
  return [tableView dequeueReusableCellWithIdentifier:[self findCellIdentifierWithCard:card]
                                         forIndexPath:indexPath];
}

- (NSString *)findCellIdentifierWithCard:(ABKContentCard *)card {
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

  // Content Cards Delegate handles card click action
  if ([self.delegate respondsToSelector:@selector(contentCardTableViewController:shouldHandleCardClick:)] &&
      ![self.delegate contentCardTableViewController:self shouldHandleCardClick:cardURL]) {
    return;
  }

  // URL Delegate
  if ([ABKUIURLUtils URLDelegate:Appboy.sharedInstance.appboyUrlDelegate
                      handlesURL:cardURL
                     fromChannel:ABKContentCardChannel
                      withExtras:nil]) {
    return;
  }

  // WebView
  if ([ABKUIURLUtils URL:cardURL shouldOpenInWebView:card.openUrlInWebView]) {
    [self openURLInWebView:cardURL];
  } else {
    // System
    [ABKUIURLUtils openURLWithSystem:cardURL];
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

#pragma mark - Utility Methods

+ (instancetype)getNavigationContentCardsViewController {
  return [[ABKContentCardsTableViewController alloc] init];
}

- (NSString *)localizedAppboyContentCardsString:(NSString *)key {
  return [ABKUIUtils getLocalizedString:key
                         inAppboyBundle:[ABKUIUtils bundle:[ABKContentCardsTableViewController class] channel:ABKContentCardChannel]
                                  table:@"AppboyContentCardsLocalizable"];
}

#pragma mark - ABKBaseContentCardCellDelegate

- (void)cellRequestSizeUpdate:(UITableViewCell *)cell {
  NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
  if (indexPath == nil) {
    return;
  }

  [UIView performWithoutAnimation:^{
    [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
  }];
}

@end
