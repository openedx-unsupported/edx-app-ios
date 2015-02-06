//
//  OEXFrontCourseViewController.m
//  edXVideoLocker
//
//  Created by Nirbhay Agarwal on 16/05/14.
//  Copyright (c) 2014 edX. All rights reserved.
//

#import "OEXFrontCourseViewController.h"

#import "OEXAppDelegate.h"
#import "OEXCourse.h"
#import "OEXCustomTabBarViewViewController.h"
#import "OEXDateFormatting.h"
#import "OEXDownloadViewController.h"
#import "OEXNetworkConstants.h"
#import "OEXConfig.h"
#import "OEXEnvironment.h"
#import "OEXFindCourseTableViewCell.h"
#import "OEXFrontTableViewCell.h"
#import "Reachability.h"
#import "SWRevealViewController.h"
#import "OEXUserCourseEnrollment.h"
#import "OEXFindCourseInterstitialViewController.h"
#import "OEXImageCache.h"

#define ERROR_VIEW_HEIGHT 90

@interface OEXFrontCourseViewController ()<OEXFindCourseInterstitialViewControllerDelegate>
{
    dispatch_queue_t imageQueue;
    UIImage *placeHolderImage;

}

@property (nonatomic, strong) OEXInterface * dataInterface;
@property (nonatomic, strong) NSMutableArray * arr_CourseData;
@property (nonatomic,strong) OEXCourse *selectedCourse;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *ConstraintOfflineErrorHeight;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *constraintErrorY;
@property (strong , nonatomic) UIRefreshControl *refreshTable;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;
@property(nonatomic,strong) OEXCustomTabBarViewViewController *obj_customtab;
@property (weak, nonatomic) IBOutlet UIView *view_EULA;
@property (weak, nonatomic) IBOutlet UIWebView *webview_Message;
@property (weak, nonatomic) IBOutlet UIButton *btn_Close;
@property (weak, nonatomic) IBOutlet UIImageView *separator;
@property (weak, nonatomic) IBOutlet UIView *view_Offline;
@property (weak, nonatomic) IBOutlet UIButton *btn_Downloads;
@property (weak, nonatomic) IBOutlet UILabel *lbl_Offline;
@property (weak, nonatomic) IBOutlet UITableView *table_Courses;
@property (weak, nonatomic) IBOutlet UIButton *btn_LeftNavigation;
@property (weak, nonatomic) IBOutlet DACircularProgressView *customProgressBar;
@property (weak, nonatomic) IBOutlet UILabel *lbl_NavTitle;
@property (weak, nonatomic) IBOutlet UIButton *overlayButton;

- (IBAction)overlayButtonTapped:(id)sender;

@end

@implementation OEXFrontCourseViewController


#pragma mark Controller delegate
-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if([[segue  identifier] isEqualToString:@"LaunchCourseDetailTab"]){
        
        OEXCustomTabBarViewViewController *obj_customtab_temp = (OEXCustomTabBarViewViewController *)[segue destinationViewController];
        obj_customtab_temp.isNewCourseContentSelected = YES;
        obj_customtab_temp.selectedCourse=self.selectedCourse;
        
        
    }else if([[segue  identifier] isEqualToString:@"DownloadControllerSegue"])
    {
        OEXDownloadViewController *obj_download = (OEXDownloadViewController *)[segue destinationViewController];
        obj_download.isFromFrontViews = YES;
    }
}

#pragma mark - Refresh Control

- (void)InitializeTableCourseData
{
    // Initialize array
    
    self.activityIndicator.hidden = NO;
    
    self.arr_CourseData = [[NSMutableArray alloc] init];
    
    placeHolderImage = [UIImage imageNamed:@"Splash_map.png"];
    
    
    // Initialize the interface for API calling
    self.dataInterface = [OEXInterface sharedInterface];
    if (!_dataInterface.courses) {
        [_dataInterface downloadWithRequestString:URL_COURSE_ENROLLMENTS forceUpdate:YES];
    }
    else
    {
        for (OEXUserCourseEnrollment * courseEnrollment in _dataInterface.courses)
        {
            OEXCourse * course = courseEnrollment.course;
            [self.arr_CourseData addObject:course];
        }
        
        self.activityIndicator.hidden = YES;
    }
}

