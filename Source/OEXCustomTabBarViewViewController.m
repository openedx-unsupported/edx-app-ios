//
//  OEXCustomTabBarViewViewController.m
//  edXVideoLocker
//
//  Created by Nirbhay Agarwal on 16/05/14.
//  Copyright (c) 2014 edX. All rights reserved.
//

#import "OEXCustomTabBarViewViewController.h"

#import "NSArray+OEXSafeAccess.h"
#import "NSString+OEXFormatting.h"

#import "OEXAnalytics.h"
#import "OEXAppDelegate.h"
#import "OEXAnnouncement.h"
#import "OEXAuthentication.h"
#import "OEXCourse.h"
#import "OEXCourseDetailTableViewCell.h"
#import "OEXCourseInfoCell.h"
#import "OEXCourseVideoDownloadTableViewController.h"
#import "OEXDataParser.h"
#import "OEXInterface.h"
#import "OEXFlowErrorViewController.h"
#import "OEXGenericCourseTableViewController.h"
#import "OEXHelperVideoDownload.h"
#import "OEXLastAccessedTableViewCell.h"
#import "OEXOpenInBrowserViewController.h"
#import "OEXStatusMessageViewController.h"
#import "OEXTabBarItemsCell.h"
#import "OEXUserDetails.h"
#import "OEXVideoPathEntry.h"
#import "OEXVideoSummary.h"
#import "Reachability.h"
#import "SWRevealViewController.h"
#import "OEXCourseInfoTabViewController.h"
#import "OEXHandoutsViewController.h"
#import "OEXDateFormatting.h"
#import "OEXRouter.h"

@implementation OEXCustomTabBarViewViewControllerEnvironment

- (id)initWithAnalytics:(OEXAnalytics *)analytics
                 config:(OEXConfig *)config
    pushSettingsManager:(OEXPushSettingsManager *)pushSettingsManager
                 styles:(OEXStyles *)styles {
    self = [super init];
    if(self != nil) {
        _analytics = analytics;
        _config = config;
        _pushSettingsManager = pushSettingsManager;
        _styles = styles;
    }
    return self;
}

@end

@interface OEXCustomTabBarViewViewController () <UITableViewDelegate, UITableViewDataSource, OEXCourseInfoTabViewControllerDelegate, OEXStatusMessageControlling, UICollectionViewDataSource, UICollectionViewDelegate, NSURLConnectionDelegate, NSURLConnectionDataDelegate, UITextViewDelegate>
{
    NSMutableData* receivedData;
    NSURLConnection* connection;
}

@property (strong, nonatomic) IBOutlet UIView* containerView;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint* containerHeightConstraint;
@property (strong, nonatomic) IBOutlet UIActivityIndicatorView* activityIndicator;
@property (strong, nonatomic) IBOutlet UILabel* lbl_NoCourseware;
@property (strong, nonatomic) IBOutlet UIButton* btn_Downloads;
@property (strong, nonatomic) IBOutlet DACircularProgressView* customProgressBar;
@property (strong, nonatomic) IBOutlet UIView* tabView;
@property (strong, nonatomic) IBOutlet UITableView* table_Courses;
@property (strong, nonatomic) IBOutlet UICollectionView* collectionView;
@property (strong, nonatomic) IBOutlet OEXCustomNavigationView* customNavView;
@property (nonatomic, assign) BOOL didReloadAnnouncement;
@property (nonatomic, strong)  NSArray* announcements;
@property (nonatomic, strong)  NSDictionary* dict_CourseInfo;
@property (nonatomic, strong)  OEXHelperVideoDownload* lastAccessedVideo;
@property (nonatomic, strong) NSString* OpenInBrowser_URL;
@property (nonatomic, strong) OEXDataParser* dataParser;
@property (nonatomic, weak) OEXInterface* dataInterface;
// get open in browser URL
@property (nonatomic, strong) OEXOpenInBrowserViewController* browser;
@property (nonatomic, strong) NSArray* chapterPathEntries;      // OEXVideoPathEntry array
@property (nonatomic, strong) NSSet* offlineAvailableChapterIDs;
@property(nonatomic, strong) NSString* html_Handouts;
@property (nonatomic, strong) OEXCourseInfoTabViewController* courseInfoTabBarController;
@property(nonatomic, assign) BOOL loadingCourseware;

@property (assign, nonatomic) OEXCourseTab selectedTab;

@end

@implementation OEXCustomTabBarViewViewController

- (CGFloat)verticalOffsetForStatusController:(OEXStatusMessageViewController*)controller {
    return CGRectGetMaxY(self.tabView.frame);
}

