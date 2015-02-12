//
//  OEXCustomTabBarViewViewController.m
//  edXVideoLocker
//
//  Created by Nirbhay Agarwal on 16/05/14.
//  Copyright (c) 2014 edX. All rights reserved.
//

#import "OEXCustomTabBarViewViewController.h"

#import "NSArray+OEXSafeAccess.h"

#import "OEXAppDelegate.h"
#import "OEXAnnouncement.h"
#import "OEXAnnouncementsView.h"
#import "OEXAuthentication.h"
#import "OEXConfig.h"
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
#import "OEXStyles.h"
#import "OEXTabBarItemsCell.h"
#import "OEXUserDetails.h"
#import "OEXVideoPathEntry.h"
#import "OEXVideoSummary.h"
#import "Reachability.h"
#import "SWRevealViewController.h"

@interface OEXCustomTabBarViewViewController ()<UITableViewDelegate,UITableViewDataSource>
{
    int cellSelectedIndex;
    NSMutableData *receivedData;
    NSURLConnection *connection;
}

//Announcement variable
@property(nonatomic,strong) IBOutlet UIWebView *webView;
@property (weak, nonatomic) IBOutlet UIWebView *courseInfoWebView;
@property (weak, nonatomic) IBOutlet UIView *containerView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *containerHeightConstraint;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;
@property (weak, nonatomic) IBOutlet UILabel *lbl_NoCourseware;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityAnnouncement;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityHandouts;
@property (weak, nonatomic) IBOutlet UIButton *btn_Downloads;
@property (weak, nonatomic) IBOutlet DACircularProgressView *customProgressBar;
@property (weak, nonatomic) IBOutlet UIView *tabView;
@property (weak, nonatomic) IBOutlet UITableView *table_Courses;
@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;
@property (weak, nonatomic) IBOutlet OEXCustomNavigationView *customNavView;
@property (weak, nonatomic) IBOutlet UITableView *table_Announcements;

@property (nonatomic, assign) BOOL didReloadAnnouncement;
@property (nonatomic,strong)  NSArray *announcements;
@property (nonatomic,strong)  NSDictionary *dict_CourseInfo;
@property (nonatomic,strong)  OEXHelperVideoDownload *lastAccessedVideo;
@property (nonatomic, strong) NSString *OpenInBrowser_URL;

@property (strong , nonatomic) OEXAnnouncementsView *announcementsView;
@property (nonatomic, strong) OEXDataParser *dataParser;
@property (nonatomic, weak) OEXInterface * dataInterface;
// get open in browser URL
@property (nonatomic , strong) OEXOpenInBrowserViewController *browser;
@property (nonatomic, strong) NSArray* chapterPathEntries; // OEXVideoPathEntry array
@property (nonatomic, strong) NSSet* offlineAvailableChapterIDs;
@property(nonatomic,strong)NSString *html_Handouts;

@end

@implementation OEXCustomTabBarViewViewController


#pragma mark - get Course outline from connection

- (void)getCourseOutlineData
{
    NSURL *url = [NSURL URLWithString:self.course.video_outline];
    NSMutableURLRequest *urlRequest = [NSMutableURLRequest requestWithURL:url];
    [urlRequest setTimeoutInterval:75.0f];
    [urlRequest setHTTPMethod:@"GET"];
    NSString *authValue = [NSString stringWithFormat:@"%@",[OEXAuthentication authHeaderForApiAccess]];
    [urlRequest setValue:authValue forHTTPHeaderField:@"Authorization"];
    [urlRequest setValue:@"application/json; charset=utf-8" forHTTPHeaderField:@"Content-Type"];
    connection = [[NSURLConnection alloc] initWithRequest:urlRequest delegate:self];
    
    [connection start];
    
    if(connection)
    {
        receivedData = [NSMutableData data];
    }
}



#pragma mark -
#pragma mark - NSURLConnection Delegtates


- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    if (!receivedData)
	{
		// no store yet, make one
		receivedData = [[NSMutableData alloc] initWithData:data];
	}
	else
	{
		// append to previous chunks
		[receivedData appendData:data];
	}
    
}



- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    
	NSString *response = [[NSString alloc] initWithData:receivedData encoding:NSUTF8StringEncoding];
//	ELog(@"============================================================\n");
//  ELog(@"RESPONSE : %@", response);


    if ([response hasPrefix:@"<html>"])
    {
        self.activityIndicator.hidden = YES;
        self.table_Courses.hidden = YES;
        self.lbl_NoCourseware.hidden = NO;
    }
    else
    {
        if (_dataInterface.selectedCourseOnFront.video_outline)
        {
            [self updateCourseWareData];
        }
    }
}



