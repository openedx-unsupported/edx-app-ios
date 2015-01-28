//
//  OEXMyVideosViewController.m
//  edXVideoLocker
//
//  Created by Rahul Varma on 27/06/14.
//  Copyright (c) 2014 edX. All rights reserved.
//

#import "OEXMyVideosViewController.h"

#import "CLPortraitOptionsView.h"
#import "OEXAppDelegate.h"
#import "OEXCourse.h"
#import "OEXConfig.h"
#import "OEXCourseVideosTableViewCell.h"
#import "OEXCustomLabel.h"
#import "OEXDateFormatting.h"
#import "OEXDownloadViewController.h"
#import "OEXEnvironment.h"
#import "OEXInterface.h"
#import "OEXFrontTableViewCell.h"
#import "OEXHelperVideoDownload.h"
#import "OEXMyVideosSubSectionViewController.h"
#import "OEXNetworkConstants.h"
#import "OEXStatusMessageViewController.h"
#import "OEXTabBarItemsCell.h"
#import "OEXVideoPathEntry.h"
#import "OEXVideoPlayerInterface.h"
#import "OEXVideoSummary.h"
#import "Reachability.h"
#import "SWRevealViewController.h"


#define RECENT_HEADER_HEIGHT 30.0
#define ALL_HEADER_HEIGHT 8.0
#define MOVE_OFFLINE_X 35.0
#define MOVE_TITLE_X 10.0
#define EDIT_BUTTON_HEIGHT 50.0
#define SHIFT_LEFT 40.0
#define VIDEO_VIEW_HEIGHT  225
#define ORIGINAL_RIGHT_SPACE_PROGRESSBAR 8
#define ORIGINAL_RIGHT_SPACE_OFFLINE 15

typedef  enum OEXAlertType {
    OEXAlertTypeNextVideoAlert,
    OEXAlertTypeDeleteConfirmationAlert,
    OEXAlertTypePlayBackErrorAlert,
    OEXAlertTypeCannotPlayVideo,
    OEXAlertTypeVideoTimeOutAlert,
    OEXAlertTypePlayBackContentUnAvailable
    
}OEXAlertType;


@interface OEXMyVideosViewController ()
{
    NSInteger cellSelectedIndex;
    NSIndexPath *clickedIndexpath;
}

@property (nonatomic, strong) NSMutableArray * arr_CourseData;
@property (nonatomic , strong) NSMutableArray *arr_SubsectionData;
@property(nonatomic)NSInteger alertCount;
@property (nonatomic, strong) OEXInterface * dataInterface;
@property(strong,nonatomic)OEXVideoPlayerInterface *videoPlayerInterface;
@property(strong,nonatomic)OEXHelperVideoDownload *currentTappedVideo;
@property(strong,nonatomic)NSURL *currentVideoURL;
@property(nonatomic,strong)NSIndexPath *selectedIndexPath;
@property(nonatomic , assign) BOOL isTableEditing;
@property(nonatomic , assign) BOOL selectAll;
@property (nonatomic , strong) NSMutableArray *arr_SelectedObjects;
@property (nonatomic, assign) BOOL isShifted;

@property (weak, nonatomic) IBOutlet UILabel *lbl_NoVideo;
@property (weak ,nonatomic) IBOutlet UIView *recentVideoView;
@property   (weak,nonatomic)IBOutlet UIView *recentVideoPlayBackView;
@property (weak, nonatomic) IBOutlet OEXCustomLabel *lbl_videoHeader;
@property (weak, nonatomic) IBOutlet OEXCustomLabel *lbl_videobottom;
@property (weak,nonatomic)  IBOutlet OEXCustomLabel *lbl_section;
@property (weak, nonatomic) IBOutlet UIView  *video_containerView;
@property (strong,nonatomic)IBOutlet NSLayoutConstraint *videoViewHeight;
@property   (weak,nonatomic)IBOutlet UIView *videoVideo;
@property(nonatomic,strong)IBOutlet NSLayoutConstraint *recentEditViewHeight;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *TrailingSpaceCustomProgress;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *TrailingSpaceOffline;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *ConstraintRecentTop;
@property (weak, nonatomic) IBOutlet UIView *view_NavBG;

@property (weak, nonatomic) IBOutlet UIView *view_Offline;
@property (weak, nonatomic) IBOutlet UITableView *table_MyVideos;
@property (weak, nonatomic) IBOutlet UIButton *btn_LeftNavigation;
@property (weak, nonatomic) IBOutlet DACircularProgressView *customProgressView;
@property (weak, nonatomic) IBOutlet UIButton *btn_Download;
@property (weak, nonatomic) IBOutlet UIButton *overlayButton;
@property (weak, nonatomic) IBOutlet UILabel *lbl_NavTitle;
@property (weak, nonatomic) IBOutlet UIView *tabView;
@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;
@property (weak, nonatomic) IBOutlet UITableView *table_RecentVideos;
@property (weak, nonatomic) IBOutlet UIButton *btn_Downloads;
@property (weak, nonatomic) IBOutlet UILabel *lbl_Offline;
@property (weak, nonatomic) IBOutlet UIButton *btn_SelectAllEditing;
@property (weak, nonatomic) IBOutlet OEXCustomEditingView *customEditing;
@end



@implementation OEXMyVideosViewController

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if([[segue  identifier] isEqualToString:@"DownloadControllerSegue"])
    {
        OEXDownloadViewController *obj_download = (OEXDownloadViewController *)[segue destinationViewController];
        obj_download.isFromFrontViews = YES;
    }
}

#pragma mark - REACHABILITY

- (void)HideOfflineLabel:(BOOL)isOnline
{
    self.lbl_Offline.hidden = isOnline;
    self.view_Offline.hidden = isOnline;

    if (self.isTableEditing)
    {
        if (!isOnline)
            self.lbl_NavTitle.textAlignment = NSTextAlignmentLeft;
        
    }else
        self.lbl_NavTitle.textAlignment = NSTextAlignmentCenter;

}



- (void)reachabilityDidChange:(NSNotification *)notification
{
    Reachability *reachability = (Reachability *)[notification object];
    
    if ([reachability isReachable])
    {
        _dataInterface.reachable = YES;
        [self HideOfflineLabel:YES];
        
    } else {
        
        _dataInterface.reachable = NO;
        [self HideOfflineLabel:NO];
        
    }
}



- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    // Add Observer
    [self addObservers];

    // Only if video is playing.
    if (cellSelectedIndex==1)
    {
        [self addPlayerObserver];
    }
    
    // Populate My Videos View data
    self.lbl_NoVideo.hidden = YES;
    self.lbl_NoVideo.text = NSLocalizedString(@"NO_VIDEOS_DOWNLOADED", nil);
    [self getMyVideosTableData];

    
    if(!_videoPlayerInterface){
    
        //Initiate player object
        self.videoPlayerInterface = [[OEXVideoPlayerInterface alloc] init];
        _videoPlayerInterface.videoPlayerVideoView = self.videoVideo;
        
    }
    
    if (_videoPlayerInterface) {
        [self.videoPlayerInterface videoPlayerShouldRotate];
    }
    _isShifted = NO;
    
    //While editing goto downloads then comes back Progressview overlaps checkbox.
    // To avoid this check this.
    if (_isTableEditing)
    {
        self.TrailingSpaceCustomProgress.constant = ORIGINAL_RIGHT_SPACE_PROGRESSBAR + SHIFT_LEFT;
        self.TrailingSpaceOffline.constant = ORIGINAL_RIGHT_SPACE_OFFLINE + MOVE_OFFLINE_X;
        self.lbl_NavTitle.textAlignment = NSTextAlignmentLeft;

    }
    else
    {
        self.TrailingSpaceOffline.constant = ORIGINAL_RIGHT_SPACE_OFFLINE;

        self.lbl_NavTitle.textAlignment = NSTextAlignmentCenter;

        if (self.videoViewHeight.constant == 225)
        {
            [self.recentEditViewHeight setConstant:0.0f];
        }

    }
    
    
    
    
    // Check Reachability for OFFLINE
    if (_dataInterface.reachable)
    {
        [self HideOfflineLabel:YES];
    }
    else
    {
        [self HideOfflineLabel:NO];
    }
    
   
    self.navigationController.navigationBarHidden = YES;


    
    self.table_RecentVideos.separatorInset = UIEdgeInsetsZero;
#ifdef __IPHONE_8_0
    if (IS_IOS8)
        [self.table_RecentVideos setLayoutMargins:UIEdgeInsetsZero];
#endif

}

-(void)removeAllObserver{
    
    [_videoPlayerInterface resetPlayer];
    _videoPlayerInterface.moviePlayerController=nil;
    _videoPlayerInterface.videoPlayerVideoView=nil;
    [_videoPlayerInterface resetPlayer];
    _videoPlayerInterface=nil;
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
}

- (void)addObservers
{
    
  
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(downloadCompleteNotification:)
                                                 name:VIDEO_DL_COMPLETE object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateTotalDownloadProgress:) name:TOTAL_DL_PROGRESS object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reachabilityDidChange:) name:kReachabilityChangedNotification object:nil];
    
    

}



- (void)leftNavigationBtnClicked
{
    //Hide overlay
    self.overlayButton.hidden = NO;
    [_videoPlayerInterface setShouldRotate:NO];
    [_videoPlayerInterface.moviePlayerController pause];
    [_videoPlayerInterface.moviePlayerController.view setUserInteractionEnabled:NO];
    [self performSelector:@selector(call) withObject:nil afterDelay:0.2];
}

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event{
    
}

