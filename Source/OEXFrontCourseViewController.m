//
//  OEXFrontCourseViewController.m
//  edXVideoLocker
//
//  Created by Nirbhay Agarwal on 16/05/14.
//  Copyright (c) 2014-2015 edX. All rights reserved.
//

#import "OEXFrontCourseViewController.h"

#import "edX-Swift.h"
#import "Logger+OEXObjC.h"

#import "NSArray+OEXSafeAccess.h"
#import "NSString+OEXFormatting.h"

#import "OEXAnalytics.h"
#import "OEXAppDelegate.h"
#import "OEXCourse.h"
#import "OEXDateFormatting.h"
#import "OEXDownloadViewController.h"
#import "OEXNetworkConstants.h"
#import "OEXConfig.h"
#import "OEXFindCourseTableViewCell.h"
#import "OEXFrontTableViewCell.h"
#import "OEXLatestUpdates.h"
#import "OEXRegistrationViewController.h"
#import "OEXRouter.h"
#import "Reachability.h"
#import "SWRevealViewController.h"
#import "OEXFindCoursesViewController.h"
#import "OEXStatusMessageViewController.h"
#import "OEXEnrollmentMessage.h"
#import "OEXRouter.h"
#import "OEXStyles.h"
#import "OEXCoursewareAccess.h"

@interface OEXFrontCourseViewController () <OEXStatusMessageControlling, UITableViewDataSource, UITableViewDelegate>
{
    UIImage* placeHolderImage;
}
@property (nonatomic, strong) OEXInterface* dataInterface;
@property (nonatomic, strong) NSMutableArray* arr_CourseData;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint* ConstraintOfflineErrorHeight;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint* constraintErrorY;
@property (strong, nonatomic) UIRefreshControl* refreshTable;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView* activityIndicator;
@property (weak, nonatomic) IBOutlet UIView* offlineMessageContainer;
@property (weak, nonatomic) IBOutlet UITableView* table_Courses;
@property (strong, nonatomic) IBOutlet UIButton* btn_LeftNavigation;

@property (strong, nonatomic) id <Reachability> reachability;
@property (strong, nonatomic) ProgressController* progressController;

@end

@implementation OEXFrontCourseViewController

- (void)awakeFromNib {
    self.progressController = [[ProgressController alloc] initWithOwner:self router:[OEXRouter sharedRouter] dataInterface:[OEXInterface sharedInterface]];
    self.navigationItem.rightBarButtonItem = [[self progressController] navigationItem];
    OEXAppDelegate* delegate = [UIApplication sharedApplication].delegate;
    self.reachability = delegate.reachability;
    [self.reachability startNotifier];
    
    
    self.automaticallyAdjustsScrollViewInsets = false;
    [self setAccessibilityLabels];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    //Analytics Screen record
    [[OEXAnalytics sharedAnalytics] trackScreenWithName:OEXAnalyticsScreenMyCourses];

    [self.navigationController setNavigationBarHidden:false animated:animated];
}

#pragma mark Controller delegate

- (IBAction)downloadButtonPressed:(id)sender {
    [[OEXRouter sharedRouter] showDownloadsFromViewController:self];
}


#pragma mark Status Messages

- (CGFloat)verticalOffsetForStatusController:(OEXStatusMessageViewController*)controller {
    return self.topLayoutGuide.length;
}

- (NSArray*)overlayViewsForStatusController:(OEXStatusMessageViewController*)controller {
    return @[];
}

#pragma mark - Refresh Control

- (void)InitializeTableCourseData {
    // Initialize array

    self.activityIndicator.hidden = NO;

    self.arr_CourseData = [[NSMutableArray alloc] init];

    placeHolderImage = [UIImage imageNamed:@"Splash_map.png"];

    // Initialize the interface for API calling
    self.dataInterface = [OEXInterface sharedInterface];
    if(!_dataInterface.courses) {
        [_dataInterface downloadWithRequestString:URL_COURSE_ENROLLMENTS forceUpdate:YES];
    }
    else {
        for(UserCourseEnrollment* courseEnrollment in _dataInterface.courses) {
            OEXCourse* course = courseEnrollment.course;
            [self.arr_CourseData addObject:course];
        }

        self.activityIndicator.hidden = YES;
    }
}