- (void)addRefreshControl
{
    self.refreshTable = [[UIRefreshControl alloc] init];
    self.refreshTable.attributedTitle = [[NSAttributedString alloc] initWithString:@""];
    [self.refreshTable addTarget:self action:@selector(refreshView) forControlEvents:UIControlEventValueChanged];
    [self.table_Courses addSubview:self.refreshTable];
}

- (void)refreshView
{
    ELog(@"refreshView");
    self.refreshTable.attributedTitle = [[NSAttributedString alloc] initWithString:@""];
    self.table_Courses.contentInset = UIEdgeInsetsMake(60, 0, 8, 0);
    [_dataInterface downloadWithRequestString:URL_COURSE_ENROLLMENTS forceUpdate:YES];
    
}

- (void)endRefreshingData
{
    ELog(@"endRefreshingData");
    [self.refreshTable endRefreshing];
}


- (void)removeRefreshControl
{
    ELog(@"removeRefreshControl");
    [self.refreshTable removeFromSuperview];
    [self.table_Courses reloadData];
}


#pragma mark - FIND A COURSE
#pragma mark - FIND A COURSE



-(void)findCourses:(id)sender{
    
    OEXFindCourseInterstitialViewController *interstitialViewController = [[OEXFindCourseInterstitialViewController alloc] init];
    
    interstitialViewController.delegate = self;
    
    [self presentViewController:interstitialViewController animated:NO completion:nil];
    
}



-(void)interstitialViewControllerDidChooseToOpenInBrowser:(OEXFindCourseInterstitialViewController *)interstitialViewController{
    
    [self dismissViewControllerAnimated:NO completion:nil];
    
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:[OEXEnvironment shared].config.courseSearchURL]];
    
    [OEXAnalytics trackUserFindsCourses];
    
}



-(void)interstitialViewControllerDidClose:(OEXFindCourseInterstitialViewController *)interstitialViewController{
    
    [self dismissViewControllerAnimated:NO completion:nil];
    
}


//
//-(void)findCourses:(id)sender
//{
//    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:[OEXEnvironment shared].config.courseSearchURL]];
//
//    [OEXAnalytics trackUserFindsCourses];
//}

- (void)hideWebview:(BOOL)hide
{
    [self.webview_Message.scrollView setContentOffset:CGPointMake(0, 0)];
    self.view_EULA.hidden = hide;
    self.webview_Message.hidden = hide;
    self.btn_Close.hidden = hide;
    self.separator.hidden = hide;
}

- (void)loadWebView
{
    [self.webview_Message loadRequest:[NSURLRequest requestWithURL:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"COURSE_NOT_LISTED" ofType:@"htm"]isDirectory:NO]]];
}

-(void)dontSeeCourses:(id)sender
{
    [self.view removeGestureRecognizer:self.revealViewController.panGestureRecognizer];
    
    [self hideWebview:NO];
}


- (IBAction)closeClicked:(id)sender
{
    [self.view addGestureRecognizer:self.revealViewController.panGestureRecognizer];
    [self hideWebview:YES];
}



#pragma mark view delegate methods

- (void)leftNavigationTapDown
{
    self.overlayButton.hidden = NO;
    [self.navigationController popToViewController:self animated:NO];
    [UIView animateWithDuration:0.9 delay:0 options:0 animations:^{
        self.overlayButton.alpha = 0.5f;
    } completion:^(BOOL finished) {
        
    }];
}

- (void)leftNavigationBtnClicked
{
    self.view.userInteractionEnabled=NO;
    self.overlayButton.hidden = NO;
    // End the refreshing
    [self endRefreshingData];
    [self performSelector:@selector(call) withObject:nil afterDelay:0.2];
}