-(void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event{
    
}

-(void)call
{
    [self.revealViewController revealToggle:self.btn_LeftNavigation];
}

- (void)leftNavigationTapDown
{
    self.overlayButton.hidden = NO;
    [self.navigationController popToViewController:self animated:NO];
    [UIView animateWithDuration:0.9 delay:0 options:0 animations:^{
        self.overlayButton.alpha = 0.5f;
    } completion:^(BOOL finished) {
        
    }];
    
}



- (void)viewDidLoad
{
    [super viewDidLoad];
    self.videoViewHeight.constant=0;
    
    // Do any additional setup after loading the view.
    //Hide back button
    [self.navigationItem setHidesBackButton:YES];
    [self.navigationController.navigationBar setTranslucent:NO];
    
    //Set exclusive touch for all buttons
    self.btn_LeftNavigation.exclusiveTouch=YES;
    self.videoVideo.exclusiveTouch=YES;
    self.table_RecentVideos.exclusiveTouch=YES;
    self.table_MyVideos.exclusiveTouch=YES;
    
    self.overlayButton.alpha = 0.0f;

    //set navigation title font
    self.lbl_NavTitle.font = [UIFont fontWithName:@"OpenSans-Semibold" size:16.0];
    
    // Initialize array of data to show on table
    self.arr_SubsectionData = [[NSMutableArray alloc] init];
    
    // Initialize the interface for API calling
    self.dataInterface = [OEXInterface sharedInterface];
    
    //Add custom button for drawer
    [self.btn_LeftNavigation addTarget:self action:@selector(leftNavigationBtnClicked) forControlEvents:UIControlEventTouchUpInside];
    [self.btn_LeftNavigation addTarget:self action:@selector(leftNavigationTapDown) forControlEvents:UIControlEventTouchUpInside];

    self.revealViewController.delegate = self;
    
    
    [self.view addGestureRecognizer:self.revealViewController.panGestureRecognizer];
    
    
    //set custom progress bar properties
    [self.customProgressView setProgressTintColor:PROGRESSBAR_PROGRESS_TINT_COLOR];
    [self.customProgressView setTrackTintColor:PROGRESSBAR_TRACK_TINT_COLOR];
    [self.customProgressView setProgress:_dataInterface.totalProgress animated:YES];

    
    //Fix for 20px issue for the table view
    self.automaticallyAdjustsScrollViewInsets = NO;
    [self.table_MyVideos setContentInset:UIEdgeInsetsMake(0, 0, 8, 0)];

    [[self.dataInterface progressViews] addObject:self.customProgressView];
    [[self.dataInterface progressViews] addObject:self.btn_Downloads];
    [self.customProgressView setHidden:YES];
    [self.btn_Downloads setHidden:YES];
    [self.dataInterface setNumberOfRecentDownloads:0];
    
    // Used for autorotation
    [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(orientationChanged:) name:@"UIDeviceOrientationDidChangeNotification" object:nil];

    // Show Custom editing View
    [self.customEditing.btn_Edit addTarget:self action:@selector(editTableClicked:) forControlEvents:UIControlEventTouchUpInside];
    [self.customEditing.btn_Delete addTarget:self action:@selector(deleteTableClicked:) forControlEvents:UIControlEventTouchUpInside];
    [self.customEditing.btn_Cancel addTarget:self action:@selector(cancelTableClicked:) forControlEvents:UIControlEventTouchUpInside];
    self.btn_SelectAllEditing.hidden = YES;
    self.isTableEditing = NO;     // Check Edit button is clicked
    self.selectAll = NO;     // Check if all are selected

    
    [self performSelector:@selector(reloadTable) withObject:self afterDelay:5.0];
    //Analytics Screen record
    [OEXAnalytics screenViewsTracking: @"My Videos - All Videos"];
    
}

- (void)reloadTable
{
    [self.table_MyVideos reloadData];
}

#pragma update total download progress

- (void)downloadCompleteNotification:(NSNotification *)notification
{
    NSDictionary * dict = notification.userInfo;
    
    NSURLSessionTask * task = [dict objectForKey:VIDEO_DL_COMPLETE_N_TASK];
    NSURL * url = task.originalRequest.URL;
    
    if ([OEXInterface isURLForVideo:url.absoluteString]) {
        [self getMyVideosTableData];
    }
}

-(void)updateTotalDownloadProgress:(NSNotification * )notification{
    
    [self.customProgressView setProgress:_dataInterface.totalProgress animated:YES];
    
}


- (void)getMyVideosTableData
{
    // Initialize array
    self.arr_CourseData = [[NSMutableArray alloc] init];

    NSMutableArray *arrCourseAndVideo = [[NSMutableArray alloc] initWithArray: [_dataInterface coursesAndVideosForDownloadState:OEXDownloadStateComplete] ];
 
    // Populate both ALL & RECENT Videos Table data
    for (NSDictionary *dict in arrCourseAndVideo)
    {
        NSMutableDictionary *mutableDict=[dict mutableCopy];
        
        NSString *strSize = [[NSString alloc] initWithString: [self calculateVideosSizeInCourse:[mutableDict objectForKey:CAV_KEY_VIDEOS]] ];
        NSMutableArray * sortedArray = [mutableDict objectForKey:CAV_KEY_VIDEOS];
        NSSortDescriptor *sortDesc = [[NSSortDescriptor alloc] initWithKey:@"completedDate" ascending:NO selector:@selector(compare:)];
        [sortedArray sortUsingDescriptors:[NSArray arrayWithObject:sortDesc]];
        NSMutableArray *arr_SortedArray = [sortedArray mutableCopy];
        NSDictionary *videos = @{CAV_KEY_COURSE: [mutableDict objectForKey:CAV_KEY_COURSE],
                                 CAV_KEY_VIDEOS: [mutableDict objectForKey:CAV_KEY_VIDEOS],
                                 CAV_KEY_RECENT_VIDEOS: arr_SortedArray,
                                 CAV_KEY_VIDEOS_SIZE: strSize};
        
        [self.arr_CourseData addObject:videos];
        
    }
    
    [self cancelTableClicked:nil];
    [self.table_MyVideos reloadData];
    [self.table_RecentVideos reloadData];
    
    if([self.arr_CourseData count] == 0)
    {
        self.lbl_NoVideo.hidden = NO;
        self.table_RecentVideos.hidden = YES;
        [self.recentEditViewHeight setConstant:0.0];

    }
    else
    {
        self.lbl_NoVideo.hidden = YES;
        self.table_RecentVideos.hidden = NO;

        if (self.videoViewHeight.constant == 225)
        {
            [self.recentEditViewHeight setConstant:0.0f];
        }
        else
            [self.recentEditViewHeight setConstant:EDIT_BUTTON_HEIGHT];
    }

}



- (NSString *)calculateVideosSizeInCourse:(NSArray *)arrvideo
{
    NSString *strSize = nil;
    
    double size = 0.0;
    
    for (OEXHelperVideoDownload *video in arrvideo)
    {
        double videoSize = [video.summary.size doubleValue];
        double sizeInMegabytes = (videoSize / 1024) / 1024;
        size += sizeInMegabytes;
    }
    
    strSize = [NSString stringWithFormat:@"%.2fMB",size];
    
    
    return strSize;
}





#pragma mark - Show CC options in portrait mode

- (void)showCCPortrait:(NSNotification *)notification
{
    NSDictionary *dict = notification.userInfo;
    [[CLPortraitOptionsView sharedInstance] addValueToArray:dict];
    [[CLPortraitOptionsView sharedInstance] addViewToContainerSuperview:self.view];
}



#pragma mark TableViewDataSourceDelegate

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (tableView == self.table_MyVideos) {
        return 1;
    }
    else{
        
        _selectedIndexPath=nil;
        
        return [[[self.arr_CourseData objectAtIndex:section] objectForKey:CAV_KEY_RECENT_VIDEOS] count];
        
    }
    return 1;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    if (tableView == self.table_MyVideos)
    {
        UIView *headerview = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, ALL_HEADER_HEIGHT)];
        headerview.backgroundColor = GREY_COLOR;
        return headerview;
    }
    else
    {
        
        NSDictionary *dictVideo = [self.arr_CourseData objectAtIndex:section];
        OEXCourse *obj_course = [dictVideo objectForKey:CAV_KEY_COURSE];
        
        UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, RECENT_HEADER_HEIGHT )];
        view.backgroundColor = GREY_COLOR;
        
        UILabel *courseTitle = [[UILabel alloc] initWithFrame:CGRectMake(20, 0, 300, RECENT_HEADER_HEIGHT)];
        courseTitle.numberOfLines = 2;
        courseTitle.text = obj_course.name;
        courseTitle.font = [UIFont fontWithName:@"OpenSans-Semibold" size:14.0f];
        courseTitle.textColor = [UIColor colorWithRed:69.0/255.0 green:73.0/255.0 blue:81.0/255.0 alpha:1.0];
        [view addSubview:courseTitle];
        
        return view;
        
    }
    return nil;
    
}


- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    if (tableView == self.table_MyVideos)
    {
        return ALL_HEADER_HEIGHT;
    }
    else
    {
        return RECENT_HEADER_HEIGHT;
    }

}



- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return [self.arr_CourseData count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    if (tableView == self.table_MyVideos)
    {
        static NSString * cellIndentifier = @"PlayerCell";

        OEXFrontTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIndentifier];
        
        NSDictionary *dictVideo = [self.arr_CourseData objectAtIndex:indexPath.section];
        
        OEXCourse *obj_course = [dictVideo objectForKey:CAV_KEY_COURSE];
        
        cell.lbl_Title.text = obj_course.name;
        
        cell.lbl_Subtitle.text =  [NSString stringWithFormat:@"%@ | %@", obj_course.org, obj_course.number]; // Show course ced
        
        if (obj_course.imageDataCourse && [obj_course.imageDataCourse length]>0)
        {
            cell.img_Course.image = [UIImage imageWithData:obj_course.imageDataCourse];
        }
        else
        {
            
            // MOB - 448
            //Background image
            
            if (obj_course.imageDataCourse && [obj_course.imageDataCourse length]>0)
            {
                cell.img_Course.image = [UIImage imageWithData:obj_course.imageDataCourse];
            }
            else
            {
                
                NSString *imgURLString = [NSString stringWithFormat:@"%@%@", [OEXEnvironment shared].config.apiHostURL, obj_course.course_image_url];
                NSData * imageData = [_dataInterface resourceDataForURLString:imgURLString downloadIfNotAvailable:NO];
                
                if (imageData && imageData.length>0)
                {
                    cell.img_Course.image = [UIImage imageWithData:imageData];
                }
                else
                {
                    cell.img_Course.image = [UIImage imageNamed:@"Splash_map.png"];
                    [_dataInterface downloadWithRequestString:[NSString stringWithFormat:@"%@%@", [OEXEnvironment shared].config.apiHostURL, obj_course.course_image_url]  forceUpdate:YES];
                }
                
            }
            
        }
        
        // here lbl_Stating is used for showing the no.of videos and total size
        NSInteger count = [[dictVideo objectForKey:CAV_KEY_VIDEOS] count];
        NSString *Vcount = nil;
        if (count == 1)
        {
            Vcount = [NSString stringWithFormat:@"%ld Video",(long)count];
        }
        else
            Vcount = [NSString stringWithFormat:@"%ld Videos",(long)count];
        
        cell.lbl_Starting.text = [NSString stringWithFormat:@"%@, %@", Vcount ,[dictVideo objectForKey:CAV_KEY_VIDEOS_SIZE]];
        
        return cell;

    }
    else    // table_Recent
    {
        static NSString * cellIndentifier = @"CellCourseVideo";

        OEXCourseVideosTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIndentifier];
        cell.btn_Download.hidden = YES;
        NSArray *videos = [[self.arr_CourseData objectAtIndex:indexPath.section] objectForKey:CAV_KEY_RECENT_VIDEOS];
        OEXHelperVideoDownload *obj_video = [videos objectAtIndex:indexPath.row];
        
        cell.lbl_Title.text = obj_video.summary.name;

        if ([cell.lbl_Title.text length]==0) {
            cell.lbl_Title.text = @"(Untitled)";
        }
        
        double size = [obj_video.summary.size doubleValue];
        float result = ((size/1024)/1024);
        cell.lbl_Size.text = [NSString stringWithFormat:@"%.2fMB",result];

        if (!obj_video.summary.duration)
            cell.lbl_Time.text = @"NA";
        else
            cell.lbl_Time.text = [OEXDateFormatting formatSecondsAsVideoLength: obj_video.summary.duration];
        
        


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
        

        // WHILE EDITING
        if (self.isTableEditing)
        {
            // Unhide the checkbox and set the tag
            cell.btn_CheckboxDelete.hidden = NO;
            cell.btn_CheckboxDelete.tag = (indexPath.section * 100) + indexPath.row ;
            [cell.btn_CheckboxDelete addTarget:self action:@selector(selectCheckbox:) forControlEvents:UIControlEventTouchUpInside];

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
            if(self.currentTappedVideo==obj_video && !self.isTableEditing){
                [self setSelectedCellAtIndexPath:indexPath tableView:tableView];
                _selectedIndexPath=indexPath;
                
            }

        }
 
        
#ifdef __IPHONE_8_0
        if (IS_IOS8)
            [cell setLayoutMargins:UIEdgeInsetsZero];
#endif
        
        return cell;
    }
    
    return nil;
}


-(void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath{
    
    if(tableView==self.table_RecentVideos){
        
    UIView *backview=[[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 50)];
    [backview setBackgroundColor:SELECTED_CELL_COLOR];
    cell.selectedBackgroundView=backview;
    if(indexPath==_selectedIndexPath){
        [cell setSelected:YES animated:NO];
    }
  }
    
}


-(void)setSelectedCellAtIndexPath:(NSIndexPath *)indexPath tableView:(UITableView *)tableView{
    
    UITableViewCell *cell=[tableView cellForRowAtIndexPath:indexPath];
    [cell setSelected:YES animated:YES];
    
}

#pragma mark TableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // To avoid showing selected cell index of old video when new video is played
    _dataInterface.selectedCCIndex = -1;
    _dataInterface.selectedVideoSpeedIndex = -1;
    
    clickedIndexpath = indexPath;
    
    if (tableView == self.table_MyVideos)
    {
        // To revert back to original
        [self cancelTableClicked:nil];

        NSDictionary *dictVideo = [self.arr_CourseData objectAtIndex:indexPath.section];
        OEXCourse *obj_course = [dictVideo objectForKey:CAV_KEY_COURSE];
        _dataInterface.selectedCourseOnFront = obj_course;
        // Navigate to nextview and pass array of HelperVideoDownload obj...
        
        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
        OEXMyVideosSubSectionViewController *objSub = [storyboard instantiateViewControllerWithIdentifier:@"MyVideosSubsection"];
        objSub.course = obj_course;
        [_videoPlayerInterface resetPlayer];
        _videoPlayerInterface=nil;
        [self.navigationController pushViewController:objSub animated:YES];
        
        
    }else if (tableView==self.table_RecentVideos)
    {
        if (!_isTableEditing)
        {
            // Check for disabling the prev/next videos
            [self CheckIfFirstVideoPlayed:indexPath];
            
            [self CheckIfLastVideoPlayed:indexPath];
            
            
            //Deselect previously selected row
            
            [tableView reloadRowsAtIndexPaths:[NSArray arrayWithObjects:_selectedIndexPath, nil] withRowAnimation:UITableViewRowAnimationNone];
            _selectedIndexPath=indexPath;
            
            
            NSDictionary *dictVideo = [self.arr_CourseData objectAtIndex:indexPath.section];
            _dataInterface.selectedCourseOnFront = [dictVideo objectForKey:CAV_KEY_COURSE];
            
            

            [self playVideoForIndexPath:indexPath];
            
        }else{
            _selectedIndexPath=nil;
        }
        
        [self.table_RecentVideos reloadData];
        
    }
    

}


#pragma mark - USED WHILE EDITING