- (NSArray*)overlayViewsForStatusController:(OEXStatusMessageViewController*)controller {
    NSMutableArray* result = [[NSMutableArray alloc] init];
    [result oex_safeAddObjectOrNil:self.customNavView];
    [result oex_safeAddObjectOrNil:self.tabView];
    [result oex_safeAddObjectOrNil:self.self.customProgressBar];
    [result oex_safeAddObjectOrNil:self.btn_Downloads];
    return result;
}

#pragma mark - get Course outline from connection

- (void)getCourseOutlineData {
    if(self.dataInterface.reachable) {
        NSURL* url = [NSURL URLWithString:self.course.video_outline];
        NSMutableURLRequest* urlRequest = [NSMutableURLRequest requestWithURL:url];
        [urlRequest setTimeoutInterval:75.0f];
        [urlRequest setHTTPMethod:@"GET"];
        NSString* authValue = [NSString stringWithFormat:@"%@", [OEXAuthentication authHeaderForApiAccess]];
        [urlRequest setValue:authValue forHTTPHeaderField:@"Authorization"];
        [urlRequest setValue:@"application/json; charset=utf-8" forHTTPHeaderField:@"Content-Type"];
        connection = [[NSURLConnection alloc] initWithRequest:urlRequest delegate:self];
        [connection start];
        if(connection) {
            receivedData = [NSMutableData data];
        }
        self.activityIndicator.hidden = NO;
        self.loadingCourseware = YES;
        self.lbl_NoCourseware.hidden = YES;
    }
    else {
        self.loadingCourseware = YES;
        self.lbl_NoCourseware.hidden = NO;
    }
}

- (NSAttributedString*)msgFutureCourses {
    NSString* strStartDate = [OEXDateFormatting formatAsMonthDayYearString:self.course.start];
    NSString* localizedString = OEXLocalizedString(@"COURSE_WILL_START_AT", nil);
    NSString* lblCourseMsg = [NSString oex_stringWithFormat:localizedString parameters:@{@"date" : strStartDate}];
    NSMutableAttributedString* msgFutureCourses = [[NSMutableAttributedString alloc] initWithString:lblCourseMsg];
    NSRange range = [lblCourseMsg rangeOfString:strStartDate];
    [msgFutureCourses setAttributes:@{NSFontAttributeName:[UIFont fontWithName:@"OpenSans-Semibold" size:self.lbl_NoCourseware.font.pointSize], NSForegroundColorAttributeName:[UIColor blackColor]} range:range];
    return msgFutureCourses;
}

#pragma mark -
#pragma mark - NSURLConnection Delegtates
- (void)connection:(NSURLConnection*)connection didReceiveData:(NSData*)data {
    if(!receivedData) {
        // no store yet, make one
        receivedData = [[NSMutableData alloc] initWithData:data];
    }
    else {
        // append to previous chunks
        [receivedData appendData:data];
    }
}

- (void)connectionDidFinishLoading:(NSURLConnection*)connection {
    NSString* response = [[NSString alloc] initWithData:receivedData encoding:NSUTF8StringEncoding];
    //	ELog(@"============================================================\n");
    //  ELog(@"RESPONSE : %@", response);
    self.loadingCourseware = NO;
    if([response hasPrefix:@"<html>"]) {
        self.activityIndicator.hidden = YES;
        self.table_Courses.hidden = YES;
        self.lbl_NoCourseware.hidden = NO;
    }
    else {
        if(self.course.video_outline) {
            [self updateCourseWareData];
        }
    }
}

- (void)updateCourseWareData {
    [self.dataInterface processVideoSummaryList:receivedData URLString:self.course.video_outline];
    NSString* courseVideoDetails = self.course.video_outline;
    NSArray* array = [self.dataInterface videosOfCourseWithURLString:courseVideoDetails];
    [_dataInterface storeVideoList:array forURL:courseVideoDetails];
    [self refreshCourseData];
}

// and error occured
- (void)connection:(NSURLConnection*)connection didFailWithError:(NSError*)error {
    [self updateCourseWareData];
}

#pragma mark - Offline mode

- (void)dealloc {
    connection = nil;
    _collectionView = nil;
    self.view = nil;
}

- (void)populateOfflineCheckData {
    NSMutableArray* completedVideoInfos = [[NSMutableArray alloc] initWithArray: [_dataInterface coursesAndVideosForDownloadState:OEXDownloadStateComplete]];
    NSMutableArray* downloadedVideos = [[NSMutableArray alloc] init];
    for(NSDictionary* videoInfo in completedVideoInfos) {
        for(OEXHelperVideoDownload* video in [videoInfo objectForKey : CAV_KEY_VIDEOS]) {
            [downloadedVideos addObject:video];
        }
    }
    NSMutableSet* offlineAvailableChapterIDs = [[NSMutableSet alloc] init];
    for(OEXHelperVideoDownload* objVideos in downloadedVideos) {
        [offlineAvailableChapterIDs addObject:objVideos.summary.chapterPathEntry.entryID];
    }
    self.offlineAvailableChapterIDs = offlineAvailableChapterIDs;
    [self reloadTableOnMainThread];
}