- (void)updateCourseWareData
{
    self.activityIndicator.hidden = YES;
    self.table_Courses.hidden = NO;
    self.lbl_NoCourseware.hidden = YES;
    
    [self.dataInterface processVideoSummaryList:receivedData URLString:self.course.video_outline];
    
    NSString * courseVideoDetails = self.course.video_outline;
    NSArray * array = [self.dataInterface videosOfCourseWithURLString:courseVideoDetails];
    [_dataInterface storeVideoList:array forURL:courseVideoDetails];
    
    [self refreshCourseData];
    
}



// and error occured
- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
//    ELog(@"error : %@", [error description]);
}






#pragma mark - Offline mode

-(void)dealloc
{
   
    connection = nil;
    _collectionView=nil;
    self.view=nil;
    
}

- (void)populateOfflineCheckData
{
    NSMutableArray *completedVideoInfos = [[NSMutableArray alloc] initWithArray: [_dataInterface coursesAndVideosForDownloadState:OEXDownloadStateComplete]];
    NSMutableArray *downloadedVideos = [[NSMutableArray alloc] init];
    
    for (NSDictionary *videoInfo in completedVideoInfos)
    {
        for (OEXHelperVideoDownload *video in [videoInfo objectForKey:CAV_KEY_VIDEOS]) {
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

- (void)HideOfflineLabel:(BOOL)isOnline
{
    [self showBrowserView:isOnline];
    self.customNavView.lbl_Offline.hidden = isOnline;
    self.customNavView.view_Offline.hidden = isOnline;
    [self.customNavView adjustPositionIfOnline:isOnline];
}


- (void)reachabilityDidChange:(NSNotification *)notification
{
    Reachability *reachability = (Reachability *)[notification object];
    
    if ([reachability isReachable])
    {
        _dataInterface.reachable = YES;
        
        [self HideOfflineLabel:YES];
        
        [self reloadTableOnMainThread];
        
    } else {
        
        _dataInterface.reachable = NO;
        
        [self HideOfflineLabel:NO];
        
        // get the data for offline mode
        [self populateOfflineCheckData];
        
    }
}



#pragma mark - Life Cycle

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

-(void)viewWillDisappear:(BOOL)animated{
    [self removeObserver];
    
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self addObserver];
    
    self.table_Announcements.hidden=YES;

    self.lastAccessedVideo=[self.dataInterface lastAccessedSubsectionForCourseID:_dataInterface.selectedCourseOnFront.course_id];
    
    
    [[OEXOpenInBrowserViewController sharedInstance] addViewToContainerSuperview:self.containerView];
    
    // Check Reachability for OFFLINE
    if (_dataInterface.reachable)
    {
        [self HideOfflineLabel:YES];
    }
    else
    {
        [self HideOfflineLabel:NO];
        
        //MOB-832 Issue solved
        [self refreshCourseData];

        // get the data for offline mode
        [self populateOfflineCheckData];
    
    }
    
    self.courseInfoWebView.scrollView.zoomScale=1.0;

    self.navigationController.navigationBarHidden = YES;

    [self reloadTableOnMainThread];
    
    // To get updated from the server.
    dispatch_async(dispatch_get_main_queue(), ^{
        [_dataInterface getLastVisitedModule];
    });
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // set Back button name to blank.
    
    [self setNavigationBar];
    
    // hide COURSEWARE, announcement,handouts and courseinfo
    self.table_Courses.hidden = YES;
    self.table_Announcements.hidden = YES;
    self.webView.hidden = YES;
    self.courseInfoWebView.hidden = YES;
    self.activityIndicator.hidden = NO;
    self.activityAnnouncement.hidden = YES;
    self.activityHandouts.hidden = YES;
    self.lbl_NoCourseware.hidden = YES;
    [self setExclusiveTouches];

    self.announcementsView = [[OEXAnnouncementsView alloc] initWithFrame:CGRectMake(0, 108, self.view.frame.size.width, self.view.frame.size.height-108)];
    [self.announcementsView setBackgroundColor:[UIColor colorWithRed:226.0/255.0 green:227.0/255.0 blue:229.0/255.0 alpha:1.0]];
    [self.view addSubview:self.announcementsView];

    // Initialize the interface for API calling
    self.dataInterface = [OEXInterface sharedInterface];
    self.announcements = nil;
    
    
    // set open in browser link
    _browser = [OEXOpenInBrowserViewController sharedInstance];
    _browser.str_browserURL = [self.dataInterface openInBrowserLinkForCourse:self.course];
    
    //Fix for 20px issue
   // self.automaticallyAdjustsScrollViewInsets = NO;
    [self addObserver];
    
    
    [[self.dataInterface progressViews] addObject:self.customProgressBar];
    [[self.dataInterface progressViews] addObject:self.btn_Downloads];
    [self.customProgressBar setHidden:YES];
    [self.btn_Downloads setHidden:YES];
    
    NSData * data = [_dataInterface resourceDataForURLString:_dataInterface.selectedCourseOnFront.video_outline downloadIfNotAvailable:NO];
    if (data)
    {
        [self.dataInterface processVideoSummaryList:data URLString:self.course.video_outline];
        self.activityIndicator.hidden = YES;
        [self refreshCourseData];
    }
    else
    {
        [_dataInterface downloadWithRequestString:_dataInterface.selectedCourseOnFront.video_outline forceUpdate:NO];
        [self getCourseOutlineData];
    }
    
    [self performSelector:@selector(initMoreData) withObject:nil afterDelay:0.5];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(showFloatingView:) name:FL_MESSAGE object:nil];
    
#ifdef __IPHONE_8_0
    if (IS_IOS8)
        [self.table_Courses setLayoutMargins:UIEdgeInsetsZero];
#endif
    
}

-(void)setExclusiveTouches{
    
    self.collectionView.exclusiveTouch=YES;
    self.table_Courses.exclusiveTouch = YES;
    self.announcementsView.exclusiveTouch = YES;
    self.webView.exclusiveTouch = YES;
    self.courseInfoWebView.exclusiveTouch = YES;
    self.customNavView.btn_Back.exclusiveTouch=YES;
    self.view.exclusiveTouch=YES;
}


-(void)showFloatingView:(NSNotification * )notification {
    NSDictionary *progress = (NSDictionary *)notification.userInfo;
    
    NSArray * array = [progress objectForKey:FL_ARRAY];
    NSString * sString = @"";
    if (array.count > 1) {
        sString = NSLocalizedString(@"s", nil);
    }
    
}


-(void)viewDidAppear:(BOOL)animated{
    
    [super viewDidAppear:animated];
    
}



- (void)navigateBack
{
    [self removeObserver];
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    [self.navigationController popViewControllerAnimated:YES];

}




#pragma mark Internal Methods


- (void)refreshCourseData
{
    //Get the data from the parsed global array
    self.chapterPathEntries = [[NSArray alloc] initWithArray: [self.dataInterface chaptersForURLString:self.course.video_outline]];
    
    if (cellSelectedIndex == 0 && self.chapterPathEntries.count > 0)
    {
        self.table_Courses.hidden = NO;
        self.announcementsView.hidden=YES;
        self.webView.hidden=YES;
    }
    else
    {
        self.table_Courses.hidden = YES;
        self.activityIndicator.hidden = YES;
        
        if (cellSelectedIndex==0)
        {
            self.lbl_NoCourseware.hidden = NO;
        }
        else
            self.lbl_NoCourseware.hidden = YES;

    }

    
    _browser.str_browserURL = [self.dataInterface openInBrowserLinkForCourse:self.course];
    
    if (cellSelectedIndex==0 && [_browser.str_browserURL length] > 0)
    {
        if (_dataInterface.reachable)
            [self showBrowserView:YES];
        else
            [self showBrowserView:NO];
    }
    else
        [self showBrowserView:NO];
    
    [self reloadTableOnMainThread];

}

- (void)showBrowserView:(BOOL)isShown
{
    __weak OEXCustomTabBarViewViewController *weakself=self;
    
    if( !_table_Courses.hidden && _dataInterface.reachable ){
           weakself.containerHeightConstraint.constant = OPEN_IN_BROWSER_HEIGHT;
           [weakself.containerView layoutIfNeeded];
           weakself.containerView.hidden=NO;
        
    }else{
         weakself.containerHeightConstraint.constant=0;
        [weakself.containerView layoutIfNeeded];
        weakself.containerView.hidden=YES;
    }
    
}




- (void)initMoreData
{
    self.html_Handouts = [[NSString alloc] init];
    
    /// Load Arr anouncement data
    self.announcements=nil;
    
    if (cellSelectedIndex==1)
    {
        self.lbl_NoCourseware.hidden = YES;
        self.activityAnnouncement.hidden = NO;
    }
    
    NSData * data = [self.dataInterface resourceDataForURLString:self.course.course_updates downloadIfNotAvailable:NO];
    if (data)
    {
        self.announcements = [self.dataParser announcementsWithData:data];
        self.activityAnnouncement.hidden = YES;
        
        if (cellSelectedIndex==1)
        {
            self.lbl_NoCourseware.hidden = YES;
            self.announcementsView.hidden = NO;
        }
    }
    else
        [_dataInterface downloadWithRequestString:self.course.course_updates forceUpdate:YES];

    // Get Handouts data
    NSData * handoutData = [self.dataInterface resourceDataForURLString:self.course.course_handouts downloadIfNotAvailable:NO];
    if (handoutData)
    {
        self.html_Handouts=[self.dataParser handoutsWithData:handoutData];
    }
    else
        [_dataInterface downloadWithRequestString:self.course.course_handouts forceUpdate:YES];
    
}



-(void)setNavigationBar
{
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

-(void)addObserver{
    
    //Add oserver
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateTotalDownloadProgress:) name:TOTAL_DL_PROGRESS object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(dataAvailable:) name:NOTIFICATION_URL_RESPONSE object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reachabilityDidChange:) name:kReachabilityChangedNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(downloadCompleteNotification:)
                                                 name:VIDEO_DL_COMPLETE object:nil];
    
}