- (void)cancelTableClicked:(id)sender
{
    
    // set isSelected to NO for all the objects

    for (NSDictionary *dict in self.arr_CourseData)
    {
        for (OEXHelperVideoDownload *obj_video in [dict objectForKey:CAV_KEY_RECENT_VIDEOS])
        {
            obj_video.isSelected = NO;
        }
    }
    
    [self.arr_SelectedObjects removeAllObjects];
    
    [self disableDeleteButton];
    
    // SHIFT THE PROGRESS TO LEFT
    self.TrailingSpaceCustomProgress.constant = ORIGINAL_RIGHT_SPACE_PROGRESSBAR;
    self.TrailingSpaceOffline.constant = ORIGINAL_RIGHT_SPACE_OFFLINE;
    self.lbl_NavTitle.textAlignment = NSTextAlignmentCenter;
    

    [self hideComponentsOnEditing:NO];
    [self.table_RecentVideos reloadData];
    
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
        NSString * sString = NSLocalizedString(@"THIS_VIDEO", nil);
        if (_arr_SelectedObjects.count > 1) {
            sString = NSLocalizedString(@"THESE_VIDEOS", nil);
        }
        
        [self showAlert:OEXAlertTypeDeleteConfirmationAlert];
        
    }
    
}

- (void)editTableClicked:(id)sender
{
    self.arr_SelectedObjects = [[NSMutableArray alloc] init];

    // SHIFT THE PROGRESS TO LEFT
    self.TrailingSpaceCustomProgress.constant = ORIGINAL_RIGHT_SPACE_PROGRESSBAR + SHIFT_LEFT;
    
    self.TrailingSpaceOffline.constant = ORIGINAL_RIGHT_SPACE_OFFLINE + MOVE_OFFLINE_X;

    if (!_dataInterface.reachable)
        self.lbl_NavTitle.textAlignment = NSTextAlignmentLeft;

    
    [self hideComponentsOnEditing:YES];
    
    [self.table_RecentVideos reloadData];
}