#pragma mark - REACHABILITY

- (void)HideOfflineLabel:(BOOL)isOnline {
    [self showBrowserView:isOnline];
    self.customNavView.lbl_Offline.hidden = isOnline;
    self.customNavView.view_Offline.hidden = isOnline;
    [self.customNavView adjustPositionIfOnline:isOnline];
}

- (void)reachabilityDidChange:(NSNotification*)notification {
    Reachability* reachability = (Reachability*)[notification object];
    if([reachability isReachable]) {
        _dataInterface.reachable = YES;
        [self HideOfflineLabel:YES];
        [self reloadTableOnMainThread];
    }
    else {
        _dataInterface.reachable = NO;
        [self HideOfflineLabel:NO];
        // get the data for offline mode
        [self populateOfflineCheckData];
    }
}

#pragma mark - Life Cycle
- (id)initWithNibName:(NSString*)nibNameOrNil bundle:(NSBundle*)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if(self) {
        // Custom initialization
    }
    return self;
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self removeObserver];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self addObserver];
    self.lastAccessedVideo = [self.dataInterface lastAccessedSubsectionForCourseID:self.course.course_id];
    [[OEXOpenInBrowserViewController sharedInstance] addViewToContainerSuperview:self.containerView];
    // Check Reachability for OFFLINE
    if(_dataInterface.reachable) {
        [self HideOfflineLabel:YES];
    }
    else {
        [self HideOfflineLabel:NO];
        //MOB-832 Issue solved
        [self refreshCourseData];
        // get the data for offline mode
        [self populateOfflineCheckData];
    }
    self.navigationController.navigationBarHidden = YES;
    [self reloadTableOnMainThread];
    // To get updated from the server.
    dispatch_async(dispatch_get_main_queue(), ^{
        [_dataInterface getLastVisitedModuleForCourseID:self.course.course_id];
    });
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // set Back button name to blank.
    if(!self.course.isStartDateOld && self.course.start) {
        self.lbl_NoCourseware.attributedText = [self msgFutureCourses];
    }
    else {
        self.lbl_NoCourseware.text = OEXLocalizedString(@"COURSEWARE_UNAVAILABLE", nil);
    }

    [self setNavigationBar];
    // hide COURSEWARE, announcement,handouts and courseinfo
    self.table_Courses.hidden = YES;
    self.activityIndicator.hidden = YES;
    self.lbl_NoCourseware.hidden = YES;
    self.loadingCourseware = NO;
    [self setExclusiveTouches];

    OEXCourseInfoTabViewControllerEnvironment* courseEnvironment = [[OEXCourseInfoTabViewControllerEnvironment alloc]
                                                                    initWithConfig:self.environment.config
                                                                    pushSettingsManager:self.environment.pushSettingsManager
                                                                    styles:self.environment.styles];
    self.courseInfoTabBarController = [[OEXCourseInfoTabViewController alloc] initWithCourse:self.course environment:courseEnvironment];
    self.courseInfoTabBarController.delegate = self;
    self.courseInfoTabBarController.view.frame = CGRectMake(0, 108, self.view.frame.size.width, self.view.frame.size.height - 108);
    [self.view addSubview:self.courseInfoTabBarController.view];
    [self addChildViewController:self.courseInfoTabBarController];
    self.courseInfoTabBarController.view.hidden = YES;

    self.dataParser = [[OEXDataParser alloc] init];
    // Initialize the interface for API calling
    self.dataInterface = [OEXInterface sharedInterface];
    self.announcements = nil;
    // set open in browser link
    _browser = [OEXOpenInBrowserViewController sharedInstance];
    _browser.str_browserURL = [self.dataInterface openInBrowserLinkForCourse:self.course];
    [self addObserver];
    [[self.dataInterface progressViews] addObject:self.customProgressBar];
    [[self.dataInterface progressViews] addObject:self.btn_Downloads];
    [self.customProgressBar setHidden:YES];
    [self.btn_Downloads setHidden:YES];

    NSData* data = [_dataInterface resourceDataForURLString:self.course.video_outline downloadIfNotAvailable:NO];
    if(data) {
        [self.dataInterface processVideoSummaryList:data URLString:self.course.video_outline];
        self.activityIndicator.hidden = YES;
        [self refreshCourseData];
    }
    else {if(self.course.isStartDateOld) {
              self.activityIndicator.hidden = NO;
              self.lbl_NoCourseware.hidden = YES;
          }
          [_dataInterface downloadWithRequestString:self.course.video_outline forceUpdate:NO];
          [self getCourseOutlineData]; }

    [self performSelector:@selector(initMoreData) withObject:nil afterDelay:0.5];