-(void)removeObserver{
    
    //Add oserver
    [[NSNotificationCenter defaultCenter] removeObserver:self name:TOTAL_DL_PROGRESS object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NOTIFICATION_URL_RESPONSE object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:FL_MESSAGE object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kReachabilityChangedNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:VIDEO_DL_COMPLETE object:nil];
}


- (void)dataAvailable:(NSNotification *)notification
{
    
    
    NSDictionary *userDetailsDict = (NSDictionary *)notification.userInfo;
    NSString * successString = [userDetailsDict objectForKey:NOTIFICATION_KEY_STATUS];
    NSString * URLString = [userDetailsDict objectForKey:NOTIFICATION_KEY_URL];
    
    if ([successString isEqualToString:NOTIFICATION_VALUE_URL_STATUS_SUCCESS])
    {
        if ([URLString isEqualToString:self.course.course_updates])
        {
            NSData * data = [self.dataInterface resourceDataForURLString:self.course.course_updates downloadIfNotAvailable:NO];
            self.announcements = [self.dataParser announcementsWithData:data];

            self.activityAnnouncement.hidden = YES;

            if (cellSelectedIndex==1)
            {
                self.lbl_NoCourseware.hidden = YES;
                self.announcementsView.hidden = NO;
                [self loadAnnouncement];

            }
       
        }
        else if ([URLString isEqualToString:self.course.course_handouts])
        {
        
            NSData * data = [self.dataInterface resourceDataForURLString:self.course.course_handouts downloadIfNotAvailable:NO];
            self.html_Handouts =[self.dataParser handoutsWithData:data];
        }
    
        else if ([URLString isEqualToString:self.course.video_outline])
        {
            self.activityIndicator.hidden = YES;

            [self refreshCourseData];
        }
        else if ([URLString isEqualToString:NOTIFICATION_VALUE_URL_LASTACCESSED])
        {
            self.lastAccessedVideo=[self.dataInterface lastAccessedSubsectionForCourseID:_dataInterface.selectedCourseOnFront.course_id];
            if (self.lastAccessedVideo)
            {
                [self reloadTableOnMainThread];
            }

        }
    }
    
}