- (void)addRefreshControl {
    self.refreshTable = [[UIRefreshControl alloc] init];
    self.refreshTable.attributedTitle = [[NSAttributedString alloc] initWithString:@""];
    [self.refreshTable addTarget:self action:@selector(refreshView) forControlEvents:UIControlEventValueChanged];
    [self.table_Courses addSubview:self.refreshTable];
}

- (void)refreshView {
    OEXLogInfo(@"COURSE LIST", @"refreshView");
    self.refreshTable.attributedTitle = [[NSAttributedString alloc] initWithString:@""];
    self.table_Courses.contentInset = UIEdgeInsetsMake(60, 0, 8, 0);
    [_dataInterface downloadWithRequestString:URL_COURSE_ENROLLMENTS forceUpdate:YES];
}

- (void)endRefreshingData {
    OEXLogInfo(@"COURSE LIST", @"endRefreshingData");
    [self.refreshTable endRefreshing];
}

- (void)removeRefreshControl {
    OEXLogInfo(@"COURSE LIST", @"removeRefreshControl");
    [self.refreshTable removeFromSuperview];
    [self.table_Courses reloadData];
}

#pragma mark - FIND A COURSE

- (void)findCourses:(id)sender {
    [[OEXRouter sharedRouter] showFindCourses];
}

- (void)dontSeeCourses:(id)sender {
    [[OEXRouter sharedRouter] showFullScreenMessageViewControllerFromViewController:self message:[Strings courseNotListed] bottomButtonTitle:[Strings close]];
    
}

- (IBAction)closeClicked:(id)sender {
    [self.view addGestureRecognizer:self.revealViewController.panGestureRecognizer];
}

#pragma mark view delegate methods

- (void)showSidebar {
    // End the refreshing
    [self endRefreshingData];
    [self performSelector:@selector(call) withObject:nil afterDelay:0.2];
}

- (void)call {
    [self.revealViewController toggleDrawerAnimated:YES];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle: @" " style: UIBarButtonItemStylePlain target: nil action: nil];
    
    //self.lbl_NavTitle.accessibilityLabel=@"txtHeader";
    self.title = [Strings myCourses];

    //Hide back button
    [self.navigationItem setHidesBackButton:YES];
    
    //Add custom button for drawer

    [self.table_Courses setExclusiveTouch:YES];
    self.table_Courses.estimatedRowHeight = 300.0;
    self.table_Courses.rowHeight = UITableViewAutomaticDimension;
    
    [self.btn_LeftNavigation setExclusiveTouch:YES];
    self.view.exclusiveTouch = YES;

    //Fix for 20px issue for the table view
    self.automaticallyAdjustsScrollViewInsets = NO;

    [self.table_Courses setContentInset:UIEdgeInsetsMake(0, 0, 8, 0)];

    // Add observers
    [self addObservers];

    // Course Data to show up on the TableView
    [self InitializeTableCourseData];

    [[self progressController] hideProgessView];

    if(_dataInterface.reachable) {
        [self addRefreshControl];
    }
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    self.table_Courses.contentInset = UIEdgeInsetsMake(self.topLayoutGuide.length, 0, 0, 0);
}

- (void)addObservers {
    //Listen to notification
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(showCourseEnrollSuccessMessage:) name:NOTIFICATION_COURSE_ENROLLMENT_SUCCESS object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(dataAvailable:) name:NOTIFICATION_URL_RESPONSE object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(showExternalRegistrationWithExistingLoginMessage:) name:OEXExternalRegistrationWithExistingAccountNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reachabilityDidChange:) name:kReachabilityChangedNotification object:self.reachability];
}
    