#ifdef __IPHONE_8_0
    if(IS_IOS8) {
        [self.table_Courses setLayoutMargins:UIEdgeInsetsZero];
    }
#endif
}

- (void)setExclusiveTouches {
    self.collectionView.exclusiveTouch = YES;
    self.table_Courses.exclusiveTouch = YES;
    self.courseInfoTabBarController.view.exclusiveTouch = YES;
    self.customNavView.btn_Back.exclusiveTouch = YES;
    self.view.exclusiveTouch = YES;
}

- (void)navigateBack {
    [self removeObserver];
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark Internal Methods
- (void)refreshCourseData {
    //Get the data from the parsed global array
    self.chapterPathEntries = [[NSArray alloc] initWithArray: [self.dataInterface chaptersForURLString:self.course.video_outline]];
    if(self.selectedTab == 0 && self.chapterPathEntries.count > 0) {
        self.table_Courses.hidden = NO;
        self.courseInfoTabBarController.view.hidden = YES;
        self.lbl_NoCourseware.hidden = YES;
        self.activityIndicator.hidden = YES;
    }
    else {
        self.table_Courses.hidden = YES;
        self.lbl_NoCourseware.hidden = self.loadingCourseware;
        self.activityIndicator.hidden = !self.loadingCourseware;
    }
    _browser.str_browserURL = [self.dataInterface openInBrowserLinkForCourse:self.course];
    [self showBrowserView:NO];
    [self reloadTableOnMainThread];
}

- (void)showBrowserView:(BOOL)isShown {
    __weak OEXCustomTabBarViewViewController* weakself = self;

    if(!_table_Courses.hidden &&
       _dataInterface.reachable &&
       [_browser.str_browserURL length] > 0) {
        weakself.containerHeightConstraint.constant = OPEN_IN_BROWSER_HEIGHT;
        [weakself.containerView layoutIfNeeded];
        weakself.containerView.hidden = NO;
    }
    else {
        weakself.containerHeightConstraint.constant = 0;
        [weakself.containerView layoutIfNeeded];
        weakself.containerView.hidden = YES;
    }
}

- (void)initMoreData {
    self.html_Handouts = [[NSString alloc] init];
    /// Load Arr anouncement data
    self.announcements = nil;
    if(self.selectedTab != OEXCourseTabCourseware) {
        self.lbl_NoCourseware.hidden = YES;
    }
    NSData* data = [self.dataInterface resourceDataForURLString:self.course.course_updates downloadIfNotAvailable:NO];
    if(data) {
        self.announcements = [self.dataParser announcementsWithData:data];
        if(self.selectedTab == OEXCourseTabCourseInfo) {
            self.lbl_NoCourseware.hidden = YES;
            self.courseInfoTabBarController.view.hidden = NO;
            [self.courseInfoTabBarController scrollToTop];
        }
    }
    else {
        [_dataInterface downloadWithRequestString:self.course.course_updates forceUpdate:YES];
    }

    // Get Handouts data
    NSData* handoutData = [self.dataInterface resourceDataForURLString:self.course.course_handouts downloadIfNotAvailable:NO];
    if(handoutData) {
        self.html_Handouts = [self.dataParser handoutsWithData:handoutData];
    }
    else {
        [_dataInterface downloadWithRequestString:self.course.course_handouts forceUpdate:YES];
    }
}

- (void)setNavigationBar {
    self.navigationController.navigationBar.topItem.title = @"";
    // set the custom navigation view properties
    self.customNavView.lbl_TitleView.text = self.course.name;
    [self.customNavView.btn_Back addTarget:self action:@selector(navigateBack) forControlEvents:UIControlEventTouchUpInside];

    //set custom progress bar properties
    [self.customProgressBar setProgressTintColor:PROGRESSBAR_PROGRESS_TINT_COLOR];
    [self.customProgressBar setTrackTintColor:PROGRESSBAR_TRACK_TINT_COLOR];
    [self.customProgressBar setProgress:_dataInterface.totalProgress animated:YES];

    //Analytics Screen record
    [[OEXAnalytics sharedAnalytics] trackScreenWithName:self.course.name];
}

#pragma add remove observer

- (void)addObserver {
    //Add oserver
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateTotalDownloadProgress:) name:TOTAL_DL_PROGRESS object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(dataAvailable:) name:NOTIFICATION_URL_RESPONSE object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reachabilityDidChange:) name:kReachabilityChangedNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(downloadCompleteNotification:)
                                                 name:VIDEO_DL_COMPLETE object:nil];
}