#pragma update total download progress

-(void)updateTotalDownloadProgress:(NSNotification * )notification{
    
    [self.customProgressBar setProgress:_dataInterface.totalProgress animated:YES];
    [self performSelectorOnMainThread:@selector(reloadVisibleRows) withObject:nil waitUntilDone:YES];
}

- (void)downloadCompleteNotification:(NSNotification *)notification
{
    NSDictionary * dict = notification.userInfo;
    
    NSURLSessionTask * task = [dict objectForKey:VIDEO_DL_COMPLETE_N_TASK];
    NSURL * url = task.originalRequest.URL;
    
    if ([OEXInterface isURLForVideo:url.absoluteString])
    {
        [self performSelectorOnMainThread:@selector(reloadVisibleRows) withObject:nil waitUntilDone:YES];
    }
}

-(void)reloadVisibleRows
{
    [self reloadTableOnMainThread];
}


- (void)reloadTableOnMainThread
{
    if([NSThread isMainThread]){
        
        [NSObject cancelPreviousPerformRequestsWithTarget:self.table_Courses selector:@selector(reloadVisibleRows) object:nil];
        [self.table_Courses reloadData];
        
    }else{
    __weak OEXCustomTabBarViewViewController *weakSelf=self;
    dispatch_async(dispatch_get_main_queue(), ^{
        
        [NSObject cancelPreviousPerformRequestsWithTarget:self.table_Courses selector:@selector(reloadVisibleRows) object:nil];
        [weakSelf.table_Courses reloadData];
        
    });
  }
}

