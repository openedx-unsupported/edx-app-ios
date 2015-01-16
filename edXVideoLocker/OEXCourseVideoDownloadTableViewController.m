//
//  OEXCourseVideoDownloadTableViewController.m
//  edXVideoLocker
//
//  Created by Rahul Varma on 26/05/14.
//  Copyright (c) 2014 edX. All rights reserved.
//

#import "OEXCourseVideoDownloadTableViewController.h"

#import "OEXAppDelegate.h"
#import "OEXDataParser.h"
#import "OEXCourseVideosTableViewCell.h"
#import "OEXHelperVideoDownload.h"
#import "OEXNetworkConstants.h"
#import "OEXOpenInBrowserViewController.h"
#import "OEXStatusMessageViewController.h"
#import "CLPortraitOptionsView.h"
#import "OEXVideoPlayerInterface.h"
#import "Reachability.h"

#define HEADER_HEIGHT 80.0

typedef  enum OEXAlertType {
    
    OEXAlertTypeNextVideoAlert,
    OEXAlertTypeDeleteConfirmationAlert,
    OEXAlertTypePlayBackErrorAlert,
    OEXAlertTypeCannotPlayVideo,
    OEXAlertTypeVideoTimeOutAlert,
    OEXAlertTypePlayBackContentUnAvailable
    
}OEXAlertType;



@interface OEXCourseVideoDownloadTableViewController ()<OEXVideoPlayerInterfaceDelegate,UITableViewDataSource,UITableViewDelegate>
@property (nonatomic, strong) OEXInterface * dataInterface;
@property (nonatomic, strong) OEXVideoPlayerInterface * videoPlayerInterface;
@property (nonatomic, strong) OEXHelperVideoDownload * currentTappedVideo;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *browerViewHeightConstraint;
@property (weak, nonatomic) IBOutlet UIView *browserContainerView;
@property (nonatomic , strong) NSMutableArray *arr_SubsectionData;
@property (weak, nonatomic) IBOutlet UIView *containerView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *containerHeightConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *editViewHeightConstraint;
@property(nonatomic , assign) BOOL isTableEditing;
@property(nonatomic , assign) BOOL selectAll;
@property(nonatomic) BOOL isStratingNewVideo;
@property (nonatomic , strong) NSMutableArray *arr_SelectedObjects;
@property(nonatomic,strong)NSIndexPath *selectedIndexPath;
@property (nonatomic, strong) NSString * currentPlayingOnlineURL;
@property(nonatomic)NSInteger alertCount;
// get open in browser URL
@property (nonatomic , strong) OEXOpenInBrowserViewController *browser;
@property (nonatomic , strong) OEXDataParser *obj_DataParser;
@property(nonatomic,strong)UIAlertView *confirmAlert;

@property (weak, nonatomic) IBOutlet OEXCustomEditingView *customEditing;
@property (weak, nonatomic) IBOutlet OEXCustomNavigationView *customNavView;
@property (weak, nonatomic) IBOutlet DACircularProgressView *customProgressBarTotal;
@property (weak, nonatomic) IBOutlet UITableView *table_Videos;
@property (weak, nonatomic) IBOutlet UIView *videoPlayerVideoView;
@property (weak, nonatomic) IBOutlet UIView *view_Browser;
@property (weak, nonatomic) IBOutlet UIView *playbackSubview;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *playbackViewHeightConstraint;
@property (weak, nonatomic) IBOutlet UIView  *video_containerView;
@property (weak, nonatomic) IBOutlet UIButton *btn_Downloads;
@property (weak, nonatomic) IBOutlet UIButton *btn_SelectAllEditing;
//@property(nonatomic , assign) BOOL isMovieLoading;
@end

@implementation OEXCourseVideoDownloadTableViewController

#pragma  view dalegate


-(void)viewDidLoad
{
    [super viewDidLoad];
    
    OEXAppDelegate *appD = [[UIApplication sharedApplication] delegate];
    // set the custom navigation view properties
    self.customNavView.lbl_TitleView.text = appD.str_NAVTITLE;;
    
    //Manage for did finish playing
    _isStratingNewVideo=NO;
    
    //video header
    
    //Interface
    self.dataInterface = [OEXInterface sharedInterface];
    self.obj_DataParser = [[OEXDataParser alloc] initWithDataInterface:_dataInterface];
    
    
    ///Hide edit button
    self.editViewHeightConstraint.constant = 0;
    
    // set Back button name to blank.
    self.navigationController.navigationBar.topItem.title = @"";
    
    //Fix for 20px issue for the table view
    self.automaticallyAdjustsScrollViewInsets = NO;
    
    [self.customNavView.btn_Back addTarget:self action:@selector(navigateBack) forControlEvents:UIControlEventTouchUpInside];
    
    //set custom progress bar properties
    
    [self.customProgressBarTotal setProgressTintColor:PROGRESSBAR_PROGRESS_TINT_COLOR];
    [self.customProgressBarTotal setTrackTintColor:PROGRESSBAR_TRACK_TINT_COLOR];
    [self.customProgressBarTotal setProgress:_dataInterface.totalProgress animated:NO];
    
    
    // Manage VideoplayerView
    
    self.playbackViewHeightConstraint.constant = 0;
    self.video_containerView.hidden=YES;
    self.videoPlayerInterface = [[OEXVideoPlayerInterface alloc] init];
    _videoPlayerInterface.videoPlayerVideoView = _videoPlayerVideoView;
    _videoPlayerInterface.delegate=self;
    
    
    //add web items view
    _browser = [OEXOpenInBrowserViewController sharedInstance];
    self.containerHeightConstraint.constant = OPEN_IN_BROWSER_HEIGHT;
    [_browser addViewToContainerSuperview:self.containerView];
    
    
    [[self.dataInterface progressViews] addObject:self.customProgressBarTotal];
    [[self.dataInterface progressViews] addObject:self.btn_Downloads];
    [self.customProgressBarTotal setHidden:YES];
    [self.btn_Downloads setHidden:YES];
    
    
    // Show Custom editing View
    [self.customEditing.btn_Edit addTarget:self action:@selector(editTableClicked:) forControlEvents:UIControlEventTouchUpInside];
    [self.customEditing.btn_Delete addTarget:self action:@selector(deleteTableClicked:) forControlEvents:UIControlEventTouchUpInside];
    [self.customEditing.btn_Cancel addTarget:self action:@selector(cancelTableClicked:) forControlEvents:UIControlEventTouchUpInside];
    self.btn_SelectAllEditing.hidden = YES;
    self.isTableEditing = NO;     // Check Edit button is clicked
    self.selectAll = NO;     // Check if all are selected
    
#ifdef __IPHONE_8_0
    if (IS_IOS8)
        [self.table_Videos setLayoutMargins:UIEdgeInsetsZero];
#endif
    
    
    
    if ([self.arr_DownloadProgress count]>0)
    {
        OEXHelperVideoDownload *video = [self.arr_DownloadProgress firstObject];
        [_dataInterface updateLastVisitedModule:video.subSectionID];
    }
    
    //Analytics Screen record
    [OEXAnalytics screenViewsTracking:@"My Courses"];

}


- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    [self.videoPlayerInterface.moviePlayerController setShouldAutoplay:YES];
    [self.videoPlayerInterface setAutoPlaying:NO];
    if (_videoPlayerInterface) {
        [self.videoPlayerInterface videoPlayerShouldRotate];
    }
    
    [self addObserver];
    // Add Observer
    // Check Reachability for OFFLINE
    
    if (_dataInterface.reachable)
    {
        [self HideOfflineLabel:YES];
    }
    else
    {
        [self HideOfflineLabel:NO];
        self.containerHeightConstraint.constant = 0;
    }
    
}


- (void)viewWillDisappear:(BOOL)animated
{
    if(self.navigationController.topViewController != self)
    {
        [[CLPortraitOptionsView sharedInstance] removeSelfFromSuperView];
        
        // MOB 560
        [self.videoPlayerInterface.moviePlayerController setShouldAutoplay:NO];
        
        [self.videoPlayerInterface.moviePlayerController pause];
    
    }
    [self.videoPlayerInterface setAutoPlaying:NO];
    [self removeObserver];
}



- (void)navigateBack
{
    [self.videoPlayerInterface.moviePlayerController setShouldAutoplay:NO];
    [self.videoPlayerInterface resetPlayer];
    [self.videoPlayerInterface.moviePlayerController stop];
    [self.videoPlayerInterface resetPlayer];
    [self removeObserver];
    self.videoPlayerVideoView=nil;
    self.videoPlayerInterface.delegate=nil;
    if (_dataInterface.reachable)
        [self.navigationController popViewControllerAnimated:YES];
    else
        [self.navigationController popToViewController:[self.navigationController.viewControllers objectAtIndex:1] animated:YES];
    
}

-(void)dealloc{
    
}

#pragma mark - Show CC options in portrait mode

- (void)showCCPortrait:(NSNotification *)notification
{
    NSDictionary *dict = notification.userInfo;
    [[CLPortraitOptionsView sharedInstance] addValueToArray:dict];
    [[CLPortraitOptionsView sharedInstance] addViewToContainerSuperview:self.view];
}