- (void)removeObserver {
    //Add oserver
    [[NSNotificationCenter defaultCenter] removeObserver:self name:TOTAL_DL_PROGRESS object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NOTIFICATION_URL_RESPONSE object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:FL_MESSAGE object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kReachabilityChangedNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:VIDEO_DL_COMPLETE object:nil];
}

- (void)dataAvailable:(NSNotification*)notification {
    NSDictionary* userDetailsDict = (NSDictionary*)notification.userInfo;
    NSString* successString = [userDetailsDict objectForKey:NOTIFICATION_KEY_STATUS];
    NSString* URLString = [userDetailsDict objectForKey:NOTIFICATION_KEY_URL];
    if([successString isEqualToString:NOTIFICATION_VALUE_URL_STATUS_SUCCESS]) {
        if([URLString isEqualToString:self.course.course_updates]) {
            NSData* data = [self.dataInterface resourceDataForURLString:self.course.course_updates downloadIfNotAvailable:NO];
            self.announcements = [self.dataParser announcementsWithData:data];
            if(self.selectedTab == OEXCourseTabCourseInfo) {
                self.courseInfoTabBarController.view.hidden = NO;
                [self.courseInfoTabBarController scrollToTop];
                [self loadAnnouncement];
            }
        }
        else if([URLString isEqualToString:self.course.course_handouts]) {
            NSData* data = [self.dataInterface resourceDataForURLString:self.course.course_handouts downloadIfNotAvailable:NO];
            self.html_Handouts = [self.dataParser handoutsWithData:data];
        }

        else if([URLString isEqualToString:self.course.video_outline]) {
            [self refreshCourseData];
        }
        else if([URLString isEqualToString:NOTIFICATION_VALUE_URL_LASTACCESSED]) {
            self.lastAccessedVideo = [self.dataInterface lastAccessedSubsectionForCourseID:self.course.course_id];
            if(self.lastAccessedVideo) {
                [self reloadTableOnMainThread];
            }
        }
    }
}

#pragma update total download progress

- (void)updateTotalDownloadProgress:(NSNotification* )notification {
    [self.customProgressBar setProgress:_dataInterface.totalProgress animated:YES];
    [self performSelectorOnMainThread:@selector(reloadVisibleRows) withObject:nil waitUntilDone:YES];
}

- (void)downloadCompleteNotification:(NSNotification*)notification {
    NSDictionary* dict = notification.userInfo;
    NSURLSessionTask* task = [dict objectForKey:VIDEO_DL_COMPLETE_N_TASK];
    NSURL* url = task.originalRequest.URL;

    if([OEXInterface isURLForVideo:url.absoluteString]) {
        [self performSelectorOnMainThread:@selector(reloadVisibleRows) withObject:nil waitUntilDone:YES];
    }
}

- (void)reloadVisibleRows {
    [self reloadTableOnMainThread];
}

- (void)reloadTableOnMainThread {
    if([NSThread isMainThread]) {
        [NSObject cancelPreviousPerformRequestsWithTarget:self.table_Courses selector:@selector(reloadVisibleRows) object:nil];
        [self.table_Courses reloadData];
    }
    else {
        __weak OEXCustomTabBarViewViewController* weakSelf = self;
        dispatch_async(dispatch_get_main_queue(), ^{
            [NSObject cancelPreviousPerformRequestsWithTarget:self.table_Courses selector:@selector(reloadVisibleRows) object:nil];
            [weakSelf.table_Courses reloadData];
        });
    }
}

#pragma mark - CollectionView Delegate & Datasourse

- (NSInteger)collectionView:(UICollectionView*)collectionView numberOfItemsInSection:(NSInteger)section {
    //    MOB - 474
    return 2;
}

// The cell that is returned must be retrieved from a call to -dequeueReusableCellWithReuseIdentifier:forIndexPath:
- (UICollectionViewCell*)collectionView:(UICollectionView*)collectionView cellForItemAtIndexPath:(NSIndexPath*)indexPath {
    OEXTabBarItemsCell* cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"tabCell" forIndexPath:indexPath];
    NSString* title;
    switch(indexPath.row) {
        case 0:
            title = [OEXLocalizedString(@"COURSEWARE_TAB_TITLE", nil) oex_uppercaseStringInCurrentLocale];
            break;
        case 1:
            title = [OEXLocalizedString(@"COURSE_INFO_TAB_TITLE", nil) oex_uppercaseStringInCurrentLocale];
            break;
        default:
            break;
    }

    cell.title.text = title;
    if(self.selectedTab == indexPath.row) {
        cell.title.alpha = 1.0;
        [cell.img_Clicked setImage:[UIImage imageNamed:@"bt_scrollbar_tap.png"]];
    }
    else {
        cell.title.alpha = 0.7;
        [cell.img_Clicked setImage:nil];
    }
    return cell;
}