#pragma mark - CollectionView Delegate & Datasourse

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    //    MOB - 474
    return 3;
}

// The cell that is returned must be retrieved from a call to -dequeueReusableCellWithReuseIdentifier:forIndexPath:
- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    
    OEXTabBarItemsCell * cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"tabCell" forIndexPath:indexPath];
    
    NSString * title;
    
    switch (indexPath.row) {
        case 0:
            title = NSLocalizedString(@"COURSEWARE", nil);
            break;
            
        case 1:
            title = NSLocalizedString(@"ANNOUNCEMENTS", nil);
            break;
            
        case 2:
            title = NSLocalizedString(@"HANDOUTS",nil);
            break;
            
        default:
            break;
    }
    
    cell.title.text = title;
    
    if (cellSelectedIndex == indexPath.row)
    {
        cell.title.alpha = 1.0;
        [cell.img_Clicked setImage:[UIImage imageNamed:@"bt_scrollbar_tap.png"]];
    }
    else
    {
        cell.title.alpha = 0.7;
        [cell.img_Clicked setImage:nil];
    }
    
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    cellSelectedIndex = (int)indexPath.row;
    [collectionView scrollToItemAtIndexPath:indexPath atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally animated:YES];
    [self.collectionView reloadData];

    switch (indexPath.row)
    {
        case 0:
            self.table_Courses.hidden = NO;
            self.announcementsView.hidden=YES;
            self.webView.hidden=YES;
            self.courseInfoWebView.hidden = YES;
            self.lbl_NoCourseware.text = NSLocalizedString(@"COURSEWARE_UNAVAILABLE", nil);
            self.activityAnnouncement.hidden = YES;
            self.activityIndicator.hidden = NO;
            self.activityHandouts.hidden = YES;

            if (self.chapterPathEntries.count > 0)
            {
                self.activityIndicator.hidden = YES;
                self.lbl_NoCourseware.hidden = YES;
                self.table_Courses.hidden = NO;
                
            }else
            {
                if ([self.activityIndicator isHidden])
                {
                    self.lbl_NoCourseware.hidden = NO;
                    self.table_Courses.hidden = YES;
                }
                else
                {
                    self.lbl_NoCourseware.hidden = YES;
                    self.table_Courses.hidden = YES;
                    [self refreshCourseData];
                }
            }
            
            if (_dataInterface.reachable)
            {
                [self showBrowserView:YES];
            }
            else {
                [self showBrowserView:NO];
            }
            
            
            //Analytics Screen record
            [[OEXAnalytics sharedAnalytics] trackScreenWithName:[NSString stringWithFormat:@"%@ - Courseware", self.course.name]];
            
            break;
            
        case 1:{
            __weak OEXCustomTabBarViewViewController *weakSelf=self;
            weakSelf.table_Courses.hidden = YES;
            weakSelf.webView.hidden=YES;
            weakSelf.courseInfoWebView.hidden = YES;
            weakSelf.lbl_NoCourseware.hidden = YES;
            weakSelf.announcementsView.hidden = YES;
            weakSelf.lbl_NoCourseware.text = NSLocalizedString(@"ANNOUNCEMENT_UNAVAILABLE", nil);
            weakSelf.activityIndicator.hidden = YES;
            weakSelf.activityHandouts.hidden = YES;
            weakSelf.activityAnnouncement.hidden = NO;
            [weakSelf showBrowserView:NO];
            if (weakSelf.announcements.count > 0)
            {
                weakSelf.activityAnnouncement.hidden = NO;
                weakSelf.lbl_NoCourseware.hidden = YES;
                self.announcementsView.hidden = NO;
                /// return if announcement already downloaded
                if(!weakSelf.didReloadAnnouncement)
                    [weakSelf loadAnnouncement];
                
                weakSelf.activityAnnouncement.hidden = YES;
            }
            else
            {
                [weakSelf performSelector:@selector(unHideAnnouncementTable) withObject:nil afterDelay:2.0];
            }
            }
            
            //Analytics Screen record
            [[OEXAnalytics sharedAnalytics] trackScreenWithName:[NSString stringWithFormat:@"%@ - Announcements", self.course.name]];

            break;
            
        case 2:
            
            self.table_Courses.hidden = YES;
            self.announcementsView.hidden=YES;
            self.webView.hidden=NO;
            self.courseInfoWebView.hidden = YES;
            self.lbl_NoCourseware.hidden = YES;
            self.activityHandouts.hidden = NO;
            self.activityIndicator.hidden = YES;
            self.activityAnnouncement.hidden = YES;
            [self loadHandouts];
            [self showBrowserView:NO];
            
            //Analytics Screen record
            [[OEXAnalytics sharedAnalytics] trackScreenWithName:[NSString stringWithFormat:@"%@ - Handouts", self.course.name]];

            break;
            
        default:
            break;
    }
}