#pragma mark - OFFLINE mode

- (void)manageOfflineData
{
    OEXAppDelegate *appD = [[UIApplication sharedApplication] delegate];
    self.arr_OfflineData = [[NSMutableArray alloc] init];
    self.arr_OfflineData = [_dataInterface videosForChaptername:self.customNavView.lbl_TitleView.text andSectionName:nil forURL:appD.str_COURSE_OUTLINE_URL];
    // Initialize array of data to show on table
    self.arr_SubsectionData = [[NSMutableArray alloc] init];
    [self getSubsectionVideoDataFromArray:self.arr_OfflineData];
    
    // make below array of dictionary structure
    /*
     [
     {
     "ksection":"sectionname",
     "kvideos":[videoobj, videoobj]
     }
     ]
     */
    
}


- (void)getSubsectionVideoDataFromArray:(NSMutableArray *)arr
{
    
    // arr --> array of all HelperVideoDownload objects in clicked Course
    for (OEXHelperVideoDownload *video in arr)
    {
        NSMutableArray *arr_section = [[NSMutableArray alloc] init];
        
        // Sorting the data with chapter name and section name
        for (OEXHelperVideoDownload *objvideo in arr)
        {
            // Compare both chapter names and section names
            if ([video.ChapterName isEqualToString:objvideo.ChapterName ] && [video.SectionName isEqualToString:objvideo.SectionName ])
            {
                [arr_section addObject:objvideo];
            }
            
        }
        
        [self.arr_SubsectionData addObject:arr_section];
        
    }
    
    [self removeDuplicateData];
    
}


- (void)removeDuplicateData
{
    NSMutableArray *arrTemp = [[NSMutableArray alloc] initWithArray:self.arr_SubsectionData];
    
    for (NSArray *array in arrTemp)
    {
        BOOL FlagRemoveObject = NO;
        int Count = 0;
        
        for (OEXHelperVideoDownload *videos in array)
        {
            // Comparing objects
            for (NSArray *arrayCompare in arrTemp)
            {
                for (OEXHelperVideoDownload *videosCompare in arrayCompare)
                {
                    if ([videos.ChapterName isEqualToString:videosCompare.ChapterName ] && [videos.SectionName isEqualToString:videosCompare.SectionName ])
                    {
                        Count++;
                        
                        // counting if there are more than 2 objects
                        if (Count > 1)
                        {
                            FlagRemoveObject = YES;
                            break;
                        }
                        
                    }
                    
                }
            }
            
        }
        
        if (FlagRemoveObject)
            [self.arr_SubsectionData removeObject:array];
        
        // If there are more than 1 similar objects
        if (Count>1) {
            [self.arr_SubsectionData addObject:array];
        }
    }
    
    [self checkAndchangeDownloadStateOfVideos:self.arr_SubsectionData];
    
}


- (void)checkAndchangeDownloadStateOfVideos:(NSMutableArray *)arrayVideos
{
    NSMutableArray *arrCourseAndVideo = [[NSMutableArray alloc] initWithArray: [_dataInterface coursesAndVideosForDownloadState:OEXDownloadStateComplete] ];
    
    NSMutableArray *temp = [[NSMutableArray alloc] init];
    
    // Populate both downloaded Video objs
    for (NSDictionary *dict in arrCourseAndVideo)
    {
        for (OEXHelperVideoDownload *videos in [dict objectForKey:CAV_KEY_VIDEOS])
        {
            [temp addObject:videos];
        }
    }
    
    // Now check if the object is downloaded or not.
    // If yes, then change the OEXDownloadState to complete in arr_SibsectionData
    
    BOOL isVideoAvail = NO;
    
    for (NSMutableArray *arr in self.arr_SubsectionData)
    {
        for (OEXHelperVideoDownload *obj in arr)
        {
            NSString *str_chap = [[NSString alloc] initWithString: obj.ChapterName];
            NSString *str_sec = [[NSString alloc] initWithString: obj.SectionName];
            NSString *str_URL = [[NSString alloc] initWithString: obj.str_VideoURL];
            
            for (OEXHelperVideoDownload *comparevideo in temp)
            {
                NSString *compare_chap = [[NSString alloc] initWithString: comparevideo.ChapterName];
                NSString *compare_sec = [[NSString alloc] initWithString: comparevideo.SectionName];
                NSString *compare_URL = [[NSString alloc] initWithString: comparevideo.str_VideoURL];
                
                if ([str_URL isEqualToString:compare_URL] && [str_chap isEqualToString:compare_chap] && [str_sec isEqualToString:compare_sec])
                {
                    isVideoAvail = YES;
                    obj.state = OEXDownloadStateComplete;
                    obj.filePath = comparevideo.filePath;
                    obj.watchedState = comparevideo.watchedState;
                    obj.DownloadProgress = comparevideo.DownloadProgress;
                    break;
                }
                
            }
        }
        
    }
    
    if(isVideoAvail)
    {
        self.editViewHeightConstraint.constant = 50;
    }
    else
        self.editViewHeightConstraint.constant = 0;
}




- (void)showBrowserView:(BOOL)isShown
{
    
    
    if(self.playbackViewHeightConstraint.constant > 0){
        self.containerHeightConstraint.constant = 0;
        [self.view layoutIfNeeded];
        return;
    }
    
    
    if (isShown && _browser.str_browserURL)
    {
        if ([_browser.str_browserURL length] == 0)
        {
            self.containerHeightConstraint.constant = 0;
            [self.view layoutIfNeeded];
        }
        else
        {
            self.containerHeightConstraint.constant = OPEN_IN_BROWSER_HEIGHT;
            [self.view layoutIfNeeded];
        }
        
    }
    else
    {
        self.containerHeightConstraint.constant = 0;
        [self.table_Videos reloadData];
        [self.view layoutIfNeeded];
    
    }
    if (self.playbackViewHeightConstraint.constant > 0)
      {
        self.containerHeightConstraint.constant = 0;
        [UIView animateWithDuration:ANIMATION_DURATION animations:^{
            [self.view layoutIfNeeded];
            
            
        } completion:^(BOOL finished)
         {
         }];
    }
}

- (void)manageOnlineData
{
    OEXAppDelegate *appD = [[UIApplication sharedApplication] delegate];
    self.arr_DownloadProgress = [[NSMutableArray alloc] init];
    self.table_Videos.delegate = self;
    self.table_Videos.dataSource = self;
    
    if (_isFromGenericView)
    {
        self.arr_DownloadProgress = [_dataInterface videosForChaptername:self.str_SelectedChapName andSectionName:appD.str_NAVTITLE forURL:appD.str_COURSE_OUTLINE_URL];
    }
    else
    {
        self.arr_DownloadProgress = [_dataInterface videosForChaptername:self.str_SelectedChapName andSectionName:nil forURL:appD.str_COURSE_OUTLINE_URL];
    }
    
  [self performSelector:@selector(reloadTableOnMainThread) withObject:nil afterDelay:1.0];

}


#pragma mark - REACHABILITY

- (void)HideOfflineLabel:(BOOL)isOnline
{
    if (isOnline)
    {

        self.customNavView.lbl_Offline.hidden = YES;
        self.containerHeightConstraint.constant = 0;
        
        self.editViewHeightConstraint.constant = 0;
        self.btn_SelectAllEditing.hidden = YES;
        
        self.customNavView.view_Offline.hidden = YES;
        [self.table_Videos setContentInset:UIEdgeInsetsMake(0, 0 , 0 , 0)];
        [self showBrowserView:isOnline];
        
    }
    else
    {
        
        if (_isFromGenericView)
        {
             self.customNavView.lbl_TitleView.text = self.str_SelectedChapName;
        }
        
        
        self.customNavView.lbl_Offline.hidden = NO;
        self.customNavView.view_Offline.hidden = NO;
        [self.customNavView adjustPositionOfComponentsWithEditingMode:_isTableEditing isOnline:NO];
        
        
        self.btn_SelectAllEditing.hidden = YES;
        [self.customEditing.btn_Edit addTarget:self action:@selector(editTableClicked:) forControlEvents:UIControlEventTouchUpInside];
        [self.customEditing.btn_Delete addTarget:self action:@selector(deleteTableClicked:) forControlEvents:UIControlEventTouchUpInside];
        [self.customEditing.btn_Cancel addTarget:self action:@selector(cancelTableClicked:) forControlEvents:UIControlEventTouchUpInside];
        self.isTableEditing = NO;     // Check Edit button is clicked
        self.selectAll = NO;     // Check if all are selected
        
        [self showBrowserView:isOnline];
        [self manageOfflineData];
        
        if(self.playbackViewHeightConstraint.constant == 0)
        {
            [self.table_Videos  setContentInset:UIEdgeInsetsMake(0, 0 , 50 , 0)];
            
            self.containerHeightConstraint.constant = 0;
        }else
        {
            self.editViewHeightConstraint.constant = 0;
            
        }
        
        [self cancelTableClicked:nil];
    }
    

    [self.customNavView adjustPositionIfOnline:isOnline];

    [self.table_Videos reloadData];
    
}