- (void)collectionView:(UICollectionView*)collectionView didSelectItemAtIndexPath:(NSIndexPath*)indexPath {
    OEXCourseTab tab = indexPath.row;
    
    [self showTab:tab];
}

#pragma mark - Announcement loading methods

- (void)loadAnnouncement {
    if(self.selectedTab == OEXCourseTabCourseInfo) {
        self.courseInfoTabBarController.view.hidden = NO;
        [self.courseInfoTabBarController scrollToTop];
    }
    else {
        self.courseInfoTabBarController.view.hidden = YES;
    }

    NSMutableArray* announcements = [NSMutableArray array];
    for(OEXAnnouncement* announcement in self.announcements) {
        [announcements addObject:announcement];
    }

    [self.courseInfoTabBarController useAnnouncements:announcements];

    _didReloadAnnouncement = YES;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView*)tableView {
    // Return the number of sections.
    if(tableView == self.table_Courses) {
        return 2;
    }
    return 1;
}

- (NSInteger)tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section {
    if(self.navigationController.topViewController != self) {
        return 0;
    }
    // Return the number of rows in the section.
    if(tableView == self.table_Courses) {
        if(section == 0) {
            return 1;
        }
        else {
            return self.chapterPathEntries.count;
        }
    }
    return 1;
}

- (CGFloat)tableView:(UITableView*)tableView heightForRowAtIndexPath:(NSIndexPath*)indexPath {
    if(tableView == self.table_Courses) {
        if(indexPath.section == 0) {
            if(self.lastAccessedVideo && _dataInterface.reachable) {
                return 54;
            }
            else {
                return 0;
            }
        }
        else {
            return 44;
        }
    }
    return 44;
}

- (CGFloat)tableView:(UITableView*)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath*)indexPath {
    return UITableViewAutomaticDimension;
}

- (UITableViewCell*)tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath {
    NSString* identifier;

    if([indexPath section] == 0) {
        identifier = @"CellLastAccess";
        OEXLastAccessedTableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:identifier forIndexPath:indexPath];

        OEXHelperVideoDownload* video = self.lastAccessedVideo;

        if(video.summary.sectionPathEntry.name.length == 0) {
            cell.lbl_LastAccessValue.text = @"(Untitled)";
        }
        else {
            cell.lbl_LastAccessValue.text = [NSString stringWithFormat:@" %@ ", video.summary.sectionPathEntry.name];
        }

        if(!video) {
            cell.lbl_LastAccessValue.text = @"";
        }

        if(!_dataInterface.reachable) {
            cell.lbl_LastAccessValue.text = @"";
        }

#ifdef __IPHONE_8_0
        if(IS_IOS8) {
            [cell setLayoutMargins:UIEdgeInsetsZero];
        }
#endif
        return cell;
    }
    else {
        identifier = @"CellCourseDetail";
        OEXCourseDetailTableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:identifier forIndexPath:indexPath];
        OEXVideoPathEntry* chapter = [self.chapterPathEntries oex_safeObjectAtIndex:indexPath.row];

        NSMutableArray* arr_Videos = [_dataInterface videosForChapterID:chapter.entryID sectionID:nil URL:self.course.video_outline];

        cell.lbl_Count.hidden = NO;
        cell.lbl_Count.text = [NSString stringWithFormat:@"%lu", (unsigned long)[arr_Videos count]];
        cell.btn_Download.tag = indexPath.row;
        [cell.btn_Download addTarget:self action:@selector(startDownloadChapterVideos:) forControlEvents:UIControlEventTouchUpInside];
        [cell.customProgressBar setProgressTintColor:PROGRESSBAR_PROGRESS_TINT_COLOR];
        [cell.customProgressBar setTrackTintColor:PROGRESSBAR_TRACK_TINT_COLOR];
        cell.customProgressBar.hidden = YES;

        if(_dataInterface.reachable) {
            cell.backgroundColor = [UIColor whiteColor];

            cell.lbl_Title.text = chapter.name;
            cell.view_Disable.hidden = YES;
            cell.userInteractionEnabled = YES;

            [cell setAccessoryType:UITableViewCellAccessoryNone];

            // check if all videos in that section are downloaded.
            for(OEXHelperVideoDownload* videosDownloaded in arr_Videos) {
                if(videosDownloaded.state == OEXDownloadStateNew) {
                    cell.btn_Download.hidden = NO;
                    break;
                }
                else {
                    cell.btn_Download.hidden = YES;
                }
            }

            if([cell.btn_Download isHidden]) {
                //ELog(@"cell.customProgressBar.progress : %f", cell.customProgressBar.progress);

                float progress = [_dataInterface showBulkProgressViewForCourse:self.course chapterID:chapter.entryID sectionID:nil];

                if(progress < 0) {
                    cell.customProgressBar.hidden = YES;
                }
                else {
                    cell.customProgressBar.hidden = NO;
                    cell.customProgressBar.progress = progress;
                }
            }
        }
        else {
            cell.view_Disable.hidden = YES;
            cell.btn_Download.hidden = YES;
            cell.lbl_Count.hidden = YES;
            [cell setAccessoryType:UITableViewCellAccessoryDisclosureIndicator];

            if([self.offlineAvailableChapterIDs containsObject:chapter.entryID]) {
                cell.backgroundColor = [UIColor whiteColor];
            }
            else {
                cell.backgroundColor = [UIColor colorWithRed:(float)234 / 255 green:(float)234 / 255 blue:(float)237 / 255 alpha:1.0];
            }
            cell.lbl_Title.text = chapter.name;
        }

