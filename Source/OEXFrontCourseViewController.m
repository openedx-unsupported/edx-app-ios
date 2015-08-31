//
//  OEXFrontCourseViewController.m
//  edXVideoLocker
//
//  Created by Nirbhay Agarwal on 16/05/14.
//  Copyright (c) 2014 edX. All rights reserved.
//
#import "edX-Swift.h"

#import "OEXFrontCourseViewController.h"

#import "NSArray+OEXSafeAccess.h"
#import "NSString+OEXFormatting.h"

#import "OEXAnalytics.h"
#import "OEXAppDelegate.h"
#import "OEXCourse.h"
#import "OEXCustomTabBarViewViewController.h"
#import "OEXDateFormatting.h"
#import "OEXDownloadViewController.h"
#import "OEXNetworkConstants.h"
#import "OEXConfig.h"
#import "OEXFindCourseTableViewCell.h"
#import "OEXFrontTableViewCell.h"
#import "OEXLatestUpdates.h"
#import "OEXRegistrationViewController.h"
#import "OEXRouter.h"
#import "OEXUserCourseEnrollment.h"
#import "Reachability.h"
#import "SWRevealViewController.h"
#import "OEXFindCoursesViewController.h"
#import "OEXStatusMessageViewController.h"
#import "OEXEnrollmentMessage.h"
#import "OEXRouter.h"
#import "OEXStyles.h"
#import "OEXCoursewareAccess.h"

@interface OEXFrontCourseViewController () <OEXStatusMessageControlling>
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
    UIBarButtonItem* navigationItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"ic_navigation"] style:UIBarButtonItemStylePlain target:self action:@selector(showSidebar)];
    self.navigationItem.leftBarButtonItem = navigationItem;
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
        for(OEXUserCourseEnrollment* courseEnrollment in _dataInterface.courses) {
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
    ELog(@"refreshView");
    self.refreshTable.attributedTitle = [[NSAttributedString alloc] initWithString:@""];
    self.table_Courses.contentInset = UIEdgeInsetsMake(60, 0, 8, 0);
    [_dataInterface downloadWithRequestString:URL_COURSE_ENROLLMENTS forceUpdate:YES];
}

- (void)endRefreshingData {
    ELog(@"endRefreshingData");
    [self.refreshTable endRefreshing];
}

- (void)removeRefreshControl {
    ELog(@"removeRefreshControl");
    [self.refreshTable removeFromSuperview];
    [self.table_Courses reloadData];
}

#pragma mark - FIND A COURSE

- (void)findCourses:(id)sender {
    [[OEXRouter sharedRouter] showFindCourses];
}

- (void)dontSeeCourses:(id)sender {
    [[OEXRouter sharedRouter] showFullScreenMessageViewControllerFromViewController:self message:OEXLocalizedString(@"COURSE_NOT_LISTED", nil) bottomButtonTitle:OEXLocalizedString(@"CLOSE", nil)];
    
}

- (IBAction)closeClicked:(id)sender {
    [self.view addGestureRecognizer:self.revealViewController.panGestureRecognizer];
}

#pragma mark view delegate methods

- (void)showSidebar {
    self.view.userInteractionEnabled = NO;
    self.overlayButton.hidden = NO;
    // End the refreshing
    [self endRefreshingData];
    [UIView animateWithDuration:0.9 delay:0 options:0 animations:^{
        self.overlayButton.alpha = 0.5f;
    } completion:nil];
    [self performSelector:@selector(call) withObject:nil afterDelay:0.2];
}

- (void)call {
    [self.revealViewController revealToggle:self.btn_LeftNavigation];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle: @" " style: UIBarButtonItemStylePlain target: nil action: nil];
    
    //self.lbl_NavTitle.accessibilityLabel=@"txtHeader";
    self.title = OEXLocalizedString(@"MY_COURSES", nil);

    //Hide back button
    [self.navigationItem setHidesBackButton:YES];
    if (![[OEXConfig sharedConfig] shouldEnableNewCourseNavigation]) {
        [self.navigationController.navigationBar setTranslucent:NO];
    }
    
    //Add custom button for drawer
    self.overlayButton.alpha = 0.0f;

    [self.table_Courses setExclusiveTouch:YES];
    [self.btn_LeftNavigation setExclusiveTouch:YES];
    self.overlayButton.exclusiveTouch = YES;
    self.view.exclusiveTouch = YES;

    self.revealViewController.delegate = self;
    [self.view addGestureRecognizer:self.revealViewController.panGestureRecognizer];
//    [self.view removeGestureRecognizer:self.revealViewController.panGestureRecognizer];

    //Fix for 20px issue for the table view
    self.automaticallyAdjustsScrollViewInsets = NO;

    [self.table_Courses setContentInset:UIEdgeInsetsMake(0, 0, 8, 0)];

    // Add observers
    [self addObservers];

    // Course Data to show up on the TableView
    [self InitializeTableCourseData];

    //Analytics Screen record
    [[OEXAnalytics sharedAnalytics] trackScreenWithName:@"My Courses"];

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
    NSString* message = [NSString oex_stringWithFormat:OEXLocalizedString(@"EXTERNAL_REGISTRATION_BECAME_LOGIN", nil) parameters:@{@"service" : notification.object}];
    [[OEXStatusMessageViewController sharedInstance] showMessage:message onViewController:self];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [self.table_Courses deselectRowAtIndexPath:[self.table_Courses indexPathForSelectedRow] animated:NO];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    self.view.userInteractionEnabled = YES;
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

        OEXCourse* obj_course = [self.arr_CourseData objectAtIndex:indexPath.section];

        OEXFrontTableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:cellIndentifier];

        
        CourseDashboardCourseInfoView* infoView = cell.infoView;
        infoView.course = obj_course;
        
        
        if ([self isRTL]) {
            cell.img_Starting.image = [UIImage imageNamed:@"ic_starting_RTL"];
        }
        
        cell.course = obj_course;