- (void)unHideAnnouncementTable
{
    if (cellSelectedIndex==1)
    {
        if (self.announcements.count == 0)
        {
            self.activityAnnouncement.hidden = YES;
            self.lbl_NoCourseware.hidden = NO;
        }
    }
}

-(void)loadHandouts
{
    self.courseInfoWebView.hidden = YES;
    self.lbl_NoCourseware.text = NSLocalizedString(@"HANDOUTS_UNAVAILABLE", nil);

    if (self.html_Handouts.length > 0)
    {
        self.activityHandouts.hidden = YES;
        self.webView.hidden = NO;
        self.lbl_NoCourseware.hidden = YES;
        
        NSString* styledHandouts = [OEXStyles styleHTMLContent:self.html_Handouts];
        [self.webView loadHTMLString:styledHandouts baseURL:[NSURL URLWithString:[OEXConfig sharedConfig].apiHostURL]];
    }
    else
    {
        self.webView.hidden = YES;
        self.lbl_NoCourseware.hidden = NO;
        self.activityHandouts.hidden = YES;
    }
}


#pragma mark - Announcement loading methods

- (void)loadAnnouncement
{
    if(cellSelectedIndex==1){
        self.announcementsView.hidden=NO;
    }else{
        self.announcementsView.hidden=YES;
    }

    NSMutableArray* announcements = [NSMutableArray array];
    for(OEXAnnouncement* announcement in self.announcements) {
        [announcements addObject:announcement];
    }
    [self.announcementsView useAnnouncements:announcements];

    _didReloadAnnouncement = YES;
}



#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    if (tableView == self.table_Courses)
        return 2;
    
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if(self.navigationController.topViewController!=self){
        return 0;
    }
    // Return the number of rows in the section.
    if (tableView == self.table_Courses)
    {
        if (section == 0)
        {
            return 1;
        }
        else
            return self.chapterPathEntries.count;
        
    }
    return 1;
    
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (tableView == self.table_Courses)
    {
        if (indexPath.section == 0)
        {
            if(self.lastAccessedVideo && _dataInterface.reachable ){
                return 54;
            }
            else{
                return 0;
            }
            
        }
        else
            return 44;
        
    }
    return 44;
}

- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return UITableViewAutomaticDimension;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString * identifier;
    
    
    if ([indexPath section] == 0)
    {
        identifier = @"CellLastAccess";
        OEXLastAccessedTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier forIndexPath:indexPath];
        
        OEXHelperVideoDownload *video=self.lastAccessedVideo;
        
        if (video.summary.sectionPathEntry.name.length == 0) {
            cell.lbl_LastAccessValue.text=@"(Untitled)";
        }
        else {
             cell.lbl_LastAccessValue.text = [NSString stringWithFormat:@" %@ ", video.summary.sectionPathEntry.name];
        }
        
        if(!video){
            cell.lbl_LastAccessValue.text=@"";
        }
        
        if (!_dataInterface.reachable)
        {
            cell.lbl_LastAccessValue.text=@"";
        }
        
#ifdef __IPHONE_8_0
        if (IS_IOS8)
            [cell setLayoutMargins:UIEdgeInsetsZero];