#ifdef __IPHONE_8_0

        if(IS_IOS8) {
            [cell setLayoutMargins:UIEdgeInsetsZero];
        }
#endif

        return cell;
    }
}

#pragma mark TableViewDelegate

- (void)tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath {
    if(tableView == self.table_Courses) {
        if(indexPath.section == 0) {
            // This is LAST Accessed section
            OEXHelperVideoDownload* video = self.lastAccessedVideo;
            if(video)
            {
                NSArray* downloadProgress = [_dataInterface videosForChapterID:video.summary.chapterPathEntry.entryID sectionID:video.summary.sectionPathEntry.entryID URL:self.course.video_outline];
                [[OEXRouter sharedRouter] showCourseVideoDownloadsFromViewController:self forCourse:self.course lastAccessedVideo:video downloadProgress:downloadProgress selectedPath:video.summary.displayPath];
            }
        }
        else {
            OEXVideoPathEntry* chapter = [self.chapterPathEntries oex_safeObjectAtIndex:indexPath.row];
            if(![self.offlineAvailableChapterIDs containsObject:chapter.entryID]) {
                if(!_dataInterface.reachable) {
                    //MOB - 388
                    [[OEXStatusMessageViewController sharedInstance] showMessage:OEXLocalizedString(@"SECTION_UNAVAILABLE_OFFLINE", nil) onViewController:self];

                    [tableView deselectRowAtIndexPath:indexPath animated:YES];
                    return;
                }
            }
            // Navigate to nextview and pass the Level2 Data
            if(_dataInterface.reachable) {
                NSArray* courseData = [self.dataInterface sectionsForChapterID:chapter.entryID URLString:self.course.video_outline];
                [[OEXRouter sharedRouter] showGenericCoursesFromViewController:self forCourse:self.course withCourseData:courseData selectedChapter:chapter];
            }
            else {
                
                NSArray* downloadProgress = [_dataInterface videosForChapterID:chapter.entryID sectionID:nil URL:self.course.video_outline];
                [[OEXRouter sharedRouter] showCourseVideoDownloadsFromViewController:self forCourse:self.course lastAccessedVideo:nil downloadProgress:downloadProgress selectedPath:@[chapter]];
            }
        }
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
    }
}

- (void)startDownloadChapterVideos:(id)sender {
    OEXAppDelegate* appD = [[UIApplication sharedApplication] delegate];

    if([OEXInterface shouldDownloadOnlyOnWifi]) {
        if(![appD.reachability isReachableViaWiFi]) {
            [[OEXStatusMessageViewController sharedInstance]
             showMessage:OEXLocalizedString(@"NO_WIFI_MESSAGE", nil) onViewController:self];
            return;
        }
    }

    NSInteger tagValue = [sender tag];
    OEXVideoPathEntry* chapter = [self.chapterPathEntries oex_safeObjectAtIndex:tagValue];
    NSMutableArray* arr_Videos = [_dataInterface videosForChapterID: chapter.entryID sectionID:nil URL: self.course.video_outline];
    int count = 0;
    NSMutableArray* validArray = [[NSMutableArray alloc] init];
    for(OEXHelperVideoDownload* video in arr_Videos) {
        if(video.state == OEXDownloadStateNew) {
            count++;
            [validArray addObject:video];
        }
    }
    // Analytics Bulk Video Download From Section
    if(self.course.course_id) {
        [self.environment.analytics trackSectionBulkVideoDownload: chapter.entryID
                                                             CourseID: self.course.course_id
                                                           VideoCount: [validArray count]];
    }

    NSInteger downloadingCount = [_dataInterface downloadMultipleVideosForRequestStrings:validArray];

    if(downloadingCount > 0) {
        NSString* message = [NSString oex_stringWithFormat:
                             OEXLocalizedStringPlural(@"VIDEOS_DOWNLOADING", downloadingCount, nil)
                                                parameters:@{@"count" : @(downloadingCount)}];
        [[OEXStatusMessageViewController sharedInstance] showMessage:message onViewController:self];
    }
    else {
        [[OEXStatusMessageViewController sharedInstance]
         showMessage:OEXLocalizedString(@"UNABLE_TO_DOWNLOAD", nil) onViewController:self];
    }

    [self reloadTableOnMainThread];
}