- (void)reachabilityDidChange:(NSNotification *)notification
{
    
    OEXAppDelegate *appD = [[UIApplication sharedApplication] delegate];
    // set the custom navigation view properties
    self.customNavView.lbl_TitleView.text = appD.str_NAVTITLE;;
    
    Reachability *reachability = (Reachability *)[notification object];
    
    if ([reachability isReachable])
    {
        _dataInterface.reachable = YES;
        [self HideOfflineLabel:YES];
        [self.arr_SelectedObjects removeAllObjects];
        [_confirmAlert dismissWithClickedButtonIndex:0 animated:YES];
        
    } else {
    
       
        _dataInterface.reachable = NO;
        [self HideOfflineLabel:NO];
        [self showDeviceGoneOfflineMessage];
    }
}

-(void)showDeviceGoneOfflineMessage
{
    
    if(self.playbackViewHeightConstraint.constant >0 && self.currentTappedVideo.state!=OEXDownloadStateComplete )// To
    {
        
        [[OEXStatusMessageViewController sharedInstance] showMessage:NSLocalizedString(@"CHECK_CONNECTION", nil)
                                                 onViewController:self.view
                                                         messageY:64
                                                       components:@[self.customNavView, self.customProgressBarTotal, self.btn_SelectAllEditing, self.btn_Downloads]
                                                       shouldHide:YES];
        
        
    }
    
}






#pragma update total download progress

-(void)updateTotalDownloadProgress:(NSNotification * )notification{
    
    [self.customProgressBarTotal setProgress:_dataInterface.totalProgress animated:YES];
    
}


- (void)didReceiveMemoryWarning
{
    ELog(@"MemoryWarning CourseVideoDownloadTableViewController");
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (UIView *)setOfflineTableHeaderInSection:(NSInteger)section
{
    OEXHelperVideoDownload *video = [[self.arr_SubsectionData objectAtIndex:section] objectAtIndex:0];

    BOOL ChapnameExists = [self ChapterNameAlreadyDisplayed:section];
    
    
    UIView *viewMain;
    UIView *viewTop;
    UIView *viewBottom;
    UILabel *chapTitle;
    UILabel *sectionTitle;
    
    if (ChapnameExists)
    {
        
        viewMain = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 30 )];
        
        viewBottom = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 30 )];
        viewBottom.backgroundColor = GREY_COLOR;
        [viewMain addSubview:viewBottom];
        
        sectionTitle = [[UILabel alloc] initWithFrame:CGRectMake(20, 0, 300, 30)];
        sectionTitle.text = video.SectionName;
        sectionTitle.font = [UIFont fontWithName:@"OpenSans-Semibold" size:14.0f];
        sectionTitle.textColor = [UIColor blackColor];
        [viewMain addSubview:sectionTitle];
        
    }
    else
    {
        
        viewMain = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, HEADER_HEIGHT )];
        
        viewTop = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 50 )];
        viewTop.backgroundColor = [UIColor colorWithRed:62.0/255.0 green:66.0/255.0 blue:71.0/255.0 alpha:1.0];
        [viewMain addSubview:viewTop];
        
        
        viewBottom = [[UIView alloc] initWithFrame:CGRectMake(0, 50, 320, 30 )];
        viewBottom.backgroundColor = GREY_COLOR;
        [viewMain addSubview:viewBottom];
        
        
        chapTitle = [[UILabel alloc] initWithFrame:CGRectMake(20, 0, 300, 50)];
        chapTitle.text = video.ChapterName;
        chapTitle.font = [UIFont fontWithName:@"OpenSans-Semibold" size:14.0f];
        chapTitle.textColor = [UIColor whiteColor];
        [viewMain addSubview:chapTitle];
        
        
        sectionTitle = [[UILabel alloc] initWithFrame:CGRectMake(20, 50, 300, 30)];
        sectionTitle.text = video.SectionName;
        sectionTitle.font = [UIFont fontWithName:@"OpenSans-Semibold" size:14.0f];
        sectionTitle.textColor = [UIColor blackColor];
        [viewMain addSubview:sectionTitle];
        
    }
    return viewMain;
}


- (BOOL)ChapterNameAlreadyDisplayed:(NSInteger)section
{
    OEXHelperVideoDownload *video = [[self.arr_SubsectionData objectAtIndex:section] objectAtIndex:0];
    
    //  Below for loop check to resolve MOB-447
    //  Multiple headers for the same Section appear in My Videos
    BOOL ChapnameExists = NO;
    for (int i=0; i < section; i++)
    {
        OEXHelperVideoDownload *videoCompare = [[self.arr_SubsectionData objectAtIndex:i] objectAtIndex:0];
        
        if ([video.ChapterName isEqualToString:videoCompare.ChapterName])
        {
            ChapnameExists = YES;
        }
    }
    
    return ChapnameExists;
}


- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    if (!_dataInterface.reachable)
    {
        
        // The condition means --> In any case it is offline mode
       return [self setOfflineTableHeaderInSection:section];
        
    }
    else if (_dataInterface.reachable &&  !_isFromGenericView)
    {
        
        // The condition means below
        //  1) CourseTabBarViewController (OFFLINE Mode)
        //  2) CourseVideoDownloadViewController (OFFLINE Mode)
        //  3) CourseVideoDownloadViewController (ONLINE Mode)
        
        return [self setOfflineTableHeaderInSection:section];

    }
    else
        return nil;
    
    return nil;
}


- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    if (!_dataInterface.reachable)
    {
        BOOL ChapnameExists = [self ChapterNameAlreadyDisplayed:section];
        
        if (ChapnameExists)
        {
            return 30;
        }
        else
            return HEADER_HEIGHT;
    }
    else if (_dataInterface.reachable && !_isFromGenericView)
    {
        BOOL ChapnameExists = [self ChapterNameAlreadyDisplayed:section];
        
        if (ChapnameExists)
        {
            return 30;
        }
        else
            return HEADER_HEIGHT;
    }
    else
        return 0;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 60;
}


- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    _selectedIndexPath=nil;
    
    if (!_dataInterface.reachable)
        return [self.arr_SubsectionData count];
    else if (_dataInterface.reachable && !_isFromGenericView)
        return [self.arr_SubsectionData count];
    else
        return 1;
    
}



- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (!_dataInterface.reachable)
        return [[self.arr_SubsectionData objectAtIndex:section] count];
    else if (_dataInterface.reachable && !_isFromGenericView)
        return [[self.arr_SubsectionData objectAtIndex:section] count];
    else
        return [self.arr_DownloadProgress count];
    
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    //NSLog(@"TOP indexPath.row : %d ",indexPath.row);
    if (!_dataInterface.reachable) /// Offline mode
    {
        
        return [self configureOfflineCellFor:tableView indexPath:indexPath];
        
    }
    else if (_dataInterface.reachable && !_isFromGenericView) /// online mode
    {
        // in Online mode but does not comes from generic mode
        
        static NSString * cellIndentifier = @"CellCourseVideo";
        
        OEXCourseVideosTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIndentifier forIndexPath:indexPath];
        cell.selectionStyle=UITableViewCellSelectionStyleDefault;
        cell.backgroundColor = [UIColor whiteColor];
        // hide edit button when online
        cell.btn_CheckboxDelete.hidden = YES;
        NSArray *videos = [self.arr_SubsectionData objectAtIndex:indexPath.section];
        OEXHelperVideoDownload *obj_video = [videos objectAtIndex:indexPath.row];
        
        //Progress
        cell.customProgressView.tag = indexPath.row;
        [cell.customProgressView setProgress:(obj_video.DownloadProgress)/100.0 animated:YES];
        [cell.customProgressView setProgressTintColor:PROGRESSBAR_PROGRESS_TINT_COLOR];
        [cell.customProgressView setTrackTintColor:PROGRESSBAR_TRACK_TINT_COLOR];
        cell.view_DisableOffline.hidden = YES;

        
        //Title
        cell.lbl_Title.text = obj_video.str_VideoTitle;
        
        if ([cell.lbl_Title.text length]==0) {
            cell.lbl_Title.text = @"(Untitled)";
        }
        
        
        // Size and Duration
        double size = [obj_video.size doubleValue];
        float result = ((size/1024)/1024);
        cell.lbl_Size.text = [NSString stringWithFormat:@"%.2fMB",result];
        //download button
        cell.btn_Download.tag = indexPath.row;
        [cell.btn_Download addTarget:self action:@selector(startDownloadVideo:) forControlEvents:UIControlEventTouchUpInside];
        
        
        //Played state
        UIImage * playedImage;
        if (obj_video.watchedState == OEXPlayedStateWatched) {
            playedImage = [UIImage imageNamed:@"ic_watched.png"];
        }
        else if (obj_video.watchedState == OEXPlayedStatePartiallyWatched) {
            playedImage = [UIImage imageNamed:@"ic_partiallywatched.png"];
        }
        else {
            playedImage = [UIImage imageNamed:@"ic_unwatched.png"];
        }
        cell.img_VideoWatchState.image = playedImage;
        
        
        if(self.currentTappedVideo==obj_video && !self.isTableEditing){
            _selectedIndexPath=indexPath;
            [self setSelectedCellAtIndexPath:indexPath tableView:tableView];
        }
        
        
        // MOB - 459
        if(_playbackViewHeightConstraint.constant > 0)
        {
            if (_selectedIndexPath == indexPath)
            {
                cell.btn_Download.hidden = YES;
                
                if (obj_video.DownloadProgress > 0)
                {
                    if (obj_video.DownloadProgress == 100)
                    {
                        cell.customProgressView.hidden = YES;
                    }
                    else
                        cell.customProgressView.hidden = NO;
                }
            }
            else
            {
                if (obj_video.DownloadProgress > 0)
                {
                    if (obj_video.DownloadProgress == 100)
                    {
                        cell.customProgressView.hidden = YES;
                    }
                    else
                        cell.customProgressView.hidden = NO;
                    
                    cell.btn_Download.hidden = YES;
                }
                else
                {
                    cell.customProgressView.hidden = YES;
                    cell.btn_Download.hidden = NO;
                }
            }
            
        }
        else
        {
            
            if (obj_video.DownloadProgress > 0)
            {
                cell.btn_Download.hidden = YES;
                
                if (obj_video.DownloadProgress == 100)
                {
                    cell.customProgressView.hidden = YES;
                }
                else
                {
                    cell.customProgressView.hidden = NO;
                }
            }
            else
            {
                cell.customProgressView.hidden = YES;
                cell.btn_Download.hidden = NO;
            }
        }