-(void)call
{
    [self.revealViewController revealToggle:self.btn_LeftNavigation];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    //self.lbl_NavTitle.accessibilityLabel=@"txtHeader";
    self.lbl_NavTitle.text=@"My Courses";
    
    //Hide back button
    [self.navigationItem setHidesBackButton:YES];
    [self.navigationController.navigationBar setTranslucent:NO];
    
    //set navigation title font
    self.lbl_NavTitle.font = [UIFont fontWithName:@"OpenSans-Semibold" size:16.0];
    
    //Add custom button for drawer
    self.overlayButton.alpha = 0.0f;
    [self.btn_LeftNavigation addTarget:self action:@selector(leftNavigationBtnClicked) forControlEvents:UIControlEventTouchUpInside];
    [self.btn_LeftNavigation addTarget:self action:@selector(leftNavigationTapDown) forControlEvents:UIControlEventTouchUpInside];
    
    [self.table_Courses setExclusiveTouch:YES];
    [self.btn_LeftNavigation setExclusiveTouch:YES];
    self.overlayButton.exclusiveTouch=YES;
    self.view.exclusiveTouch=YES;
    
    
    self.revealViewController.delegate = self;
    [self.view addGestureRecognizer:self.revealViewController.panGestureRecognizer];
    //    [self.view removeGestureRecognizer:self.revealViewController.panGestureRecognizer];
    
    
    //set custom progress bar properties
    
    [self.customProgressBar setProgressTintColor:PROGRESSBAR_PROGRESS_TINT_COLOR];
    
    [self.customProgressBar setTrackTintColor:PROGRESSBAR_TRACK_TINT_COLOR];
    
    [self.customProgressBar setProgress:_dataInterface.totalProgress animated:YES];
    
    //Fix for 20px issue for the table view
    self.automaticallyAdjustsScrollViewInsets = NO;
    
    [self.table_Courses setContentInset:UIEdgeInsetsMake(0, 0, 8, 0)];
    
    self.customProgressBar.progress=0.0f;
    
    // Add observers
    [self addObservers];
    
    // Course Data to show up on the TableView
    [self InitializeTableCourseData];
    
    //Analytics Screen record
    [OEXAnalytics screenViewsTracking:@"My Courses"];
    
    
    [[self.dataInterface progressViews] addObject:self.customProgressBar];
    [[self.dataInterface progressViews] addObject:self.btn_Downloads];
    [self.customProgressBar setHidden:YES];
    [self.btn_Downloads setHidden:YES];
    
    if (_dataInterface.reachable)
    {
        [self addRefreshControl];
    }
    
    imageQueue = dispatch_queue_create("Image Queue",NULL);
    
}




- (void)addObservers
{
    //Listen to notification
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(dataAvailable:) name:NOTIFICATION_URL_RESPONSE object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateTotalDownloadProgress:) name:TOTAL_DL_PROGRESS object:nil];
}

- (void)removeObservers
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NOTIFICATION_URL_RESPONSE object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:TOTAL_DL_PROGRESS object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kReachabilityChangedNotification object:nil];
}



-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    
    
    // Add Observer
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reachabilityDidChange:) name:kReachabilityChangedNotification object:nil];
    
    // Check Reachability for OFFLINE
    if (_dataInterface.reachable)
    {
        [self HideOfflineLabel:YES];
    }
    else
    {
        [self HideOfflineLabel:NO];
    }
    
    [self hideWebview:YES];
    [self loadWebView];
    
    // set navigation bar hidden
    OEXAppDelegate *appDelegate = (OEXAppDelegate *)[[UIApplication sharedApplication] delegate];
    [appDelegate.str_ANNOUNCEMENTS_URL setString:@""];
    [appDelegate.str_HANDOUTS_URL setString:@""];
    self.navigationController.navigationBarHidden = YES;
    
}


-(void)viewDidAppear:(BOOL)animated{
    self.view.userInteractionEnabled=YES;
    [self showHideOfflineModeView];
    
}


-(void)showHideOfflineModeView{
    
    if(_dataInterface.shownOfflineView){
        
        [UIView animateWithDuration:1 animations:^{
            
            _constraintErrorY.constant = 42;
            [self.view layoutIfNeeded];
        } completion:^(BOOL finished) {
            
            
            [self performSelector:@selector(hideOfflineHeaderView) withObject:nil afterDelay:2];
            _dataInterface.shownOfflineView=NO;
            
            
        }];
        
    }
    
    
}

-(void)hideOfflineHeaderView{
    
    [UIView animateWithDuration:1 animations:^{
        
        _constraintErrorY.constant = -48;
        
        [self.view layoutIfNeeded];
        
    }];
    
}
#pragma mark internalClassMethods

- (void)reloadTable {
    
    [self.table_Courses reloadData];
    
}

- (void)HideOfflineLabel:(BOOL)isOnline
{
    self.lbl_Offline.hidden = isOnline;
    self.view_Offline.hidden = isOnline;
    
    if(!self.lbl_Offline.hidden)
    {
        self.customProgressBar.hidden=YES;
        self.btn_Downloads.hidden=YES;
    }
    
}