- (BOOL)webView:(UIWebView*)inWeb shouldStartLoadWithRequest:(NSURLRequest*)inRequest navigationType:(UIWebViewNavigationType)inType {
    if(inType == UIWebViewNavigationTypeLinkClicked) {
        [[UIApplication sharedApplication] openURL:[inRequest URL]];
        return NO;
    }
    return YES;
}

- (void)webView:(UIWebView*)webView didFailLoadWithError:(NSError*)error {
}

- (void)courseInfoTabViewControllerUserTappedOnViewHandouts:(OEXCourseInfoTabViewController*)courseInfoTabViewController {
    if([self.navigationController topViewController] == self) {
        OEXHandoutsViewController* handoutsViewController = [[OEXHandoutsViewController alloc] initWithHandoutsString:self.html_Handouts];
        [self.navigationController pushViewController:handoutsViewController animated:YES];
        [self.environment.analytics trackScreenWithName:[NSString stringWithFormat:@"%@ - Handouts", self.course.name]];
    }
}

- (BOOL)textView:(UITextView*)textView shouldInteractWithURL:(NSURL*)URL inRange:(NSRange)characterRange {
    [[UIApplication sharedApplication]openURL:URL];
    //You can do anything with the URL here (like open in other web view).
    return YES;
}


- (void)showTab:(OEXCourseTab)tab {
    self.selectedTab = tab;
    
    NSIndexPath* path = [NSIndexPath indexPathForItem:tab inSection:0];
    [self.collectionView selectItemAtIndexPath:path animated:NO scrollPosition:UICollectionViewScrollPositionNone];
    [self.collectionView scrollToItemAtIndexPath:path atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally animated:YES];
    [self.collectionView reloadData];
    switch(tab) {
        case OEXCourseTabCourseware:
            self.table_Courses.hidden = NO;
            self.courseInfoTabBarController.view.hidden = YES;
            self.lbl_NoCourseware.text = OEXLocalizedString(@"COURSEWARE_UNAVAILABLE", nil);
            if(self.chapterPathEntries.count > 0) {
                self.activityIndicator.hidden = YES;
                self.lbl_NoCourseware.hidden = YES;
                self.table_Courses.hidden = NO;
            }
            else {
                [self refreshCourseData];
            }
            [self showBrowserView:YES];
            if(!self.course.isStartDateOld &&
               self.chapterPathEntries.count == 0 &&
               !self.loadingCourseware) {
                self.lbl_NoCourseware.attributedText = [self msgFutureCourses];
                self.lbl_NoCourseware.hidden = NO;
            }
            //Analytics Screen record
            [self.environment.analytics trackScreenWithName:[NSString stringWithFormat:@"%@ - Courseware", self.course.name]];
            break;
            
        case OEXCourseTabCourseInfo: {
            self.table_Courses.hidden = YES;
            self.lbl_NoCourseware.hidden = YES;
            self.courseInfoTabBarController.view.hidden = NO;
            [self.courseInfoTabBarController scrollToTop];
            self.activityIndicator.hidden = YES;
            [self showBrowserView:NO];
            if(self.announcements.count > 0) {
                /// return if announcement already downloaded
                if(!self.didReloadAnnouncement) {
                    [self loadAnnouncement];
                }
            }
            //Analytics Screen record
            [self.environment.analytics trackScreenWithName:[NSString stringWithFormat:@"%@ - Course Info", self.course.name]];
            
            break;
        }
    }
}

#pragma mark - Actions

- (IBAction)downloadButtonPressed:(id)sender {
    [[OEXRouter sharedRouter] showDownloadsFromViewController:self fromFrontViews:NO fromGenericView:NO];

}

@end