- (void)showExternalRegistrationWithExistingLoginMessage:(NSNotification*)notification {
    NSString* platform = [[OEXConfig sharedConfig] platformName];
    NSString* message = [Strings externalRegistrationBecameLoginWithPlatformName:platform service:notification.object];
    [[OEXStatusMessageViewController sharedInstance] showMessage:message onViewController:self];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [self.table_Courses deselectRowAtIndexPath:[self.table_Courses indexPathForSelectedRow] animated:NO];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self setOfflineUIVisible:![self.reachability isReachable]];
}

- (CGFloat)offlineHeaderHiddenOffset {
    return -self.offlineMessageContainer.bounds.size.height;
}

- (CGFloat)offlineHeaderVisibleOffset {
    return 0;
}

- (CGFloat)offlineHeaderPeekingOutOffset {
    return [self offlineHeaderHiddenOffset] + 4;
}

- (void)showOfflineHeader {
    if(self.navigationController.topViewController != self) {
        return;
    }
    if(self.constraintErrorY.constant < [self offlineHeaderPeekingOutOffset]) {
        [UIView animateWithDuration:1 animations:^{
            _constraintErrorY.constant = [self offlineHeaderVisibleOffset];
            [self.view layoutIfNeeded];
        } completion:^(BOOL finished) {
            [self performSelector:@selector(peekOfflineHeader) withObject:nil afterDelay:2];
        }];
    }
}

- (void)peekOfflineHeader {
    [UIView animateWithDuration:1 animations:^{
        _constraintErrorY.constant = [self offlineHeaderPeekingOutOffset];
        [self.view layoutIfNeeded];
    }];
}

- (void)hideOfflineHeader {
    [UIView animateWithDuration:.2 animations:^{
        _constraintErrorY.constant = [self offlineHeaderHiddenOffset];
    }];
}
#pragma mark internalClassMethods

- (void)reloadTable {
    [self.table_Courses reloadData];
}

- (void)setOfflineUIVisible:(BOOL)isOffline {
    if(isOffline) {
        self.activityIndicator.hidden = YES;
        [[self progressController] hideProgessView];
        [self removeRefreshControl];
        [self showOfflineHeader];
    }
    else {
        [self removeRefreshControl];
        [self addRefreshControl];
        [self hideOfflineHeader];
    }
}

#pragma mark TableViewDataSourceDelegate

- (NSInteger)tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section {
    return 1;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView*)tableView {
    return [self.arr_CourseData count] + 1;
}

- (UITableViewCell*)tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath {
    if(indexPath.section < [self.arr_CourseData count]) {
        static NSString* cellIndentifier = @"PlayerCell";
        OEXFrontTableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:cellIndentifier];

        OEXCourse* obj_course = [self.arr_CourseData objectAtIndex:indexPath.section];

        CourseCardView* infoView = cell.infoView;
        [CourseCardViewModel applyCourse:obj_course toCardView:infoView forType:CardTypeHome videoDetails: nil];
        
        cell.exclusiveTouch = YES;
        return cell;
    }
    else {
        static NSString* cellIndentifier = @"FindCell";

        OEXFindCourseTableViewCell* cellFind = [tableView dequeueReusableCellWithIdentifier:cellIndentifier];
        cellFind.btn_FindACourse.titleLabel.font = [UIFont fontWithName:@"OpenSans" size:cellFind.btn_FindACourse.titleLabel.font.pointSize];
        [cellFind.btn_FindACourse addTarget:self action:@selector(findCourses:) forControlEvents:UIControlEventTouchUpInside];

        cellFind.btn_DontSeeCourse.titleLabel.font = [UIFont fontWithName:@"OpenSans" size:cellFind.btn_DontSeeCourse.titleLabel.font.pointSize];
        [cellFind.btn_DontSeeCourse addTarget:self action:@selector(dontSeeCourses:) forControlEvents:UIControlEventTouchUpInside];

        return cellFind;
    }
}

- (CGFloat)tableView:(UITableView*)tableView heightForHeaderInSection:(NSInteger)section {
    return 8;
}