- (void)selectCheckbox:(id)sender
{
    NSInteger section = ([sender tag])/100;
    NSInteger row = ([sender tag])%100;
    
    NSArray *videos = [[self.arr_CourseData objectAtIndex:section] objectForKey:CAV_KEY_RECENT_VIDEOS];
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
    
    [self.table_RecentVideos reloadData];
    
    [self disableDeleteButton];
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


- (void)checkIfAllSelected
{
    // check if all the boxes checked on table then show SelectAll checkbox checked
    BOOL flagBreaked = NO;

    for (NSDictionary *dict in self.arr_CourseData)
    {
        for (OEXHelperVideoDownload *obj_video in [dict objectForKey:CAV_KEY_RECENT_VIDEOS])
        {
            if (!obj_video.isSelected)
            {
                self.selectAll = NO;
                flagBreaked = YES;
                break;
            }
            else
                self.selectAll = YES;
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
        
        for (NSDictionary *dict in self.arr_CourseData)
        {
            for (OEXHelperVideoDownload *obj_video in [dict objectForKey:CAV_KEY_RECENT_VIDEOS])
            {
                obj_video.isSelected = NO;
                [self.arr_SelectedObjects removeObject:obj_video];
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
        
        
        for (NSDictionary *dict in self.arr_CourseData)
        {
            for (OEXHelperVideoDownload *obj_video in [dict objectForKey:CAV_KEY_RECENT_VIDEOS])
            {
                obj_video.isSelected = YES;
                [self.arr_SelectedObjects addObject:obj_video];
            }
        }
        
    }
    
    [self.table_RecentVideos reloadData];
   
    [self disableDeleteButton];

}







-(void)playVideoForIndexPath:(NSIndexPath *)indexPath
{
    self.video_containerView.hidden = NO;
    
    
    [_videoPlayerInterface setShouldRotate:YES];
    
    NSArray *videos = [[self.arr_CourseData objectAtIndex:indexPath.section] objectForKey:CAV_KEY_RECENT_VIDEOS];
    OEXHelperVideoDownload *obj = [videos objectAtIndex:indexPath.row];
    
    // Assign this for Analytics
    _dataInterface.selectedVideoUsedForAnalytics = obj;

    // Set the path of the downloaded videos
    [_dataInterface downloadTranscripts:obj];
  
    
    NSFileManager *filemgr = [NSFileManager defaultManager];
    NSString *slink = [obj.filePath stringByAppendingPathExtension:@"mp4"];
    if (![filemgr fileExistsAtPath:slink])
    {
        NSError *error = nil;
        [filemgr createSymbolicLinkAtPath:[obj.filePath stringByAppendingPathExtension:@"mp4"] withDestinationPath:obj.filePath error:&error];
      
        if (error)
        {
            [self showAlert:OEXAlertTypePlayBackErrorAlert];
       }
    }
    
    [self.videoPlayerInterface.moviePlayerController stop];
    
    self.currentVideoURL = [NSURL fileURLWithPath:slink];
    // handle the frame of table, videoplayer & bottom view
    [self handleComponentsFrame];
    
    self.currentTappedVideo = obj;

    self.lbl_videoHeader.text = [NSString stringWithFormat:@"%@ ", self.currentTappedVideo.summary.name];
    self.lbl_videobottom.text = [NSString stringWithFormat:@"%@ ", obj.summary.name];
    self.lbl_section.text = [NSString stringWithFormat:@"%@\n%@", self.currentTappedVideo.summary.sectionPathEntry.name, self.currentTappedVideo.summary.chapterPathEntry.name];
	
    [_videoPlayerInterface playVideoFor:obj];
    
    
    // Send Analytics
    [_dataInterface sendAnalyticsEvents:OEXVideoStatePlay WithCurrentTime:self.videoPlayerInterface.moviePlayerController.currentPlaybackTime];
}



- (void)handleComponentsFrame
{

        [UIView animateWithDuration:ANIMATION_DURATION animations:^{
            self.videoViewHeight.constant=225;
            [self.recentEditViewHeight setConstant:0.0f];
            [self.view layoutIfNeeded];
            
        } completion:^(BOOL finished) {
            
        
           
         }];
    
}

#pragma mark - CollectionView Delegate

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return 2;
}

// The cell that is returned must be retrieved from a call to -dequeueReusableCellWithReuseIdentifier:forIndexPath:
- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    
    OEXTabBarItemsCell * cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"tabCell" forIndexPath:indexPath];
    
    NSString * title;
    
    switch (indexPath.row) {
        case 0:
            title = NSLocalizedString(@"ALL_VIDEOS", nil);
            break;
            
        case 1:
            title = NSLocalizedString(@"RECENT VIDEOS",nil);
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
    
    if (indexPath.row == cellSelectedIndex)
        return;
   
    self.videoViewHeight.constant=0;
    self.video_containerView.hidden = YES;
    
    [_videoPlayerInterface setShouldRotate:NO];
     cellSelectedIndex = indexPath.row;
   
    [self removePlayerObserver];
    self.currentTappedVideo=nil;
    _selectedIndexPath=nil;
    [self.videoPlayerInterface.moviePlayerController stop];
    self.lbl_NavTitle.textAlignment = NSTextAlignmentCenter;
    

    switch (indexPath.row)
    {
        case 0: //All Videos
           
            self.table_MyVideos.hidden = NO;
            self.recentVideoView.hidden = YES;
            self.customEditing.hidden = YES;
            self.btn_SelectAllEditing.hidden = YES;
            self.TrailingSpaceCustomProgress.constant = ORIGINAL_RIGHT_SPACE_PROGRESSBAR;
            self.TrailingSpaceOffline.constant = ORIGINAL_RIGHT_SPACE_OFFLINE;
            [self cancelTableClicked:nil];
            
            
            //Analytics Screen record
            [OEXAnalytics screenViewsTracking: @"My Videos - All Videos"];
            
            break;
            
        case 1: //Recent Videos
            [self addPlayerObserver];
            if([self.arr_CourseData count]==0)
                [self.recentEditViewHeight setConstant:0.0];
            else
                [self.recentEditViewHeight setConstant:EDIT_BUTTON_HEIGHT];
            self.table_MyVideos.hidden = YES;
            self.recentVideoView.hidden = NO;
            self.customEditing.hidden = NO;
            
            if (self.isTableEditing)
            {
                self.btn_SelectAllEditing.hidden = NO;
                self.TrailingSpaceCustomProgress.constant = ORIGINAL_RIGHT_SPACE_PROGRESSBAR + SHIFT_LEFT;
                self.TrailingSpaceOffline.constant = ORIGINAL_RIGHT_SPACE_OFFLINE + MOVE_OFFLINE_X;
                self.lbl_NavTitle.textAlignment = NSTextAlignmentLeft;
            }
            else
                self.TrailingSpaceOffline.constant = ORIGINAL_RIGHT_SPACE_OFFLINE;
            
            
            
            //Analytics Screen record
            [OEXAnalytics screenViewsTracking: @"My Videos - Recent Videos"];
            
            break;
            
        default:
            break;
    }

    [self.collectionView reloadData];
    
}




- (void)playbackStateChanged:(NSNotification *)notification
{

    switch ([_videoPlayerInterface.moviePlayerController playbackState])
    {
        case MPMoviePlaybackStateStopped:
            
            ELog(@"Stopped");
            ELog(@"Player current current duration %f total duration %f " , self		.videoPlayerInterface.moviePlayerController.currentPlaybackTime,self.videoPlayerInterface.moviePlayerController.duration);
            break;
        case MPMoviePlaybackStatePlaying:
            
            
            if (_currentTappedVideo.watchedState == OEXPlayedStateWatched)
            {
                ELog(@"Playing 1 ");
            }
            else
            {
                //Buffering view
                ELog(@"Playing 2 ");
                if (_currentTappedVideo.watchedState != OEXPlayedStatePartiallyWatched)
                    [_dataInterface markVideoState:OEXPlayedStatePartiallyWatched
                                      forVideo:_currentTappedVideo];
                _currentTappedVideo.watchedState = OEXPlayedStatePartiallyWatched;
            }
            
            break;
        case MPMoviePlaybackStatePaused:
            ELog(@"Paused");
            
            break;
        case MPMoviePlaybackStateInterrupted:
            ELog(@"Interrupted");
            break;
        case MPMoviePlaybackStateSeekingForward:
            ELog(@"Seeking Forward");
            break;
        case MPMoviePlaybackStateSeekingBackward:
            ELog(@"Seeking Backward");
            break;
        default:
            break;
    }
    
    [self.table_RecentVideos reloadData];
    
}


- (void)playbackEnded:(NSNotification *)notification
{
    NSLog(@"Player current current duration %f total duration %f " , self.videoPlayerInterface.moviePlayerController.currentPlaybackTime,self.videoPlayerInterface.moviePlayerController.duration);

    
    int reason = [[[notification userInfo] valueForKey:MPMoviePlayerPlaybackDidFinishReasonUserInfoKey] intValue];
    if (reason == MPMovieFinishReasonPlaybackEnded)
    {
        int  currentTime=self.videoPlayerInterface.moviePlayerController.currentPlaybackTime;
        int  totalTime=self.videoPlayerInterface.moviePlayerController.duration;
        
        if(currentTime==totalTime && totalTime>0)
        {
            [_dataInterface markLastPlayedInterval:0.0 forVideo:_currentTappedVideo];
            
            self.videoPlayerInterface.moviePlayerController.currentPlaybackTime=0.0;
            
            
            if(cellSelectedIndex!=0){
                _currentTappedVideo.watchedState = OEXPlayedStateWatched;
                [_dataInterface markVideoState:OEXPlayedStateWatched
                                  forVideo:_currentTappedVideo];
            }
          [self.table_RecentVideos reloadData];
        }
        
        
    }else if (reason == MPMovieFinishReasonUserExited) {
  
    }else if (reason == MPMovieFinishReasonPlaybackError) { 
        if([_currentTappedVideo.summary.videoURL isEqualToString:@""])
            [self showAlert:OEXAlertTypePlayBackContentUnAvailable];
    
    }
    
}




#pragma mark play previous video from the list

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
    if(indexPath)
    {
        [self CheckIfFirstVideoPlayed:indexPath];
        [self tableView:self.table_RecentVideos didSelectRowAtIndexPath:indexPath];
    }
}

-(NSIndexPath *)getPreviousVideoIndex
{
    NSIndexPath *indexPath=nil;
    NSIndexPath *currentIndexPath=clickedIndexpath;
    NSInteger row=currentIndexPath.row;
    NSInteger section=currentIndexPath.section;
    
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
            NSInteger rowcount=[self.table_RecentVideos numberOfRowsInSection:section-1];
            indexPath=[NSIndexPath indexPathForRow:rowcount-1 inSection:section-1];
        }
    }
    
    
    return indexPath;
    
}





#pragma mark  Implement next video play functionality

- (void)CheckIfLastVideoPlayed:(NSIndexPath *)indexPath
{
    NSInteger totalSections = [self.table_RecentVideos numberOfSections];
    // get last index of the table
    NSInteger totalRows = [self.table_RecentVideos numberOfRowsInSection:totalSections-1];
    
    if (indexPath.section == totalSections-1 && indexPath.row == totalRows-1)
    {
        // Post notification to hide the next button
        // We are playing the last video
        [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_HIDE_PREV_NEXT object:self userInfo:@{KEY_DISABLE_NEXT: @"YES"}];
    }
    else
    {
        // Not the last video is playing.
        [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_HIDE_PREV_NEXT object:self userInfo:@{KEY_DISABLE_NEXT: @"NO"}];
    }
    
}


