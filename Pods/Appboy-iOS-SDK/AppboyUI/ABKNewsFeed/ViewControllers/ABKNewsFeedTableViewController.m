#import "ABKNewsFeedTableViewController.h"
#import "ABKNFBannerCardCell.h"
#import "ABKNFCaptionedMessageCardCell.h"
#import "ABKNFClassicCardCell.h"
#import "ABKUIUtils.h"
#import "ABKFeedWebViewController.h"
#import "ABKUIURLUtils.h"

@implementation ABKNewsFeedTableViewController

#pragma mark - Initialization

- (instancetype)init {
  self = [super init];
  if (self) {
    [self setUp];
    [self setUpUI];
    [self registerTableViewCellClasses];
  }
  return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
  self = [super initWithCoder:aDecoder];
  if (self) {
    [self setUp];
  }
  return self;
}

#pragma mark - SetUp

- (void)setUp {
  _categories = ABKCardCategoryAll;
  _cacheTimeout = 60.0;
  _cardImpressions = [NSMutableSet set];

  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(feedUpdated:)
                                               name:ABKFeedUpdatedNotification
                                             object:nil];
}

- (void)setUpUI {
#if !TARGET_OS_TV
   if (@available(iOS 15.0, *)) {
     self.view.backgroundColor = UIColor.systemGroupedBackgroundColor;
   }
#endif
  self.emptyFeedView = [[UIView alloc] init];
  self.emptyFeedView.translatesAutoresizingMaskIntoConstraints = NO;
  [self.view addSubview:self.emptyFeedView];
  [self.emptyFeedView.centerYAnchor constraintEqualToAnchor:self.view.centerYAnchor].active = YES;
  [self.emptyFeedView.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor].active = YES;

  self.emptyFeedLabel = [[UILabel alloc] init];
  self.emptyFeedLabel.translatesAutoresizingMaskIntoConstraints = NO;
  self.emptyFeedLabel.text = [self localizedAppboyFeedString:@"Appboy.feed.no-card.text"];
  [self.emptyFeedView addSubview:self.emptyFeedLabel];

  [self.emptyFeedLabel.topAnchor constraintEqualToAnchor:self.emptyFeedView.topAnchor].active = YES;
  [self.emptyFeedLabel.bottomAnchor constraintEqualToAnchor:self.emptyFeedView.bottomAnchor].active = YES;
  [self.emptyFeedLabel.trailingAnchor constraintEqualToAnchor:self.emptyFeedView.trailingAnchor].active = YES;
  [self.emptyFeedLabel.leadingAnchor constraintEqualToAnchor:self.emptyFeedView.leadingAnchor].active = YES;
  
  self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
  self.tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
  self.tableView.backgroundView = nil;
  if (@available(iOS 13.0, *)) {
    self.tableView.backgroundColor = [UIColor systemGroupedBackgroundColor];
  } else {
    self.tableView.backgroundColor = [UIColor groupTableViewBackgroundColor];
  }

  UIRefreshControl *refreshControl = [[UIRefreshControl alloc] init];
  [refreshControl addTarget:self action:@selector(refreshNewsFeed:)
           forControlEvents:UIControlEventValueChanged];
  self.refreshControl = refreshControl;
  self.navigationItem.title = @"News Feed";
}

# pragma mark - View Controller Life Cycle Methods

- (void)viewDidLoad {
  [super viewDidLoad];
  self.cards = [[Appboy sharedInstance].feedController getCardsInCategories:self.categories];

  self.tableView.rowHeight = UITableViewAutomaticDimension;
  self.tableView.estimatedRowHeight = 160;

  [self requestNewCardsIfTimeout];

  self.emptyFeedLabel.text = [self localizedAppboyFeedString:@"Appboy.feed.no-card.text"];
}

- (void)viewWillAppear:(BOOL)animated {
  [super viewWillAppear:animated];
  [self updateAndDisplayCardsFromCache];
}

- (void)viewDidAppear:(BOOL)animated {
  [super viewDidAppear:animated];
  [[Appboy sharedInstance] logFeedDisplayed];
}

- (void)viewWillTransitionToSize:(CGSize)size
       withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
  [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
  [coordinator animateAlongsideTransition:nil completion:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
    [self.tableView reloadData];
  }];
}