#ifdef __IPHONE_8_0
        if (IS_IOS8)
            [cell setLayoutMargins:UIEdgeInsetsZero];
#endif
       
        return cell;
        
    }
    else
    {
        
        // in Online mode navigated from generic view
        
        OEXCourseVideosTableViewCell *cell = [self.table_Videos dequeueReusableCellWithIdentifier:@"CellCourseVideo" forIndexPath:indexPath];
        //NSLog(@"indexPath.row : %d ",indexPath.row);
        
        cell.backgroundColor = [UIColor whiteColor];
        cell.selectionStyle=UITableViewCellSelectionStyleDefault;
        // hide edit button when online
        cell.btn_CheckboxDelete.hidden = YES;
        cell.view_DisableOffline.hidden = YES;

        OEXHelperVideoDownload *obj = [self.arr_DownloadProgress objectAtIndex:indexPath.row];
        //Progress
        cell.customProgressView.tag = indexPath.row;
        [cell.customProgressView setProgress:(obj.DownloadProgress)/100.0 animated:YES];
        [cell.customProgressView setProgressTintColor:PROGRESSBAR_PROGRESS_TINT_COLOR];
        [cell.customProgressView setTrackTintColor:PROGRESSBAR_TRACK_TINT_COLOR];
        
        //Title
        cell.lbl_Title.text = obj.str_VideoTitle;
        if ([cell.lbl_Title.text length]==0) {
            cell.lbl_Title.text = @"(Untitled)";
        }
        
        //Size and duration
        double size = [obj.size doubleValue];
        float result = ((size/1024)/1024);
        cell.lbl_Size.text = [NSString stringWithFormat:@"%.2fMB",result];
       
        if (!obj.duration)
            cell.lbl_Time.text = @"NA";
        else
            cell.lbl_Time.text = [OEXAppDelegate timeFormatted: [NSString stringWithFormat:@"%.1f", obj.duration]];


        //download button
        cell.btn_Download.tag = indexPath.row;
        [cell.btn_Download addTarget:self action:@selector(startDownloadVideo:) forControlEvents:UIControlEventTouchUpInside];
        
        //Played state
        UIImage * playedImage;
        if (obj.watchedState == OEXPlayedStateWatched) {
            playedImage = [UIImage imageNamed:@"ic_watched.png"];
        }
        else if (obj.watchedState == OEXPlayedStatePartiallyWatched) {
            playedImage = [UIImage imageNamed:@"ic_partiallywatched.png"];
        }
        else {
            playedImage = [UIImage imageNamed:@"ic_unwatched.png"];
        }
        cell.img_VideoWatchState.image = playedImage;
        
        
        if(self.currentTappedVideo==obj && !self.isTableEditing){
            _selectedIndexPath=indexPath;
            [self setSelectedCellAtIndexPath:indexPath tableView:tableView];
            
        }
        
        // MOB - 459
        if(_playbackViewHeightConstraint.constant > 0)
        {
            if (_selectedIndexPath == indexPath)
            {
                cell.btn_Download.hidden = YES;
                cell.customProgressView.hidden = YES;

                if (obj.DownloadProgress > 0)
                {
                    if (obj.DownloadProgress == 100)
                    {
                        cell.customProgressView.hidden = YES;
                    }
                    else
                        cell.customProgressView.hidden = NO;
                }
            }
            else
            {
                if (obj.DownloadProgress > 0)
                {
                    if (obj.DownloadProgress == 100)
                    {
                        cell.customProgressView.hidden = YES;
                    }
                    else
                        cell.customProgressView.hidden = NO;
                    
                    cell.btn_Download.hidden = YES;
                }
                else
                {
                    cell.customProgressView.hidden = YES;
                    cell.btn_Download.hidden = NO;
                }
            }
            
        }
        else
        {
            
            if (obj.DownloadProgress > 0)
            {
                cell.btn_Download.hidden = YES;
                
                if (obj.DownloadProgress == 100)
                {
                    cell.customProgressView.hidden = YES;
                }
                else
                {
                    cell.customProgressView.hidden = NO;
                }
            }
            else
            {
                cell.customProgressView.hidden = YES;
                cell.btn_Download.hidden = NO;
            }
        }

#ifdef __IPHONE_8_0
        if (IS_IOS8)
            [cell setLayoutMargins:UIEdgeInsetsZero];
#endif
        
        return cell;
        
    }
    
}


-(UITableViewCell *)configureOfflineCellFor:(UITableView *)tableView indexPath:(NSIndexPath *)indexPath
{
    
    // in Offline mode
    
    static NSString * cellIndentifier = @"CellCourseVideo";
    OEXCourseVideosTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIndentifier forIndexPath:indexPath];
    NSArray *videos = [self.arr_SubsectionData objectAtIndex:indexPath.section];
    OEXHelperVideoDownload *obj_video = [videos objectAtIndex:indexPath.row];
    cell.lbl_Title.text = obj_video.str_VideoTitle;
    
    if ([cell.lbl_Title.text length]==0) {
        cell.lbl_Title.text = @"(Untitled)";
    }
    
    
    //Calculated Video size
    double size = [obj_video.size doubleValue];
    float result = ((size/1024)/1024);
    cell.lbl_Size.text = [NSString stringWithFormat:@"%.2fMB",result];
    
    
    //Set NA for o lenth video
    if (!obj_video.duration)
        cell.lbl_Time.text = @"NA";
    else
        cell.lbl_Time.text = [OEXAppDelegate timeFormatted: [NSString stringWithFormat:@"%.1f", obj_video.duration]];
    
    //Played state for video
    UIImage * playedImage;
    
    if (obj_video.watchedState == OEXPlayedStateWatched) {
        playedImage = [UIImage imageNamed:@"ic_watched.png"];
    }
    else if (obj_video.watchedState == OEXPlayedStatePartiallyWatched) {
        playedImage = [UIImage imageNamed:@"ic_partiallywatched.png"];
    }
    else {
        playedImage = [UIImage imageNamed:@"ic_unwatched.png"];
    }
    cell.img_VideoWatchState.image = playedImage;
    
    
    
    cell.btn_Download.hidden = YES;
    cell.customProgressView.hidden = YES;
    cell.btn_CheckboxDelete.tag = (indexPath.section * 100) + indexPath.row ;
    cell.view_DisableOffline.hidden = YES;
    
    // Check state to disabled the videos background
    
    if (obj_video.state == OEXDownloadStateComplete)
    {
        cell.backgroundColor = [UIColor whiteColor];
        UIView *backview=[[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 50)];
        [backview setBackgroundColor:SELECTED_CELL_COLOR];
        cell.selectedBackgroundView=backview;
        cell.selectionStyle=UITableViewCellSelectionStyleDefault;
        
        if(self.currentTappedVideo==obj_video && !self.isTableEditing)
        {
            _selectedIndexPath=indexPath;
            [self setSelectedCellAtIndexPath:indexPath tableView:tableView];
        }
    }
    else
    {
        cell.backgroundColor = [UIColor colorWithRed:(float)234/255 green:(float)234/255 blue:(float)237/255 alpha:1.0];
        cell.selectionStyle=UITableViewCellSelectionStyleNone;
        cell.view_DisableOffline.hidden = NO;
    }
    
    // After clicking on Edit button at the bottom
    if (self.isTableEditing)
    {
        // Unhide the checkbox and set the tag
        cell.btn_CheckboxDelete.tag = (indexPath.section * 100) + indexPath.row ;
        [cell.btn_CheckboxDelete addTarget:self action:@selector(selectCheckbox:) forControlEvents:UIControlEventTouchUpInside];
        
        if (obj_video.state == OEXDownloadStateComplete)
        {
            // Videos which can be deleted (downloaded)
            cell.btn_CheckboxDelete.hidden = NO;
        }
        else
        {
            // Videos which cannot be deleted (online)
            cell.btn_CheckboxDelete.hidden = YES;
        }
        
        // Toggle between selected and unselected checkbox
        if (obj_video.isSelected)
        {
            [cell.btn_CheckboxDelete setImage:[UIImage imageNamed:@"ic_checkbox_active.png"] forState:UIControlStateNormal];
        }
        else
        {
            [cell.btn_CheckboxDelete setImage:[UIImage imageNamed:@"ic_checkbox_default.png"] forState:UIControlStateNormal];
        }
        
    }
    else
    {
        cell.btn_CheckboxDelete.hidden = YES;
    }
  
    