//        cell.img_Course.image = placeHolderImage;
        cell.lbl_Title.text = obj_course.name;

        cell.lbl_Subtitle.text = [NSString stringWithFormat:@"%@ | %@", obj_course.org, obj_course.number];     // Show course ced

        //set course image
        [cell setCourseImage];

        cell.lbl_Starting.hidden = NO;
        cell.img_Starting.hidden = NO;

        // If no new course content is available
        if([obj_course.latest_updates.video length] == 0) {
//            cell.img_NewCourse.hidden = YES;
            cell.btn_NewCourseContent.hidden = YES;

            // If both start and end dates are blank then show nothing.
            if(obj_course.start_display_info.date == nil && obj_course.end == nil) {
                cell.img_Starting.hidden = YES;
                cell.lbl_Starting.hidden = YES;
            }
            else {
                // If start date is older than current date
                if(obj_course.isStartDateOld) {
                    NSString* formattedEndDate = [OEXDateFormatting formatAsMonthDayString: obj_course.end];

                    // If Old date is older than current date
                    if(obj_course.isEndDateOld) {
                        cell.lbl_Starting.text = [NSString stringWithFormat:@"%@ - %@", OEXLocalizedString(@"ENDED", nil), formattedEndDate];
                    }
                    else {      // End date is newer than current date
                        if(obj_course.end == nil) {
                            cell.img_Starting.hidden = YES;
//                            cell.img_NewCourse.hidden = YES;
                            cell.btn_NewCourseContent.hidden = YES;
                            cell.lbl_Starting.hidden = YES;
                        }
                        else {
                            cell.lbl_Starting.text = [NSString stringWithFormat:@"%@ - %@", [OEXLocalizedString(@"ENDING", nil) oex_uppercaseStringInCurrentLocale], formattedEndDate];
                        }
                    }
                }
                else {  // Start date is newer than current date
                    OEXAccessError error_code = obj_course.courseware_access.error_code;
                    if(obj_course.start_display_info.date == nil || (error_code == OEXStartDateError && obj_course.start_display_info.type != OEXStartTypeTimestamp)) {
                        cell.img_Starting.hidden = YES;
//                        cell.img_NewCourse.hidden = YES;
                        cell.btn_NewCourseContent.hidden = YES;
                        cell.lbl_Starting.hidden = YES;
                    }
                    else {
                        NSString* formattedStartDate = [OEXDateFormatting formatAsMonthDayString:obj_course.start_display_info.date];
                        cell.lbl_Starting.text = [NSString stringWithFormat:@"%@ - %@", [OEXLocalizedString(@"STARTING", nil) oex_uppercaseStringInCurrentLocale], formattedStartDate];
                    }
                }
            }
        }
        else {
            cell.img_Starting.hidden = YES;
            cell.lbl_Starting.hidden = YES;
//            cell.img_NewCourse.hidden = NO;
            cell.btn_NewCourseContent.hidden = NO;
        }

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

- (CGFloat)tableView:(UITableView*)tableView heightForRowAtIndexPath:(NSIndexPath*)indexPath {
    if(indexPath.section < [self.arr_CourseData count]) {
        return 187;
    }
    else {
        return 125;
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
            for(OEXUserCourseEnrollment* courseEnrollment in _dataInterface.courses) {
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
            ELog(@"Course data available");
        }
    }
}

#pragma mark  action event

- (void)showCourse:(OEXCourse*)course {
    if(course) {
        [[OEXRouter sharedRouter] showCourse:course fromController:self];
    }
}

- (IBAction)newCourseContentClicked:(UIButton*)sender {
    UIView* view = sender;
    while(![view isKindOfClass:[OEXFrontTableViewCell class]])  {
        view = view.superview;
    }
    OEXCourse* course = ((OEXFrontTableViewCell*)view).course;
    [self showCourse:course];
}

#pragma mark SWRevealViewController

- (void)revealController:(SWRevealViewController*)revealController didMoveToPosition:(FrontViewPosition)position {
    self.view.userInteractionEnabled = YES;
    [super revealController:revealController didMoveToPosition:position];
}

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


- (BOOL) isRTL {
    return [UIApplication sharedApplication].userInterfaceLayoutDirection == UIUserInterfaceLayoutDirectionRightToLeft;
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return [OEXStyles sharedStyles].standardStatusBarStyle;
}

- (void) setAccessibilityLabels {
    self.navigationItem.leftBarButtonItem.accessibilityLabel = OEXLocalizedString(@"ACCESSIBILITY_NAVIGATION", nil);
}

@end