-(void)playNextVideo{
    
    NSIndexPath *indexPath=[self getNextVideoIndex];
    
    if(indexPath)
    {
        [self CheckIfLastVideoPlayed:indexPath];
        [self tableView:self.table_RecentVideos didSelectRowAtIndexPath:indexPath];
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
    NSIndexPath *currentIndexPath=clickedIndexpath;
    NSInteger row=currentIndexPath.row;
    NSInteger section=currentIndexPath.section;
    
    NSInteger totalSection=[self.table_RecentVideos numberOfSections];
    if(currentIndexPath.section>=(totalSection-1)){
        
        NSInteger rowcount=[self.table_RecentVideos numberOfRowsInSection:totalSection-1];
        if(currentIndexPath.row >= rowcount-1){
             return nil;
        }
        
    }

    if([self.table_RecentVideos numberOfSections] > 1 ){
        
        NSInteger rowcount=[self.table_RecentVideos numberOfRowsInSection:section];
        
        if(row+1 <rowcount){
            
            indexPath=[NSIndexPath indexPathForRow:row+1 inSection:section];
            
        }else{
            
            NSInteger sectionCount=[self.table_RecentVideos numberOfSections];
            
            if(section+1 < sectionCount){
                
                indexPath=[NSIndexPath indexPathForRow:0 inSection:section+1];
                
            }
        }
        
    }else{
        
        NSInteger rowcount=[self.table_RecentVideos numberOfRowsInSection:section];
        if(row+1 <rowcount){
            
            indexPath=[NSIndexPath indexPathForRow:row+1 inSection:section];
            
        }
    }
    
    return indexPath;
    
}

/// get  current video indexPath

-(NSIndexPath *) getCurrentIndexPath{
    
    if([self.table_RecentVideos numberOfSections] > 1)
    {
   
        for (id  array in self.arr_SubsectionData) {
            
            if( [array containsObject:self.currentTappedVideo]  &&[array isKindOfClass:[NSArray class]] ){
                
                NSInteger row=[array indexOfObject:self.currentTappedVideo];
                NSInteger section=[self.arr_SubsectionData indexOfObject:array];
                return [NSIndexPath indexPathForRow:row inSection:section];
                
            }
            
        }
    }
    
    
    return [NSIndexPath indexPathForRow:0 inSection:0] ;
    
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

- (void)didReceiveMemoryWarning
{
    ELog(@"MemoryWarning MyVideosViewController");

    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark SWRevealViewController
- (void)revealController:(SWRevealViewController *)revealController didMoveToPosition:(FrontViewPosition)position {
    
    if (position == FrontViewPositionLeft)
    {
        if(cellSelectedIndex==1){
            [self addPlayerObserver];
        }
      
        //Hide overlay
        [UIView animateWithDuration:0.5 delay:0.0 options:0 animations:^{
            self.overlayButton.alpha = 0.0f;
        } completion:^(BOOL finished) {
            self.overlayButton.hidden = YES;
        }];
        
        
        [_videoPlayerInterface.moviePlayerController.view setUserInteractionEnabled:YES];
        //check if needs to launch email
        OEXAppDelegate *appDelegate = (OEXAppDelegate *)[[UIApplication sharedApplication] delegate];
        if (appDelegate.pendingMailComposerLaunch) {
            appDelegate.pendingMailComposerLaunch = NO;
            
            if (![MFMailComposeViewController canSendMail]) {
                [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"EMAIL_ACCOUNT_NOT_SET_UP_TITLE", nil)
                                            message:NSLocalizedString(@"EMAIL_ACCOUNT_NOT_SET_UP_MESSAGE", nil)
                                           delegate:nil
                                  cancelButtonTitle:NSLocalizedString(@"OK", nil)
                                  otherButtonTitles:nil] show];
            }
            else
            {
                MFMailComposeViewController * mailComposer = [[MFMailComposeViewController alloc] init];
                [mailComposer setMailComposeDelegate:self];
                [mailComposer setSubject:@"Customer Feedback"];
                [mailComposer setMessageBody:@" " isHTML:NO];
                NSString* feedbackAddress = [OEXEnvironment shared].config.feedbackEmailAddress;
                if(feedbackAddress != nil) {
                    [mailComposer setToRecipients:@[feedbackAddress]];
                }
                [self presentViewController:mailComposer animated:YES completion:nil];
            }
        }
        //Hide overlay
        [_videoPlayerInterface setShouldRotate:YES];
        //self.overlayButton.hidden = YES;
    }
    else if (position == FrontViewPositionRight)
    {
        
        
        [self.navigationController popToViewController:self animated:NO];
        [UIView animateWithDuration:0.5 delay:0 options:0 animations:^{
            self.overlayButton.alpha = 0.5f;
        } completion:^(BOOL finished) {
            
        }];
       
        [_videoPlayerInterface.moviePlayerController setFullscreen:NO];
        [_videoPlayerInterface.moviePlayerController.view setUserInteractionEnabled:NO];
        [_videoPlayerInterface setShouldRotate:NO];
        [self removePlayerObserver];
        [_videoPlayerInterface.moviePlayerController pause];
        self.overlayButton.hidden = NO;
        
    }
}

-(void)mailComposeController:(MFMailComposeViewController*)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)overlayButtonTapped:(id)sender {
    [self.revealViewController revealToggleAnimated:YES];
}


-(void)dealloc
{
    
}


- (void)viewWillDisappear:(BOOL)animated
{
    //NSLog(@"DEALLOC my videos");
    if(self.navigationController.topViewController != self)
    {
        [[CLPortraitOptionsView sharedInstance] removeSelfFromSuperView];
        [self.videoPlayerInterface.moviePlayerController pause];
    }
    
    [self removePlayerObserver];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:TOTAL_DL_PROGRESS object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self  name:DOWNLOAD_PROGRESS_NOTIFICATION object:nil];

    [[NSNotificationCenter defaultCenter] removeObserver:self name:kReachabilityChangedNotification object:nil];
   
}


-(void)addPlayerObserver{
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playNextVideo) name:NOTIFICATION_NEXT_VIDEO object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playPreviousVideo) name:NOTIFICATION_PREVIOUS_VIDEO object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(showCCPortrait:)
                                                 name:NOTIFICATION_OPEN_CC_PORTRAIT object:nil];
    

    //Add oserver
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(playbackStateChanged:)
                                                 name:MPMoviePlayerPlaybackStateDidChangeNotification object:_videoPlayerInterface.moviePlayerController];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(playbackEnded:)
                                                 name:MPMoviePlayerPlaybackDidFinishNotification object:_videoPlayerInterface.moviePlayerController];
}