#ifdef __IPHONE_8_0
    if (IS_IOS8)
        [cell setLayoutMargins:UIEdgeInsetsZero];
#endif
    
    return cell;
    
    
}

-(void)setSelectedCellAtIndexPath:(NSIndexPath *)indexPath tableView:(UITableView *)tableView{
    
    UITableViewCell *cell=[tableView cellForRowAtIndexPath:indexPath];
    if(_selectedIndexPath==indexPath)
        [cell setSelected:YES animated:YES];
    
    
}

-(void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath{
    
    UIView *backview=[[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 50)];
    [backview setBackgroundColor:SELECTED_CELL_COLOR];
    cell.selectedBackgroundView=backview;
    
    if(indexPath==_selectedIndexPath)
    {
        [cell setSelected:YES animated:NO];
    }
}




- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{    
    _videoPlayerInterface.delegate=self;

    // To avoid showing selected cell index of old video when new video is played
    _dataInterface.selectedCCIndex = -1;
    _dataInterface.selectedVideoSpeedIndex = -1;
    
    
    OEXHelperVideoDownload *obj;
    
    if(_selectedIndexPath!=indexPath)
        [tableView deselectRowAtIndexPath:_selectedIndexPath animated:NO];
    _selectedIndexPath=indexPath;
    
    
    // Check for disabling the prev/Next button on the Video Player
    [self CheckIfFirstVideoPlayed:indexPath];
    [self CheckIfLastVideoPlayed:indexPath];

    
    // handle the frame of table, videoplayer & bottom view
    if (_dataInterface.reachable)
    {
        if (!_isFromGenericView)
        {
            NSArray *videos = [self.arr_SubsectionData objectAtIndex:indexPath.section];
            obj = [videos objectAtIndex:indexPath.row];
        }
        else
            obj = [self.arr_DownloadProgress objectAtIndex:indexPath.row];
        
        
        // Assign this for Analytics
        _dataInterface.selectedVideoUsedForAnalytics = obj;
        
        // To download srt files in the sandbox
        [_dataInterface downloadTranscripts:obj];
        
        
        if (obj.state == OEXDownloadStateComplete)
            [self playVideoFromLocal:obj];
        else
        {
            
            //stop current video
            [_videoPlayerInterface.moviePlayerController stop];
            
        
            [self handleComponentsFrame];
            self.currentVideoURL = [NSURL URLWithString:obj.str_VideoURL];
            self.currentPlayingOnlineURL = obj.str_VideoURL;
            self.currentTappedVideo = obj;
            _isStratingNewVideo=YES;
            

            if([self checkIfVideoFileDownloaded:obj]){
                
                [self playVideoFromLocal:obj];
                
            }else
            {
                if(obj.str_VideoURL==nil || [obj.str_VideoURL isEqualToString:@""]){
                    
                    [[OEXStatusMessageViewController sharedInstance] showMessage:NSLocalizedString(@"VIDEO_CONTENT_NOT_AVAILABLE", nil)
                                                             onViewController:self.view
                                                                     messageY:64
                                                                   components:@[self.customNavView]
                                                                   shouldHide:YES];
                   
                   
                }else{
                    [_dataInterface insertVideoData:obj];
                    [_videoPlayerInterface playVideoFor:obj];
                    
                    // Send Analytics
                    [_dataInterface sendAnalyticsEvents:OEXVideoStatePlay WithCurrentTime:self.videoPlayerInterface.moviePlayerController.currentPlaybackTime];

                }
                
            }

        }
    }
    else
    {
        NSArray *videos = [self.arr_SubsectionData objectAtIndex:indexPath.section];
        obj = [videos objectAtIndex:indexPath.row];
        
        // Assign this for Analytics
        _dataInterface.selectedVideoUsedForAnalytics = obj;
        
        // To download srt files in the sandbox
        [_dataInterface downloadTranscripts:obj];
        
        if (obj.state == OEXDownloadStateComplete)
        {
            //RAHUL
            if (!_isTableEditing)
            {
                [self.table_Videos setContentInset:UIEdgeInsetsMake(0, 0, 0, 0)];
                self.editViewHeightConstraint.constant=0;
                [self playVideoFromLocal:obj];
                
            }
            
            
        }else
        {
            [[OEXStatusMessageViewController sharedInstance] showMessage:NSLocalizedString(@"VIDEO_NOT_AVAILABLE", nil)
                                                     onViewController:self.view
                                                             messageY:64
                                                           components:@[self.customNavView, self.customProgressBarTotal, self.btn_SelectAllEditing, self.btn_Downloads]
                                                           shouldHide:YES];
            
        }
        
    }
    
    [tableView reloadData];
    
}



-(void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath{
    
    
    
}

/*

#pragma mark - TABLEVIEW EDITING delegate

*/


- (void)playVideoFromLocal:(OEXHelperVideoDownload *)obj
{
    [self handleComponentsFrame];
    //stop current video
    [_videoPlayerInterface.moviePlayerController stop];
    NSFileManager *filemgr = [NSFileManager defaultManager];
    NSString *slink = [obj.filePath stringByAppendingPathExtension:@"mp4"];
    if (![filemgr fileExistsAtPath:slink]) {
             [self showAlert:OEXAlertTypePlayBackErrorAlert];
    }
    
    self.currentVideoURL = [NSURL fileURLWithPath:slink];
    self.currentPlayingOnlineURL = obj.str_VideoURL;
    self.currentTappedVideo=obj;
    _isStratingNewVideo=YES;
    [_videoPlayerInterface playVideoFor:obj];
    
    
    // Send Analytics
    [_dataInterface sendAnalyticsEvents:OEXVideoStatePlay WithCurrentTime:self.videoPlayerInterface.moviePlayerController.currentPlaybackTime];

}




- (void)handleComponentsFrame
{
    if (self.playbackViewHeightConstraint.constant != 225) {
        self.playbackViewHeightConstraint.constant = 225;
        self.containerHeightConstraint.constant = 0;
        self.videoPlayerVideoView.alpha = 0;
        [UIView animateWithDuration:ANIMATION_DURATION animations:^{
            self.videoPlayerVideoView.alpha = 1.0;
            [self.view layoutIfNeeded];
        } completion:^(BOOL finished) {
            self.video_containerView.hidden=NO;
        }];
    }
}

- (void)startDownloadVideo:(id)sender
{
    OEXAppDelegate *appD = [[UIApplication sharedApplication] delegate];

    if ([OEXInterface shouldDownloadOnlyOnWifi])
    {
        if (![appD.reachability isReachableViaWiFi])
        {
            [[OEXStatusMessageViewController sharedInstance] showMessage:NSLocalizedString(@"NO_WIFI_MESSAGE", nil)
                                                     onViewController:self.view
                                                             messageY:64
                                                           components:@[self.customNavView, self.customProgressBarTotal, self.btn_SelectAllEditing, self.btn_Downloads]
                                                           shouldHide:YES];
            
            return;
        }
        
    }
    
    
    NSInteger tagValue = [sender tag];
    OEXHelperVideoDownload *obj = [self.arr_DownloadProgress objectAtIndex:tagValue];
    
    
    // Analytics Single Video Download
    if (obj.video_id)
    {
        [OEXAnalytics trackSingleVideoDownload: obj.video_id
                                   CourseID: _dataInterface.selectedCourseOnFront.course_id
                                    UnitURL: _dataInterface.selectedVideoUsedForAnalytics.unit_url];
    }
   
__weak id weakself=self;
   __weak UIButton * button = (UIButton *)sender;
    button.hidden = YES;
    
    if(obj.str_VideoURL==nil || [obj.str_VideoURL isEqualToString:@""]){
       
        [[OEXStatusMessageViewController sharedInstance] showMessage:NSLocalizedString(@"UNABLE_TO_DOWNLOAD", nil)
                                                 onViewController:self.view
                                                         messageY:64
                                                       components:@[self.customNavView, self.customProgressBarTotal, self.btn_SelectAllEditing, self.btn_Downloads]
                                                       shouldHide:YES];
         button.hidden=NO;
         return;
    }
    
    
   [_dataInterface startDownloadForVideo:obj completionHandler:^(BOOL success){
     dispatch_async(dispatch_get_main_queue(), ^{
         [_dataInterface downloadTranscripts:obj];
         
         if(success){
         
         [[OEXStatusMessageViewController sharedInstance] showMessage:NSLocalizedString(@"DOWNLOADING_1_VIDEO", nil)
                                                  onViewController:self.view
                                                          messageY:64
                                                        components:@[self.customNavView, self.customProgressBarTotal, self.btn_SelectAllEditing, self.btn_Downloads]
                                                        shouldHide:YES];
         if(obj.DownloadProgress==100){
             OEXCourseVideosTableViewCell *cell=(OEXCourseVideosTableViewCell *)[self.table_Videos cellForRowAtIndexPath:[NSIndexPath indexPathForRow:tagValue inSection:0]];
             cell.customProgressView.hidden=NO;
             cell.btn_Download.hidden=YES;
             [cell.customProgressView setProgress:100 animated:YES];
             [weakself performSelector:@selector(reloadTableOnMainThread) withObject:nil afterDelay:1.0];
             return ;
           }
         }else{
             
            button.hidden=NO;
         }

         [self reloadTableOnMainThread];
     });
       
       
   }];
    
}

- (void)reloadTableOnMainThread {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.table_Videos reloadData];
    });
}