#endif
        return cell;
    }
    else
    {
        identifier = @"CellCourseDetail";
        OEXCourseDetailTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier forIndexPath:indexPath];
        OEXVideoPathEntry *chapter = [self.chapterPathEntries oex_safeObjectAtIndex:indexPath.row];
        
        NSMutableArray *arr_Videos = [_dataInterface videosForChapterID:chapter.entryID sectionID:nil URL:self.course.video_outline];
        
        cell.lbl_Count.hidden = NO;
        cell.lbl_Count.text = [NSString stringWithFormat:@"%lu", (unsigned long)[arr_Videos count]];
        cell.btn_Download.tag = indexPath.row;
        [cell.btn_Download addTarget:self action:@selector(startDownloadChapterVideos:) forControlEvents:UIControlEventTouchUpInside];
        [cell.customProgressBar setProgressTintColor:PROGRESSBAR_PROGRESS_TINT_COLOR];
        [cell.customProgressBar setTrackTintColor:PROGRESSBAR_TRACK_TINT_COLOR];
        cell.customProgressBar.hidden = YES;
        
        if (_dataInterface.reachable)
        {
            cell.backgroundColor = [UIColor whiteColor];
            
            cell.lbl_Title.text = chapter.name;
            cell.view_Disable.hidden = YES;
            cell.userInteractionEnabled = YES;
            
            [cell setAccessoryType:UITableViewCellAccessoryNone];
            
            // check if all videos in that section are downloaded.
            for (OEXHelperVideoDownload *videosDownloaded in arr_Videos)
            {
                if (videosDownloaded.state == OEXDownloadStateNew)
                {
                    cell.btn_Download.hidden = NO;
                    break;
                }
                else
                {
                    cell.btn_Download.hidden = YES;
                }
            }
            
            if ([cell.btn_Download isHidden])
            {
                //ELog(@"cell.customProgressBar.progress : %f", cell.customProgressBar.progress);
                
                float progress = [_dataInterface showBulkProgressViewForCourse:self.course chapterID:chapter.entryID sectionID:nil];
                
                if (progress < 0)
                {
                    cell.customProgressBar.hidden = YES;
                }
                else
                {
                    cell.customProgressBar.hidden = NO;
                    cell.customProgressBar.progress = progress;
                }
            }
        }
        else
        {
            cell.view_Disable.hidden = YES;
            cell.btn_Download.hidden = YES;
            cell.lbl_Count.hidden = YES;
            [cell setAccessoryType:UITableViewCellAccessoryDisclosureIndicator];
            
            if ([self.offlineAvailableChapterIDs containsObject:chapter.entryID]){
                cell.backgroundColor = [UIColor whiteColor];
            }
            else {
                cell.backgroundColor = [UIColor colorWithRed:(float)234/255 green:(float)234/255 blue:(float)237/255 alpha:1.0];
            }
            cell.lbl_Title.text = chapter.name;
        }
        
#ifdef __IPHONE_8_0
        
        if (IS_IOS8)
            [cell setLayoutMargins:UIEdgeInsetsZero];
#endif
        
        return cell;
    }
    
}


#pragma mark TableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if(tableView==self.table_Courses)
    {
        if (indexPath.section == 0 )
        {
            // This is LAST Accessed section
            UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
            OEXCourseVideoDownloadTableViewController *videoController = [storyboard instantiateViewControllerWithIdentifier:@"CourseVideos"];
            videoController.course = self.course;
            OEXHelperVideoDownload *video=self.lastAccessedVideo;
            if(video){
                videoController.arr_DownloadProgress = [_dataInterface videosForChapterID:video.summary.chapterPathEntry.entryID sectionID:video.summary.sectionPathEntry.entryID URL:self.course.video_outline];
                
                videoController.lastAccessedVideo=video;
                videoController.selectedPath = video.summary.path;
                [self.navigationController pushViewController:videoController animated:YES];
            }
        }
        else
        {
            OEXVideoPathEntry *chapter = [self.chapterPathEntries oex_safeObjectAtIndex:indexPath.row];
            if(![self.offlineAvailableChapterIDs containsObject:chapter.entryID]) {
                if (!_dataInterface.reachable)
                {
                    
                    //MOB - 388
                    [[OEXStatusMessageViewController sharedInstance] showMessage:NSLocalizedString(@"SECTION_UNAVAILABLE_OFFLINE", nil)
                                                             onViewController:self.view
                                                                     messageY:108
                                                                   components:@[self.customNavView , self.tabView, self.customProgressBar, self.btn_Downloads]
                                                                   shouldHide:YES];
                    
                    [tableView deselectRowAtIndexPath:indexPath animated:YES];
                    return;
                }
            }
            // Navigate to nextview and pass the Level2 Data
            UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
            if (_dataInterface.reachable)
            {
                OEXGenericCourseTableViewController *objGeneric = [storyboard instantiateViewControllerWithIdentifier:@"GenericTableView"];
                objGeneric.arr_TableCourseData = [self.dataInterface sectionsForChapterID:chapter.entryID URLString:self.course.video_outline];
                objGeneric.course = self.course;
                objGeneric.selectedChapter = chapter;
                [self.navigationController pushViewController:objGeneric animated:YES];
            }
            else{
                UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
                OEXCourseVideoDownloadTableViewController *videoController = [storyboard instantiateViewControllerWithIdentifier:@"CourseVideos"];
                videoController.course = self.course;
                videoController.selectedPath = @[chapter];
                videoController.arr_DownloadProgress = [_dataInterface videosForChapterID:chapter.entryID sectionID:nil URL:self.course.video_outline];
                
                [self.navigationController pushViewController:videoController animated:YES];
            }
        }
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
    }
}