-(void)removePlayerObserver{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NOTIFICATION_NEXT_VIDEO object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NOTIFICATION_PREVIOUS_VIDEO object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NOTIFICATION_OPEN_CC_PORTRAIT object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:MPMoviePlayerPlaybackStateDidChangeNotification object:_videoPlayerInterface.moviePlayerController];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:MPMoviePlayerPlaybackDidFinishNotification object:_videoPlayerInterface.moviePlayerController];
}


#pragma mark videoPlayer Delegate

-(void)movieTimedOut{
    
    if(!_videoPlayerInterface.moviePlayerController.isFullscreen){
        
        [[OEXStatusMessageViewController sharedInstance] showMessage:NSLocalizedString(@"TIMEOUT_CHECK_INTERNET_CONNECTION", nil)
                                                 onViewController:self.view
                                                         messageY:64
                                                       components:@[self.view_NavBG , self.tabView]
                                                       shouldHide:YES];
        
        [_videoPlayerInterface.moviePlayerController stop];
        
        
    }else{
        
        [self showAlert:OEXAlertTypeVideoTimeOutAlert];
        
    }
    
    
}



- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (alertView.tag == 1001)
    {
        if (buttonIndex == 1)
        {
            [self playNextVideo];
        }
    }
    else if(alertView.tag==1002)
    {
        if (buttonIndex == 1)
        {
            NSInteger deleteCount = 0;
            
            for (OEXHelperVideoDownload *selectedVideo in self.arr_SelectedObjects)
            {
                // make a copy of array to avoid GeneralException(updation of array in loop) - crashes app
                
                NSMutableArray *arrCopySubsection = [self.arr_CourseData mutableCopy];
                
                NSInteger index = -1;
                
                for (NSDictionary *dict in arrCopySubsection)
                {
                    index ++;
                    NSMutableArray *arrvideos = [[dict objectForKey:CAV_KEY_RECENT_VIDEOS] mutableCopy];
                    
                    for (OEXHelperVideoDownload *videos in arrvideos)
                    {
                        if (selectedVideo == videos)
                        {
                            [[[self.arr_CourseData objectAtIndex:index] objectForKey:CAV_KEY_RECENT_VIDEOS] removeObject:videos];
                            
                            // remove for key CAV_KEY_VIDEOS also to maintain consistency.
                            // As it is unsorted array used to sort and put in array for key CAV_KEY_RECENT_VIDEOS
                            
                            [[[self.arr_CourseData objectAtIndex:index] objectForKey:CAV_KEY_VIDEOS] removeObject:videos];
                            
                            [[OEXInterface sharedInterface] deleteDownloadedVideoForVideoId:selectedVideo.summary.videoID completionHandler:^(BOOL success) {
                                selectedVideo.state=OEXDownloadStateNew;
                                selectedVideo.DownloadProgress=0.0;
                                selectedVideo.isVideoDownloading = NO;
                                
                            }];
                            
                            deleteCount++;
                            // if no objects in a particular section then remove the array
                            if ([[[self.arr_CourseData objectAtIndex:index] objectForKey:CAV_KEY_RECENT_VIDEOS] count] == 0)
                            {
                                [self.arr_CourseData removeObject:dict];
                            }
                        }
                    }
                    
                }
                
            }
            
            // if no objects to show
            if ([self.arr_CourseData count] == 0)
            {
                self.btn_SelectAllEditing.hidden = YES;
                [self.btn_SelectAllEditing setImage:[UIImage imageNamed:@"ic_checkbox_default.png"] forState:UIControlStateNormal];
                self.isTableEditing = NO;
                [self.recentEditViewHeight setConstant:0.0];
                self.lbl_NoVideo.hidden = NO;
                self.table_RecentVideos.hidden = YES;
            }
            
            [self.table_RecentVideos reloadData];
            [self.table_MyVideos reloadData];
            
            NSString * sString = @"";
            if (deleteCount > 1) {
                sString = NSLocalizedString(@"s", nil);
            }
            
            [[OEXStatusMessageViewController sharedInstance] showMessage:[NSString stringWithFormat:@"%ld %@%@ %@", (long)deleteCount, NSLocalizedString(@"VIDEO", nil), sString, NSLocalizedString(@"DELETED", nil)]
                                                     onViewController:self.view
                                                             messageY:108
                                                           components:@[self.view_NavBG , self.tabView , self.btn_LeftNavigation, self.lbl_NavTitle, self.lbl_Offline, self.view_Offline, self.btn_SelectAllEditing, self.customProgressView, self.btn_Downloads]
                                                           shouldHide:YES];
            // clear all objects form array after deletion.
            // To obtain correct count on next deletion process.
            
            [self.arr_SelectedObjects removeAllObjects];
        }
        
        [self cancelTableClicked:nil];

    }else if (alertView.tag==1005 || alertView.tag ==1006){
        
        
        
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
            UIAlertView *alert= [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"CONFIRM_DELETE_TITLE", nil)
                                                           message:[NSString stringWithFormat:@"%@ %@", NSLocalizedString(@"CONFIRM_DELETE_MESSAGE", nil) ,sString]
                                                          delegate:self
                                                 cancelButtonTitle:NSLocalizedString(@"CANCEL", nil)
                                                 otherButtonTitles:NSLocalizedString(@"DELETE", nil), nil];
            alert.tag=1002;
            [alert show];
            
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
            
            alert.tag=1003;
            [alert show];
            
            
        }
            
            break;
            
            
        case OEXAlertTypeVideoTimeOutAlert:{
            
            UIAlertView *alert= [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"TIMEOUT", nil)
                                                           message:NSLocalizedString(@"TIMEOUT_CHECK_INTERNET_CONNECTION", nil)
                                                          delegate:self
                                                 cancelButtonTitle:NSLocalizedString(@"OK", nil)
                                                 otherButtonTitles:nil];
            alert.tag=1004;
            [alert show];
            
        }
            break;
            
            
        case OEXAlertTypePlayBackContentUnAvailable:{
            
            UIAlertView *alert= [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"VIDEO_CONTENT_NOT_AVAILABLE", nil)
                                                           message:nil
                                                          delegate:self
                                                 cancelButtonTitle:NSLocalizedString(@"CLOSE", nil)
                                                 otherButtonTitles:nil];
            alert.tag=1005;
            [alert show];
            
            
        }
            break;
            
        default:
            break;
    }
    
    
    
}




@end