#pragma mark - Orientation methods

- (void) orientationChanged:(id)object
{
    [[CLPortraitOptionsView sharedInstance] removeSelfFromSuperView];
}


- (BOOL)shouldAutorotate
{
    return YES;
}



#pragma mark - USED WHILE EDITING

- (void)cancelTableClicked:(id)sender
{
    [self.customNavView adjustPositionOfComponentsWithEditingMode:NO isOnline:[_dataInterface reachable]];
    
    // set isSelected to NO for all the objects
    for (NSArray *arr in self.arr_SubsectionData)
    {
        for (OEXHelperVideoDownload *videos in arr)
        {
            videos.isSelected = NO;
        }
    }
    
    
    
    [self.arr_SelectedObjects removeAllObjects];
    
    [self disableDeleteButton];
    
    [self hideComponentsOnEditing:NO];
    [self.table_Videos reloadData];
    
}


- (void)hideComponentsOnEditing:(BOOL)hide
{
    self.isTableEditing = hide;
    self.btn_SelectAllEditing.hidden = !hide;
    
    self.customEditing.btn_Edit.hidden = hide;
    self.customEditing.btn_Cancel.hidden = !hide;
    self.customEditing.btn_Delete.hidden = !hide;
    self.customEditing.imgSeparator.hidden = !hide;
    
    [self.btn_SelectAllEditing setImage:[UIImage imageNamed:@"ic_checkbox_default.png"] forState:UIControlStateNormal];
    self.selectAll = NO;
    
}


- (void)deleteTableClicked:(id)sender
{
    
    if (_arr_SelectedObjects.count > 0) {
        [self showAlert:OEXAlertTypeDeleteConfirmationAlert];
    }
}




- (void)disableDeleteButton
{
    if ([self.arr_SelectedObjects count] == 0)
    {
        self.customEditing.btn_Delete.enabled = NO;
        [self.customEditing.btn_Delete setBackgroundColor:[UIColor darkGrayColor]];
    }
    else
    {
        [self.customEditing.btn_Delete setBackgroundColor:[UIColor clearColor]];
        self.customEditing.btn_Delete.enabled = YES;
    }
}




-(void)deleteSelectedVideos{
    //RAHUL
    NSInteger deleteCount = 0;
    for (OEXHelperVideoDownload *selectedVideo in self.arr_SelectedObjects)
    {
        // make a copy of array to avoid GeneralException(updation of array in loop) - crashes app
        NSMutableArray *arrCopySubsection = [self.arr_SubsectionData copy];
        
        for (NSMutableArray *arr in arrCopySubsection)
        {
            NSMutableArray *arrCopy = [arr copy];
            
            for (OEXHelperVideoDownload *videos in arrCopy)
            {
                if (selectedVideo == videos)
                {
                    videos.state = OEXDownloadStateNew;
                    videos.isVideoDownloading = NO;
                    videos.DownloadProgress = 0.0;
                    
               
                    [[OEXInterface sharedInterface] deleteDownloadedVideoForVideoId:selectedVideo.video_id completionHandler:^(BOOL success) {
                        selectedVideo.state=OEXDownloadStateNew;
                    }];
                    
                    
                    // RAHUL
                    deleteCount++;
                    
                }
            }
        }
        
    }
    
    
    
    
    BOOL isDownloadedVideos = NO;
    
    // Check if no downloaded videos left
    for (NSArray *arr in self.arr_SubsectionData)
    {
        for (OEXHelperVideoDownload *videos in arr)
        {
            if (videos.state == OEXDownloadStateComplete)
            {
                isDownloadedVideos = YES;
                break;
            }
            else
                isDownloadedVideos = NO;
            
        }
    }
    
    
    if (!isDownloadedVideos)
    {
        self.isTableEditing = NO;
        self.btn_SelectAllEditing.hidden = YES;
        self.customEditing.btn_Edit.hidden = NO;
        self.customEditing.btn_Cancel.hidden = YES;
        self.customEditing.btn_Delete.hidden = YES;
        
        ///Hide edit button MOB- 864
        self.editViewHeightConstraint.constant = 0;
    }
    
    
    [self.table_Videos reloadData];
    
    
    // RAHUL
    NSString * sString = @"";
    if (deleteCount > 1) {
        sString = NSLocalizedString(@"s", nil);
    }
    [[OEXStatusMessageViewController sharedInstance] showMessage:[NSString stringWithFormat:@"%ld %@%@ %@", (long)deleteCount, NSLocalizedString(@"VIDEO", nil) , sString, NSLocalizedString(@"DELETED", nil)]
                                             onViewController:self.view
                                                     messageY:64
                                                   components:@[self.customNavView, self.customProgressBarTotal, self.btn_SelectAllEditing, self.btn_Downloads]
                                                   shouldHide:YES];
    
    
//    [self disableDeleteButton];
    [self cancelTableClicked:nil];
}



- (void)editTableClicked:(id)sender
{
    [self.customNavView adjustPositionOfComponentsWithEditingMode:YES isOnline:[_dataInterface reachable]];
    
    self.arr_SelectedObjects = [[NSMutableArray alloc] init];
    
    [self hideComponentsOnEditing:YES];
    
    [self.table_Videos reloadData];
}


- (void)selectCheckbox:(id)sender
{
    NSInteger section = ([sender tag])/100;
    NSInteger row = ([sender tag])%100;
    
    
    NSArray *videos = [self.arr_SubsectionData objectAtIndex:section];
    
    OEXHelperVideoDownload *obj_video = [videos objectAtIndex:row];
    
    // change status of the object and reload table
    
    if (obj_video.isSelected)
    {
        obj_video.isSelected = NO;
        [self.arr_SelectedObjects removeObject:obj_video];
    }
    else
    {
        obj_video.isSelected = YES;
        
        [self.arr_SelectedObjects addObject:obj_video];
    }
    
    [self checkIfAllSelected];
    
    [self.table_Videos reloadData];
    
    [self disableDeleteButton];
    
}

- (void)checkIfAllSelected
{
    // check if all the boxes checked on table then show SelectAll checkbox checked
    
    //RAHUL
    BOOL flagBreaked = NO;
    
    for (NSArray *arr in self.arr_SubsectionData)
    {
        for (OEXHelperVideoDownload *videos in arr)
        {
            if (videos.state == OEXDownloadStateComplete)
            {
                if (!videos.isSelected)
                {
                    self.selectAll = NO;
                    flagBreaked = YES;
                    break;
                }
                else
                    self.selectAll = YES;
            }
            
        }
        
        if (flagBreaked)
            break;
        
    }
    
    
    
    if (self.selectAll)
    {
        [self.btn_SelectAllEditing setImage:[UIImage imageNamed:@"ic_checkbox_active.png"] forState:UIControlStateNormal];
    }
    else
        [self.btn_SelectAllEditing setImage:[UIImage imageNamed:@"ic_checkbox_default.png"] forState:UIControlStateNormal];
    
}

- (IBAction)btn_SelectAllCheckBoxClicked:(id)sender
{
    
    if (self.selectAll)
    {
        // de-select all the videos to delete
        
        self.selectAll = NO;
        [self.btn_SelectAllEditing setImage:[UIImage imageNamed:@"ic_checkbox_default.png"] forState:UIControlStateNormal];
        
        for (NSArray *arr in self.arr_SubsectionData)
        {
            for (OEXHelperVideoDownload *videos in arr)
            {
                if (videos.state == OEXDownloadStateComplete)
                {
                    videos.isSelected = NO;
                    [self.arr_SelectedObjects removeObject:videos];
                    
                }
            }
        }
    }
    else
    {
        // remove all objects to avoids number problem
        [self.arr_SelectedObjects removeAllObjects];
        
        // select all the videos to delete
        
        self.selectAll = YES;
        [self.btn_SelectAllEditing setImage:[UIImage imageNamed:@"ic_checkbox_active.png"] forState:UIControlStateNormal];
        
        for (NSArray *arr in self.arr_SubsectionData)
        {
            for (OEXHelperVideoDownload *videos in arr)
            {
                if (videos.state == OEXDownloadStateComplete)
                {
                    videos.isSelected = YES;
                    [self.arr_SelectedObjects addObject:videos];
                }
            }
        }
    }
    
    [self.table_Videos reloadData];
    
    [self disableDeleteButton];
    
}





#pragma mark play previous video from the list