- (void)dealloc {
  [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Update And Display Cached Cards

- (IBAction)refreshNewsFeed:(UIRefreshControl *)sender {
  [[Appboy sharedInstance] requestFeedRefresh];
}

- (void)requestNewCardsIfTimeout {
  NSTimeInterval passedTime = fabs([[Appboy sharedInstance].feedController.lastUpdate timeIntervalSinceNow]);
  if (passedTime > self.cacheTimeout) {
    [[Appboy sharedInstance] requestFeedRefresh];
  }
}

- (void)feedUpdated:(NSNotification *)notification {
  BOOL isSuccessful = [notification.userInfo[ABKFeedUpdatedIsSuccessfulKey] boolValue];
  if (isSuccessful) {
    [self updateAndDisplayCardsFromCache];
  }
  [self.refreshControl endRefreshing];
}

- (void)updateAndDisplayCardsFromCache {
  self.cards = [[Appboy sharedInstance].feedController getCardsInCategories:self.categories];
  if (self.cards == nil || self.cards.count == 0) {
    [self hideTableViewAndShowViewInHeader:self.emptyFeedView];
  } else {
    [self showTableViewAndHideHeaderViews];
  }
  [self.tableView reloadData];
}

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

- (void)setCategories:(ABKCardCategory)categories {
  if (categories != _categories) {
    _categories = categories;
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

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
  BOOL cellVisible = [[tableView indexPathsForVisibleRows] containsObject:indexPath];
  if (cellVisible) {
    ABKCard *card = self.cards[indexPath.row];
    [self logCardImpressionIfNeeded:card];
  }
}

- (void)logCardImpressionIfNeeded:(ABKCard *)card {
  if ([self.cardImpressions containsObject:card.idString]) {
    // do nothing if we have already logged an impression
    return;
  }

  [card logCardImpression];
  [self.cardImpressions addObject:card.idString];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  ABKCard *card = self.cards[indexPath.row];
  ABKNFBaseCardCell *cell = [self dequeueCellFromTableView:tableView
                                              forIndexPath:indexPath
                                                   forCard:card];
  [cell applyCard:card];
  cell.delegate = self;
  cell.hideUnreadIndicator = self.disableUnreadIndicator;
  return cell;
}

- (void)registerTableViewCellClasses {
  [self.tableView registerClass:[ABKNFBannerCardCell class]
          forCellReuseIdentifier:@"ABKBannerCardCell"];
  [self.tableView registerClass:[ABKNFCaptionedMessageCardCell class]
          forCellReuseIdentifier:@"ABKNFCaptionedMessageCardCell"];
  [self.tableView registerClass:[ABKNFClassicCardCell class]
          forCellReuseIdentifier:@"ABKNFNewsCardCell"];
}

- (ABKNFBaseCardCell *)dequeueCellFromTableView:(UITableView *)tableView
                                   forIndexPath:(NSIndexPath *)indexPath
                                        forCard:(ABKCard *)card {
  NSString *cellIdentifier = [self findCellIdentifierWithCard:card];
  return [tableView dequeueReusableCellWithIdentifier:cellIdentifier
                                         forIndexPath:indexPath];
}

- (NSString *)findCellIdentifierWithCard:(ABKCard *)card {
  if ([card isKindOfClass:[ABKBannerCard class]]) {
    return @"ABKBannerCardCell";
  } else if ([card isKindOfClass:[ABKCaptionedImageCard class]]) {
    return @"ABKNFCaptionedMessageCardCell";
  } else if ([card isKindOfClass:[ABKClassicCard class]]) {
    return @"ABKNFNewsCardCell";
  } else if ([card isKindOfClass:[ABKTextAnnouncementCard class]]) {
    return @"ABKNFCaptionedMessageCardCell";
  }
  return nil;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  ABKCard *card = self.cards[indexPath.row];
  [self handleCardClick:card];
}

#pragma mark - Card Click Actions

- (void)handleCardClick:(ABKCard *)card {
  [card logCardClicked];

  NSURL *cardURL = [ABKUIURLUtils getEncodedURIFromString:card.urlString];

  // URL Delegate
  if ([ABKUIURLUtils URLDelegate:Appboy.sharedInstance.appboyUrlDelegate
                      handlesURL:cardURL
                     fromChannel:ABKNewsFeedChannel
                      withExtras:nil]) {
    return;
  }

  // WebView
  if ([ABKUIURLUtils URL:cardURL shouldOpenInWebView:card.openUrlInWebView]) {
    [self openURLInWebView:cardURL];
    return;
  }

  // System
  [ABKUIURLUtils openURLWithSystem:cardURL];
}

- (void)openURLInWebView:(NSURL *)url {
  ABKFeedWebViewController *webViewController = [[ABKFeedWebViewController alloc] init];
  webViewController.url = url;
  webViewController.showDoneButton = self.navigationItem.rightBarButtonItem != nil;
  [self.navigationController pushViewController:webViewController animated:YES];
}

# pragma mark - Utility Methods

+ (instancetype)getNavigationFeedViewController {
  return [[ABKNewsFeedTableViewController alloc] init];
}

- (NSString *)localizedAppboyFeedString:(NSString *)key {
  return [ABKUIUtils getLocalizedString:key
                         inAppboyBundle:[ABKUIUtils bundle:[ABKNewsFeedTableViewController class] channel:ABKNewsFeedChannel]
                                  table:@"AppboyFeedLocalizable"];
}

# pragma mark - ABKBaseNewsFeedCellDelegate

- (void)refreshTableViewCellHeights {
  [UIView performWithoutAnimation:^{
    [self.tableView beginUpdates];
    [self.tableView endUpdates];
  }];
}

@end