- (UIView*)tableView:(UITableView*)tableView viewForHeaderInSection:(NSInteger)section {
    UIView* headerview = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 22)];
    headerview.backgroundColor = [UIColor clearColor];
    return headerview;
}

- (void)tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath {
    if(indexPath.section < self.arr_CourseData.count) {
        OEXCourse* course = [self.arr_CourseData oex_safeObjectAtIndex:indexPath.section];
        [self showCourse:course];
        
        // End the refreshing
        [self endRefreshingData];
    }
    // Else it's the find courses cell
}

#pragma mark - Reachability

- (void)reachabilityDidChange:(NSNotification*)notification {
    id <Reachability> reachability = [notification object];

    if([reachability isReachable]) {
        _dataInterface.reachable = YES;
    }
    else {
        _dataInterface.reachable = NO;
    }
    [self setOfflineUIVisible:![reachability isReachable]];
}

#pragma mark data edxInterfaceDelegate

- (void)dataAvailable:(NSNotification*)notification {
    NSDictionary* userDetailsDict = (NSDictionary*)notification.userInfo;

    NSString* successString = [userDetailsDict objectForKey:NOTIFICATION_KEY_STATUS];
    NSString* URLString = [userDetailsDict objectForKey:NOTIFICATION_KEY_URL];

    if([successString isEqualToString:NOTIFICATION_VALUE_URL_STATUS_SUCCESS]) {
        if([URLString isEqualToString:[_dataInterface URLStringForType:URL_COURSE_ENROLLMENTS]]) {
            // Change is_registered state to false first for all the entries.
            // Then check the Courseid and update the is_registered to True for
            // only the Courseid we receive in response.
            //
            // The locally saved files for the entries with is_registered False should be removed.
            // Then remvoe the entries from the DB.

            // Unregister All entries
            [_dataInterface setAllEntriesUnregister];
            [self.arr_CourseData removeAllObjects];
            NSMutableArray* courses = [[NSMutableArray alloc] init];
            NSMutableSet* seenCourseIds = [[NSMutableSet alloc] init];
            for(UserCourseEnrollment* courseEnrollment in _dataInterface.courses) {
                OEXCourse* course = courseEnrollment.course;
                // is_Register to YES for course.
                if(course.course_id && ![seenCourseIds containsObject:course.course_id]) {
                    [courses addObject:course];
                    [seenCourseIds addObject:course.course_id];
                }
                [self.arr_CourseData addObject:course];
            }
            // Delete all the saved file for unregistered.
            [self.dataInterface setRegisteredCourses:courses];
            [_dataInterface deleteUnregisteredItems];
            // When we get new data . stop the refresh loading.
            [self endRefreshingData];
            [self.table_Courses reloadData];
            self.activityIndicator.hidden = YES;
            OEXLogInfo(@"COURSE LIST", @"Course data available");
        }
    }
}

#pragma mark  action event

- (void)showCourse:(OEXCourse*)course {
    if(course) {
        [[OEXRouter sharedRouter] showCourse:course fromController:self];
    }
}

#pragma mark SWRevealViewController

- (void)showCourseEnrollSuccessMessage:(NSNotification*)notification {
    if(notification.object && [notification.object isKindOfClass:[OEXEnrollmentMessage class]]) {
        OEXEnrollmentMessage* message = (OEXEnrollmentMessage*)notification.object;
        [[OEXStatusMessageViewController sharedInstance]
         showMessage:message.messageBody onViewController:self];
        if(message.shouldReloadTable) {
            self.activityIndicator.hidden = NO;
            [_dataInterface downloadWithRequestString:URL_COURSE_ENROLLMENTS forceUpdate:YES];
        }
    }
}


- (UIStatusBarStyle)preferredStatusBarStyle {
    return [OEXStyles sharedStyles].standardStatusBarStyle;
}

- (void) setAccessibilityLabels {
    self.navigationItem.leftBarButtonItem.accessibilityLabel = [Strings accessibilityNavigation];
}

@end