-(BOOL)checkIfVideoFileDownloaded:(OEXHelperVideoDownload *)video{
    
    NSString *fileUrl=[OEXFileUtility localFilePathForVideoUrl:video.str_VideoURL];
    if([[NSFileManager defaultManager] fileExistsAtPath:fileUrl]){
        return YES;
    }
    
    return NO;

}

- (void)CheckIfFirstVideoPlayed:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0 && indexPath.row == 0)
    {
        // Post notification to hide the next button
        // We are playing the last video
        
        [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_HIDE_PREV_NEXT object:self userInfo:@{KEY_DISABLE_PREVIOUS: @"YES"}];
    }
    else
    {
        // Not the last video id playing.
        [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_HIDE_PREV_NEXT object:self userInfo:@{KEY_DISABLE_PREVIOUS: @"NO"}];
    }
    
}

-(void)playPreviousVideo{
    
    NSIndexPath *indexPath=[self getPreviousVideoIndex];
    if(indexPath && indexPath.row >= 0)
    {
        [self CheckIfFirstVideoPlayed:indexPath];
        [self tableView:self.table_Videos didSelectRowAtIndexPath:indexPath];
    }
}

-(NSIndexPath *)getPreviousVideoIndex
{
    NSIndexPath *indexPath=nil;
    NSIndexPath *currentIndexPath=_selectedIndexPath;
    NSInteger row=currentIndexPath.row;
    NSInteger section=currentIndexPath.section;
  
    NSInteger totalSection=[self.table_Videos numberOfSections];
    if(totalSection<= 0){
        return nil;
    }
    
    // Check for the last video in the list
    if(currentIndexPath.section==0)
    {
        
        if(currentIndexPath.row == 0)
        {
            //NSLog(@"Disable previous button");
            
            return nil;
        }
        else
        {
            indexPath=[NSIndexPath indexPathForRow:row-1 inSection:section];
        }
        
    }
    else
    {
        if (row > 0 )
        {
            indexPath=[NSIndexPath indexPathForRow:row-1 inSection:section];
        }
        else
        {
            NSInteger rowcount=[self.table_Videos numberOfRowsInSection:section-1];
            indexPath=[NSIndexPath indexPathForRow:rowcount-1 inSection:section-1];
        }
    }
    
    
    return indexPath;
    
}


#pragma mark  Implement next video play functionality

- (void)CheckIfLastVideoPlayed:(NSIndexPath *)indexPath
{
    NSInteger totalSections = [self.table_Videos numberOfSections];
    if (totalSections <=0) {
        return;
    }
    // get last index of the table
    NSInteger totalRows = [self.table_Videos numberOfRowsInSection:totalSections-1];
    
    if (indexPath.section == totalSections-1 && indexPath.row == totalRows-1)
    {
        // Post notification to hide the next button
        // We are playing the last video
        [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_HIDE_PREV_NEXT object:self userInfo:@{KEY_DISABLE_NEXT: @"YES"}];
    }
    else
    {
        // Not the last video id playing.
        [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_HIDE_PREV_NEXT object:self userInfo:@{KEY_DISABLE_NEXT: @"NO"}];
    }
    
}




-(void)playNextVideo{
    
    NSIndexPath *indexPath=[self getNextVideoIndex];
    if(indexPath && indexPath.row >= 0)
    {
        [self CheckIfLastVideoPlayed:indexPath];
        [self tableView:self.table_Videos didSelectRowAtIndexPath:indexPath];
    }
}


-(void)showAlertForNextLecture{
    
    
    NSIndexPath *indexPath=[self getNextVideoIndex];
    if(indexPath){
        [self showAlert:OEXAlertTypeNextVideoAlert];
    }
    
}

/// get next video index path

-(NSIndexPath *)getNextVideoIndex{
    
    NSIndexPath *indexPath=nil;
    NSIndexPath *currentIndexPath=[self getCurrentIndexPath];
    NSInteger totalSection=[self.table_Videos numberOfSections];
    if(totalSection<= 0){
        return nil;
    }
    if(currentIndexPath.section>=(totalSection-1)){
        
        NSInteger rowcount=[self.table_Videos numberOfRowsInSection:totalSection-1];
        if(currentIndexPath.row >= rowcount-1){
          return nil;
        }
        
    }
    
    NSInteger row=currentIndexPath.row;
    NSInteger section=currentIndexPath.section;
    
    if(! _dataInterface.reachable){
        
        NSInteger rowcount=[self.table_Videos numberOfRowsInSection:section];
        
        if(row+1 <rowcount){
            
            indexPath=[NSIndexPath indexPathForRow:row+1 inSection:section];
            
        }else{
            
            NSInteger sectionCount=[self.table_Videos numberOfSections];
            
            if(section+1 < sectionCount){
                
                indexPath=[NSIndexPath indexPathForRow:0 inSection:section+1];
                
            }
        }
        
        if(indexPath!=nil){
            
            if([self.arr_SubsectionData count] > indexPath.section){
                
                if([[self.arr_SubsectionData objectAtIndex:indexPath.section] count] > indexPath.row){
                    
                    OEXHelperVideoDownload *video=[[self.arr_SubsectionData  objectAtIndex:indexPath.section]  objectAtIndex:indexPath.row];
                    if(video)
                    {
                        return indexPath;
                    }
                }
            }
            
            return  nil ;
            
        }
        
    }else{
        
        NSInteger rowcount=[self.table_Videos numberOfRowsInSection:section];
        
        if(row+1 <rowcount){
            
            indexPath=[NSIndexPath indexPathForRow:row+1 inSection:section];
            
        }
        
        if(indexPath!=nil){
            
            if([self.arr_DownloadProgress count] > indexPath.row){
                
                OEXHelperVideoDownload *video=[self.arr_DownloadProgress  objectAtIndex:indexPath.row];
                if(video){
                    return indexPath;
                }
                
            }
            
            return nil ;
            
        }
    }
    
    
    return indexPath;
    
}

/// get  current video indexPath

-(NSIndexPath *) getCurrentIndexPath{
    
    if([self.table_Videos numberOfSections] > 1){
        
        for (id  array in self.arr_SubsectionData) {
            
            if( [array containsObject:self.currentTappedVideo]  &&[array isKindOfClass:[NSArray class]] ){
                
                NSInteger row=[array indexOfObject:self.currentTappedVideo];
                NSInteger section=[self.arr_SubsectionData indexOfObject:array];
                return [NSIndexPath indexPathForRow:row inSection:section];
                
            }
            
        }
    }else if ([self.arr_DownloadProgress count]>0  && [self.arr_DownloadProgress containsObject:self.currentTappedVideo]){
        
        NSInteger index=[self.arr_DownloadProgress indexOfObject:self.currentTappedVideo];
        return [NSIndexPath indexPathForRow:index inSection:0];
        
        
    }
    
    
    return [NSIndexPath indexPathForRow:0 inSection:0] ;
    
}


#pragma mark add observer


-(void)addObserver
{
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(orientationChanged:) name:@"UIDeviceOrientationDidChangeNotification" object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playNextVideo) name:NOTIFICATION_NEXT_VIDEO object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playPreviousVideo) name:NOTIFICATION_PREVIOUS_VIDEO object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(showCCPortrait:)
                                                 name:NOTIFICATION_OPEN_CC_PORTRAIT object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reachabilityDidChange:) name:kReachabilityChangedNotification object:nil];
    
    
    //Listen to notification
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(downloadProgressNotification:) name:DOWNLOAD_PROGRESS_NOTIFICATION object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(playbackStateChanged:)
                                                 name:MPMoviePlayerPlaybackStateDidChangeNotification object:_videoPlayerInterface.moviePlayerController];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(playbackEnded:)
                                                 name:MPMoviePlayerPlaybackDidFinishNotification object:_videoPlayerInterface.moviePlayerController];

    
    //Add oserver
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateTotalDownloadProgress:) name:TOTAL_DL_PROGRESS object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(movieLoadStateDidChange:) name:MPMoviePlayerLoadStateDidChangeNotification object:_videoPlayerInterface.moviePlayerController];
    
}


-(void)removeObserver
{

   //NSLog(@"self.videoPlayerInterface.moviePlayerController : %ld",(long)self.videoPlayerInterface.moviePlayerController.loadState);
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NOTIFICATION_NEXT_VIDEO object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NOTIFICATION_PREVIOUS_VIDEO object:nil];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:TOTAL_DL_PROGRESS object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NOTIFICATION_OPEN_CC_PORTRAIT object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self  name:DOWNLOAD_PROGRESS_NOTIFICATION object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self  name:kReachabilityChangedNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self    name:MPMoviePlayerPlaybackStateDidChangeNotification object:_videoPlayerInterface.moviePlayerController];
    [[NSNotificationCenter defaultCenter] removeObserver:self    name:MPMoviePlayerPlaybackDidFinishNotification object:_videoPlayerInterface.moviePlayerController];
    [[NSNotificationCenter defaultCenter] removeObserver:self    name:MPMoviePlayerLoadStateDidChangeNotification object:_videoPlayerInterface.moviePlayerController];
    
}

#pragma mark plyer notification methods