#pragma mark TableViewDataSourceDelegate


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 1;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return [self.arr_CourseData count]+1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    //    ELog(@"%d",indexPath.section);
    if (indexPath.section<[self.arr_CourseData count])
    {
        
        static NSString * cellIndentifier = @"PlayerCell";
        
        OEXFrontTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIndentifier];
        
        OEXCourse *obj_course = [self.arr_CourseData objectAtIndex:indexPath.section];
        
        cell.img_Course.image=placeHolderImage;
        cell.lbl_Title.text = obj_course.name;
        
        cell.lbl_Subtitle.text =  [NSString stringWithFormat:@"%@ | %@" , obj_course.org, obj_course.number]; // Show course ced
        
        NSString *imgURLString = [NSString stringWithFormat:@"%@%@", [OEXEnvironment shared].config.apiHostURL, obj_course.course_image_url];
        if(imgURLString)
        {
            OEXImageCache *imageCache=[OEXImageCache sharedInstance];
            NSString * filePath = [OEXFileUtility completeFilePathForUrl:imgURLString];
            UIImage *displayImage=[imageCache getImageFromCacheFromKey:filePath];
            if(displayImage)
            {
                cell.img_Course.image=displayImage;
            }else
            {
                [imageCache.imageQueue addOperationWithBlock:^{
                    
                    // get the UIImage
                    
                    UIImage *image = [imageCache getImage:imgURLString];
                    
                    // if we found it, then update UI
                    
                    if (image)
                    {
                        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                            // if the cell is visible, then set the image
                            
                            OEXFrontTableViewCell *cell = (OEXFrontTableViewCell *)[self.table_Courses cellForRowAtIndexPath:indexPath];
                            if (cell && [cell isKindOfClass:[OEXFrontTableViewCell class]])
                            {
                                cell.img_Course.image=image;
                            }
                        }];
                        
                        
                    }
                }];
                
            }
            
            
        }
        
        
        cell.lbl_Starting.hidden = NO;
        cell.img_Starting.hidden = NO;
        
        // If no new course content is available
        if ([obj_course.latest_updates.video length]==0)
        {
            cell.img_NewCourse.hidden = YES;
            cell.btn_NewCourseContent.hidden  = YES;
            
            // If both start and end dates are blank then show nothing.
            if (obj_course.start == nil && obj_course.end == nil)
            {
                cell.img_Starting.hidden = YES;
                cell.lbl_Starting.hidden = YES;
            }
            else
            {
                
                // If start date is older than current date
                if (obj_course.isStartDateOld)
                {
                    
                    NSString* formattedEndDate = [OEXDateFormatting formatAsMonthDayString: obj_course.endDate];
                    
                    // If Old date is older than current date
                    if (obj_course.isEndDateOld)
                    {
                        cell.lbl_Starting.text = [NSString stringWithFormat:@"%@ - %@", NSLocalizedString(@"ENDED", nil) , formattedEndDate];
                        
                    }
                    else    // End date is newer than current date
                    {
                        if (obj_course.endDate == nil)
                        {
                            cell.img_Starting.hidden = YES;
                            cell.img_NewCourse.hidden = YES;
                            cell.btn_NewCourseContent.hidden = YES;
                            cell.lbl_Starting.hidden = YES;
                        }
                        else {
                            cell.lbl_Starting.text = [NSString stringWithFormat:@"%@ - %@",NSLocalizedString(@"ENDING", nil) ,formattedEndDate];
                        }
                        
                    }
                    
                }
                else    // Start date is newer than current date
                {
                    if (obj_course.startDate == nil)
                    {
                        cell.img_Starting.hidden = YES;
                        cell.img_NewCourse.hidden = YES;
                        cell.btn_NewCourseContent.hidden = YES;
                        cell.lbl_Starting.hidden = YES;
                    }
                    else {
                        NSString* formattedStartDate = [OEXDateFormatting formatAsMonthDayString:obj_course.startDate];
                        cell.lbl_Starting.text = [NSString stringWithFormat:@"%@ - %@",NSLocalizedString(@"STARTING", nil), formattedStartDate];
                    }
                    
                }
                
            }
            
        }
        else
        {
            cell.img_Starting.hidden = YES;
            cell.lbl_Starting.hidden = YES;
            cell.img_NewCourse.hidden = NO;
            cell.btn_NewCourseContent.hidden = NO;
        }
        
        cell.exclusiveTouch=YES;
        
        return cell;
        
    }
    else
    {
        static NSString * cellIndentifier = @"FindCell";
        
        OEXFindCourseTableViewCell *cellFind = [tableView dequeueReusableCellWithIdentifier:cellIndentifier];
        cellFind.btn_FindACourse.titleLabel.font = [UIFont fontWithName:@"OpenSans" size:cellFind.btn_FindACourse.titleLabel.font.pointSize];
        [cellFind.btn_FindACourse addTarget:self action:@selector(findCourses:) forControlEvents:UIControlEventTouchUpInside];
        
        cellFind.btn_DontSeeCourse.titleLabel.font = [UIFont fontWithName:@"OpenSans" size:cellFind.btn_DontSeeCourse.titleLabel.font.pointSize];
        [cellFind.btn_DontSeeCourse addTarget:self action:@selector(dontSeeCourses:) forControlEvents:UIControlEventTouchUpInside];
        
        
        return cellFind;
        
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if(indexPath.section < [self.arr_CourseData count]){
        return 187;
    }else{
        return 125;
    }
}



- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 8;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    UIView *headerview = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 22)];
    headerview.backgroundColor = [UIColor clearColor];
    return headerview;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    // End the refreshing
    [self endRefreshingData];
    
    OEXAppDelegate *appD = [[UIApplication sharedApplication] delegate];
    if(indexPath.section < [self.arr_CourseData count]){
        self.selectedCourse= [self.arr_CourseData objectAtIndex:indexPath.section];
    }else{
        return;
    }
    [appD.str_COURSE_OUTLINE_URL setString: self.selectedCourse.video_outline];
    appD.str_selected_course=[self.selectedCourse.name mutableCopy];
    _dataInterface.selectedCourseOnFront = self.selectedCourse;
    // To set the title of the next view
    [appD.str_NAVTITLE setString: self.selectedCourse.name];
    [appD.str_HANDOUTS_URL setString: self.selectedCourse.course_handouts];
    [appD.str_ANNOUNCEMENTS_URL setString: self.selectedCourse.course_updates];
    [appD.str_COURSE_ABOUT_URL setString: self.selectedCourse.course_about];
    
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    OEXCustomTabBarViewViewController *viewController =
    [[UIStoryboard storyboardWithName:@"Main"
                               bundle:NULL] instantiateViewControllerWithIdentifier:@"CustomTabBarView"];
    viewController.isNewCourseContentSelected = YES;
    viewController.selectedCourse=self.selectedCourse;
    [self.navigationController pushViewController:viewController animated:YES];
    
    
}





#pragma mark Notifications Received

-(void)updateTotalDownloadProgress:(NSNotification * )notification{
    
    [self.customProgressBar setProgress:_dataInterface.totalProgress animated:YES];
    
}

#pragma mark - Reachability

- (void)reachabilityDidChange:(NSNotification *)notification
{
    Reachability *reachability = (Reachability *)[notification object];
    
    if ([reachability isReachable])
    {
        _dataInterface.reachable = YES;
        
        [self HideOfflineLabel:YES];
        
        [self removeRefreshControl];
        [self addRefreshControl];
        
    } else
    {
        self.activityIndicator.hidden = YES;
        
        _dataInterface.reachable = NO;
        
        [self HideOfflineLabel:NO];
        
        
        [self removeRefreshControl];
        
    }
    
    if([self.navigationController topViewController]==self)
        [self showHideOfflineModeView];
    
    
    
}



#pragma mark data edxInterfaceDelegate