-(void)startDownloadChapterVideos:(id)sender
{
    OEXAppDelegate *appD = [[UIApplication sharedApplication] delegate];

    if ([OEXInterface shouldDownloadOnlyOnWifi])
    {
        if (![appD.reachability isReachableViaWiFi])
        {
            [[OEXStatusMessageViewController sharedInstance] showMessage:NSLocalizedString(@"NO_WIFI_MESSAGE", nil)
                                                     onViewController:self.view
                                                             messageY:108
                                                           components:@[self.customNavView , self.tabView, self.customProgressBar, self.btn_Downloads]
                                                           shouldHide:YES];
            return;
        }
    
    }
    
    NSInteger tagValue = [sender tag];
    OEXVideoPathEntry* chapter = [self.chapterPathEntries oex_safeObjectAtIndex:tagValue];
    NSMutableArray *arr_Videos = [_dataInterface videosForChapterID: chapter.entryID sectionID:nil URL: self.course.video_outline];
    int count = 0;
    NSMutableArray * validArray = [[NSMutableArray alloc] init];
    for (OEXHelperVideoDownload * video in arr_Videos) {
        if (video.state == OEXDownloadStateNew) {
            count++;
            [validArray addObject:video];
        }
    }
    // Analytics Bulk Video Download From Section
    if (_dataInterface.selectedCourseOnFront.course_id)
    {
        [[OEXAnalytics sharedAnalytics] trackSectionBulkVideoDownload: chapter.entryID
                                        CourseID: _dataInterface.selectedCourseOnFront.course_id
                                      VideoCount: [validArray count]];
        
        
    }
    
    NSString * sString = @"";
    if (count > 1) {
        sString = NSLocalizedString(@"s", nil);
    }
    
    NSInteger downloadingCount=[_dataInterface downloadMultipleVideosForRequestStrings:validArray];
    
    if (downloadingCount > 0) {
            [[OEXStatusMessageViewController sharedInstance] showMessage:[NSString stringWithFormat:@"%@ %d %@%@", NSLocalizedString(@"DOWNLOADING", nil),(int)downloadingCount, NSLocalizedString(@"VIDEO", nil), sString]
                                                     onViewController:self.view
                                                             messageY:108
                                                           components:@[self.customNavView , self.tabView, self.customProgressBar, self.btn_Downloads]
                                                           shouldHide:YES];
        }else{
            
            [[OEXStatusMessageViewController sharedInstance] showMessage:NSLocalizedString(@"UNABLE_TO_DOWNLOAD", nil)
                                                     onViewController:self.view
                                                             messageY:108
                                                           components:@[self.customNavView , self.tabView, self.customProgressBar, self.btn_Downloads]
                                                           shouldHide:YES];
        }

    
    [self reloadTableOnMainThread];
}



-(BOOL) webView:(UIWebView *)inWeb shouldStartLoadWithRequest:(NSURLRequest *)inRequest navigationType:(UIWebViewNavigationType)inType {
    if ( inType == UIWebViewNavigationTypeLinkClicked ) {
        [[UIApplication sharedApplication] openURL:[inRequest URL]];
        return NO;
    }
    return YES;
}


- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error
{
}

- (void)didReceiveMemoryWarning
{
    ELog(@"MemoryWarning CustomTabBarViewViewController");
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(BOOL)textView:(UITextView *)textView shouldInteractWithURL:(NSURL *)URL inRange:(NSRange)characterRange
{
    [[UIApplication sharedApplication]openURL:URL];
    //You can do anything with the URL here (like open in other web view).
    return YES;
}




@end