- (void)playbackStateChanged:(NSNotification *)notification
{
    
    switch ([_videoPlayerInterface.moviePlayerController playbackState])
    {
            
        case MPMoviePlaybackStateStopped:
        {
            
            
           //NSLog(@"Stopped");
        }break;
            
        case MPMoviePlaybackStatePlaying:
         if(self.navigationController.topViewController != self)
            {
                [self.videoPlayerInterface.moviePlayerController pause];
            }
            break;
        case MPMoviePlaybackStatePaused:
            
            
           
           //NSLog(@"Paused");
            break;
        case MPMoviePlaybackStateInterrupted:
           //NSLog(@"Interrupted");
            break;
        case MPMoviePlaybackStateSeekingForward:
           //NSLog(@"Seeking Forward");
            break;
        case MPMoviePlaybackStateSeekingBackward:
           //NSLog(@"Seeking Backward");
            break;
        default:
            break;
    }
    
    
    
    NSInteger reason = [[notification.userInfo objectForKey:MPMoviePlayerPlaybackDidFinishReasonUserInfoKey] integerValue];
    if (reason == MPMovieFinishReasonUserExited) {
       //NSLog(@"THIS HAPPENS FOUR TIMES every time the movie ends");
    }
    
}




- (void)playbackEnded:(NSNotification *)notification
{
    
    
    int reason = [[[notification userInfo] valueForKey:MPMoviePlayerPlaybackDidFinishReasonUserInfoKey] intValue];
    
    if (reason == MPMovieFinishReasonPlaybackEnded) {
        
        int  currentTime=self.videoPlayerInterface.moviePlayerController.currentPlaybackTime;
        int  totalTime=self.videoPlayerInterface.moviePlayerController.duration;
        if(currentTime==totalTime && totalTime > 0 )
        {
            [_dataInterface markLastPlayedInterval:0.0 forVideo:_currentTappedVideo];
            self.videoPlayerInterface.moviePlayerController.currentPlaybackTime=0.0;
             _currentTappedVideo.watchedState = OEXPlayedStateWatched;
            [_dataInterface markVideoState:OEXPlayedStateWatched
                              forVideo:_currentTappedVideo];
            [self.table_Videos reloadData];
    
        }else{
            
        }
        
        
    }else if (reason == MPMovieFinishReasonUserExited) {
       
        
    }else if (reason == MPMovieFinishReasonPlaybackError) {
        if (_dataInterface.reachable)
        {
            if(_currentTappedVideo.state == OEXDownloadStateNew || _currentTappedVideo.state == OEXDownloadStatePartial)
            {
                _videoPlayerInterface.delegate=nil;
                
                [self showAlert:OEXAlertTypePlayBackContentUnAvailable];
            }
        }
        
    }
}



- (void)movieLoadStateDidChange:(NSNotification *)note
{
    //NSLog(@"State changed to: %d\n", _videoPlayerInterface.moviePlayerController.loadState);
    
    switch (_videoPlayerInterface.moviePlayerController.loadState)
    {
        case MPMovieLoadStatePlayable:
        case MPMovieLoadStatePlaythroughOK:
            if(self.table_Videos){
                if (_currentTappedVideo.watchedState != OEXPlayedStateWatched){
                    if (_currentTappedVideo.watchedState != OEXPlayedStatePartiallyWatched)
                        [_dataInterface markVideoState:OEXPlayedStatePartiallyWatched
                                          forVideo:_currentTappedVideo];
                    _currentTappedVideo.watchedState = OEXPlayedStatePartiallyWatched;
                }
                [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                    [_table_Videos reloadData];
                }];
            }
            break;
        case MPMovieLoadStateStalled:{
           //NSLog(@"STALLED");
            if(_videoPlayerInterface.moviePlayerController.duration==_videoPlayerInterface.moviePlayerController.currentPlaybackTime){
            }
            break;
        }
        case MPMovieLoadStateUnknown:
           //NSLog(@"UNLNOWN");
            break;
        default:
            break;
    }
}



- (void)downloadProgressNotification:(NSNotification *)notification
{
    
    NSDictionary *progress = (NSDictionary *)notification.userInfo;
    NSURLSessionTask * task = [progress objectForKey:DOWNLOAD_PROGRESS_NOTIFICATION_TASK];
    NSString *url = [task.originalRequest.URL absoluteString];
    
    for (OEXHelperVideoDownload * video in _arr_DownloadProgress) {
        if ([video.str_VideoURL isEqualToString:url]) {
            [self.table_Videos reloadData];
            break;
        }
    }
    
    
}


#pragma alertview delegeate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    
    
    if(alertView.tag==1000) //Delete Videos
    {
        
        if (buttonIndex == 1)
        {
            [self deleteSelectedVideos];
        }
        _confirmAlert=nil;
    }
    else if(alertView.tag==1001) //Play next video
    {
        if(buttonIndex==1){
            
            [self playNextVideo];
            
        }
    }else if(alertView.tag==1002){
        
        
        
    }else if (alertView.tag==1003 || alertView.tag==1004 || alertView.tag==1005){
        
        
        
    }
    
    
    if(self.alertCount > 0){
        
        self.alertCount=_alertCount-1;
        
    }
    
    if(self.alertCount==0){
        
        [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
        [_videoPlayerInterface setShouldRotate:YES];
        [_videoPlayerInterface orientationChanged:nil];
        
    }
    
    
}


#pragma mark videoPlayer Delegate

-(void)movieTimedOut{
    
    if(!_videoPlayerInterface.moviePlayerController.isFullscreen){
        
        [[OEXStatusMessageViewController sharedInstance] showMessage:NSLocalizedString(@"TIMEOUT_CHECK_INTERNET_CONNECTION", nil)
                                                 onViewController:self.view
                                                         messageY:64
                                                       components:@[self.customNavView, self.customProgressBarTotal, self.btn_SelectAllEditing, self.btn_Downloads]
                                                       shouldHide:YES];
        
        [_videoPlayerInterface.moviePlayerController stop];
        
        
    }else{
        
        [self showAlert:OEXAlertTypeVideoTimeOutAlert];
        
    }
    
    
}

-(void)showAlert:(OEXAlertType )OEXAlertType{
    
    self.alertCount=_alertCount+1;
    
    if(self.alertCount>=1){
        
        [[UIDevice currentDevice] endGeneratingDeviceOrientationNotifications];
        [_videoPlayerInterface setShouldRotate:NO];
        
    }
    
    switch (OEXAlertType) {
            
        case OEXAlertTypeDeleteConfirmationAlert:{
            
            
            NSString * sString = NSLocalizedString(@"THIS_VIDEO", nil);
            if (_arr_SelectedObjects.count > 1) {
                sString = NSLocalizedString(@"THESE_VIDEOS", nil);
            }
            _confirmAlert= [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"CONFIRM_DELETE_TITLE", nil)
                                                           message:[NSString stringWithFormat:@"%@ %@", NSLocalizedString(@"CONFIRM_DELETE_MESSAGE", nil), sString]
                                                          delegate:self
                                                 cancelButtonTitle:NSLocalizedString(@"CANCEL", nil)
                                                 otherButtonTitles:NSLocalizedString(@"DELETE", nil), nil];
            _confirmAlert.tag=1000;
            [_confirmAlert show];
            
        }
            
            break;
            
            
        case OEXAlertTypeNextVideoAlert:{
            
            UIAlertView *alert=[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"PLAYBACK_COMPLETE_TITLE", nil)
                                                          message:NSLocalizedString(@"PLAYBACK_COMPLETE_MESSAGE", nil)
                                                         delegate:self
                                                cancelButtonTitle:NSLocalizedString(@"PLAYBACK_COMPLETE_CONTINUE_CANCEL", nil)
                                                otherButtonTitles:NSLocalizedString(@"PLAYBACK_COMPLETE_CONTINUE", nil), nil];
            alert.tag=1001;
            alert.delegate=self;
            [alert show];
            
            
        }
            break;
            
        case OEXAlertTypePlayBackErrorAlert:{
            
            UIAlertView *alert=[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"VIDEO_CONTENT_NOT_AVAILABLE", nil)
                                                          message:nil
                                                         delegate:self
                                                cancelButtonTitle:NSLocalizedString(@"CLOSE", nil)
                                                otherButtonTitles:nil, nil] ;
            
            alert.tag=1002;
            [alert show];
            
            
        }
            
            break;
            
            
        case OEXAlertTypeVideoTimeOutAlert:{
            
            UIAlertView *alert= [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"TIMEOUT", nil)
                                                           message:NSLocalizedString(@"TIMEOUT_CHECK_INTERNET_CONNECTION", nil)
                                                          delegate:self
                                                 cancelButtonTitle:@"Ok"
                                                 otherButtonTitles:nil];
            alert.tag=1003;
            [alert show];
            
        }
            break;
            
            
            
        case OEXAlertTypePlayBackContentUnAvailable:
        {
            
            UIAlertView *alert= [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"VIDEO_CONTENT_NOT_AVAILABLE", nil)
                                                           message:nil
                                                          delegate:self
                                                 cancelButtonTitle:NSLocalizedString(@"CLOSE", nil)
                                                 otherButtonTitles:nil];
            alert.tag=1004;
            [alert show];
            
            
        }
            break;
            
        default:
            break;
    }
    
    
    
}




@end