- (void)dataAvailable:(NSNotification *)notification {
    NSDictionary *userDetailsDict = (NSDictionary *)notification.userInfo;
    
    NSString * successString = [userDetailsDict objectForKey:NOTIFICATION_KEY_STATUS];
    NSString * URLString = [userDetailsDict objectForKey:NOTIFICATION_KEY_URL];
    
    if ([successString isEqualToString:NOTIFICATION_VALUE_URL_STATUS_SUCCESS])
    {
        if ([URLString isEqualToString:[_dataInterface URLStringForType:URL_COURSE_ENROLLMENTS]])
        {
            // Change is_registered state to false first for all the entries.
            // Then check the Courseid and update the is_registered to True for
            // only the Courseid we receive in response.
            //
            // The locally saved files for the entries with is_registered False should be removed.
            // Then remvoe the entries from the DB.
            
            // Unregister All entries
            [_dataInterface setAllEntriesUnregister];
            
            [self.arr_CourseData removeAllObjects];
            for (OEXUserCourseEnrollment * courseEnrollment in _dataInterface.courses)
            {
                OEXCourse * course = courseEnrollment.course;
                // is_Register to YES for course.
                [_dataInterface setRegisterCourseForCourseID:course.course_id];
                [self.arr_CourseData addObject:course];
            }
            // Delete all the saved file for unregistered.
            [_dataInterface deleteUnregisteredItems];
            // When we get new data . stop the refresh loading.
            [self endRefreshingData];
            [self.table_Courses reloadData];
            self.activityIndicator.hidden = YES;
            ELog(@"Course data available");
        }
        /*else if ([OEXInterface isURLForImage:URLString])
         {
         NSInteger section = -1;
         for (OEXUserCourseEnrollment * courseEnrollment in _dataInterface.courses)
         {
         OEXCourse * course = courseEnrollment.course;
         section++;
         
         if ([URLString rangeOfString:course.course_image_url].location != NSNotFound)
         {
         NSData * imageData = [_dataInterface resourceDataForURLString:[NSString stringWithFormat:@"%@%@", [OEXEnvironment shared].config.apiHostURL, course.course_image_url] downloadIfNotAvailable:NO];
         course.imageDataCourse = imageData;
         [self.table_Courses reloadData];
         
         break;
         }
         }
         
         }*/
    }
}

#pragma mark  action envent

- (void)newCourseContentClicked:(id)sender
{
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    if(!_obj_customtab){
        _obj_customtab = [storyboard instantiateViewControllerWithIdentifier:@"CustomTabBarView"];
    }
    _obj_customtab.isNewCourseContentSelected = YES;
    [self.navigationController pushViewController:_obj_customtab animated:YES];
    
}


#pragma mark SWRevealViewController


- (void)revealController:(SWRevealViewController *)revealController didMoveToPosition:(FrontViewPosition)position
{
    
    self.view.userInteractionEnabled=YES;
    
    if (position == FrontViewPositionLeft)
    {
        
        //Hide overlay
        [UIView animateWithDuration:0.2 delay:0.0 options:0 animations:^{
            self.overlayButton.alpha = 0.0f;
        } completion:^(BOOL finished) {
            self.overlayButton.hidden = YES;
        }];
        
        
        //check if needs to launch email
        OEXAppDelegate *appDelegate = (OEXAppDelegate *)[[UIApplication sharedApplication] delegate];
        if (appDelegate.pendingMailComposerLaunch) {
            appDelegate.pendingMailComposerLaunch = NO;
            
            if (![MFMailComposeViewController canSendMail]) {
                [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"EMAIL_ACCOUNT_NOT_SET_UP_TITLE", nil)
                                            message:NSLocalizedString(@"EMAIL_ACCOUNT_NOT_SET_UP_MESSAGE", nil)                                           delegate:nil
                                  cancelButtonTitle:NSLocalizedString(@"OK", nil)
                                  otherButtonTitles:nil] show];
            }
            else
            {
                MFMailComposeViewController * mailComposer = [[MFMailComposeViewController alloc] init];
                [mailComposer setMailComposeDelegate:self];
                [mailComposer setSubject:@"Customer Feedback"];
                [mailComposer setMessageBody:@"" isHTML:NO];
                NSString* feedbackAddress = [OEXEnvironment shared].config.feedbackEmailAddress;
                if(feedbackAddress != nil) {
                    [mailComposer setToRecipients:@[feedbackAddress]];
                }
                [self presentViewController:mailComposer animated:YES completion:nil];
            }
        }
    }
    else if (position == FrontViewPositionRight)
    {
        
        self.overlayButton.hidden = NO;
        [self.navigationController popToViewController:self animated:NO];
        [UIView animateWithDuration:0.5 delay:0 options:0 animations:^{
            self.overlayButton.alpha = 0.5f;
        } completion:^(BOOL finished) {
            
        }];
        
    }
}

-(void)mailComposeController:(MFMailComposeViewController*)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)overlayButtonTapped:(id)sender {
    [self.revealViewController revealToggleAnimated:YES];
}

-(void)dealloc{
    imageQueue=nil;
    placeHolderImage=nil;
    [self removeObservers];
}

@end
