//
//  OEXMyVideosViewController.m
//  edXVideoLocker
//
//  Created by Rahul Varma on 27/06/14.
//  Copyright (c) 2014-2015 edX. All rights reserved.
//

@import edXCore;

#import "OEXMyVideosViewController.h"

#import "edX-Swift.h"
#import "Logger+OEXObjC.h"

#import "NSArray+OEXSafeAccess.h"

#import "OEXAnalytics.h"
#import "OEXAppDelegate.h"
#import "OEXCourse.h"
#import "OEXCourseVideosTableViewCell.h"
#import "OEXCustomEditingView.h"
#import "OEXCustomLabel.h"
#import "OEXDateFormatting.h"
#import "OEXDownloadViewController.h"
#import "OEXInterface.h"
#import "OEXFrontTableViewCell.h"
#import "OEXHelperVideoDownload.h"
#import "OEXNetworkConstants.h"
#import "OEXTabBarItemsCell.h"
#import "OEXVideoPathEntry.h"
#import "OEXVideoPlayerInterface.h"
#import "OEXVideoSummary.h"
#import "OEXRouter.h"
#import "SWRevealViewController.h"
#import "OEXStyles.h"

#define RECENT_HEADER_HEIGHT 30.0
#define ALL_HEADER_HEIGHT 8.0
#define MOVE_OFFLINE_X 35.0
#define MOVE_TITLE_X 10.0
#define EDIT_BUTTON_HEIGHT 50.0
#define SHIFT_LEFT 45.0
#define VIDEO_VIEW_HEIGHT  225
#define ORIGINAL_RIGHT_SPACE_PROGRESSBAR 8
#define ORIGINAL_RIGHT_SPACE_OFFLINE 15

typedef  enum OEXAlertType
{
    OEXAlertTypeNextVideoAlert,
    OEXAlertTypeDeleteConfirmationAlert,
    OEXAlertTypePlayBackErrorAlert,
    OEXAlertTypeCannotPlayVideo,
    OEXAlertTypeVideoTimeOutAlert,
    OEXAlertTypePlayBackContentUnAvailable
}OEXAlertType;

@interface OEXMyVideosViewController () <OEXVideoPlayerInterfaceDelegate, UITableViewDataSource, UITableViewDelegate, UICollectionViewDataSource, UICollectionViewDelegate>
{
    NSInteger cellSelectedIndex;
    NSIndexPath* clickedIndexpath;
}

@property (nonatomic, strong) NSMutableArray* arr_CourseData;
@property (nonatomic, strong) NSMutableArray* arr_SubsectionData;
@property(nonatomic) NSInteger alertCount;
@property (nonatomic, strong) OEXInterface* dataInterface;
@property(strong, nonatomic) OEXVideoPlayerInterface* videoPlayerInterface;
@property(strong, nonatomic) OEXHelperVideoDownload* currentTappedVideo;
@property(strong, nonatomic) NSURL* currentVideoURL;
@property(nonatomic, strong) NSIndexPath* selectedIndexPath;
@property(nonatomic, assign) BOOL isTableEditing;
@property(nonatomic, assign) BOOL selectAll;
@property (nonatomic, strong) NSMutableArray* arr_SelectedObjects;
@property (nonatomic, assign) BOOL isShifted;

@property (weak, nonatomic) IBOutlet UILabel* lbl_NoVideo;
@property (weak, nonatomic) IBOutlet UIView* recentVideoView;
@property   (weak, nonatomic) IBOutlet UIView* recentVideoPlayBackView;
@property (weak, nonatomic) IBOutlet OEXCustomLabel* lbl_videoHeader;
@property (weak, nonatomic) IBOutlet OEXCustomLabel* lbl_videobottom;
@property (weak, nonatomic)  IBOutlet OEXCustomLabel* lbl_section;
@property (weak, nonatomic) IBOutlet UIView* video_containerView;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint* videoViewHeight;
@property   (weak, nonatomic) IBOutlet UIView* videoVideo;
@property(nonatomic, strong) IBOutlet NSLayoutConstraint* recentEditViewHeight;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint* TrailingSpaceCustomProgress;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint* ConstraintRecentTop;

@property (weak, nonatomic) IBOutlet UITableView* table_MyVideos;
@property (weak, nonatomic) IBOutlet UIView* tabView;
@property (weak, nonatomic) IBOutlet UICollectionView* collectionView;
@property (weak, nonatomic) IBOutlet UITableView* table_RecentVideos;

@property (weak, nonatomic) IBOutlet OEXCustomEditingView* customEditing;

@property (strong, nonatomic) OEXCheckBox* btn_SelectAllEditing;
@property (strong, nonatomic) ProgressController *progressController;
@end

@implementation OEXMyVideosViewController

#pragma mark Status Overlay

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    //Analytics Screen record
    [[OEXAnalytics sharedAnalytics] trackScreenWithName: @"My Videos - All Videos"];

    [self.navigationController setNavigationBarHidden:false animated:animated];

    // Add Observer
    [self addObservers];

    // Only if video is playing.
    if(cellSelectedIndex == 1) {
        [self addPlayerObserver];
    }

    // Populate My Videos View data
    self.lbl_NoVideo.hidden = YES;
    self.lbl_NoVideo.text = [Strings noVideosDownloaded];
    [self getMyVideosTableData];
    _isShifted = NO;

    //While editing goto downloads then comes back Progressview overlaps checkbox.
    // To avoid this check this.
    if(_isTableEditing) {
        self.TrailingSpaceCustomProgress.constant = ORIGINAL_RIGHT_SPACE_PROGRESSBAR + SHIFT_LEFT;
    }
    else {
        if(self.videoViewHeight.constant == 225) {
            [self.recentEditViewHeight setConstant:0.0f];
        }
    }

    self.navigationController.navigationBarHidden = NO;

    self.table_RecentVideos.separatorInset = UIEdgeInsetsZero;
#ifdef __IPHONE_8_0
    if(IS_IOS8) {
        [self.table_RecentVideos setLayoutMargins:UIEdgeInsetsZero];
    }
#endif
}

- (void)removeAllObserver {
    [_videoPlayerInterface resetPlayer];
    _videoPlayerInterface.moviePlayerController = nil;
    _videoPlayerInterface.videoPlayerVideoView = nil;
    _videoPlayerInterface = nil;
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)addObservers {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(downloadCompleteNotification:)
                                                 name:OEXDownloadEndedNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateTotalDownloadProgress:) name:OEXDownloadProgressChangedNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(navigationStateChangedWithNotification:) name:OEXSideNavigationChangedStateKey object:nil];
}

- (void)leftNavigationBtnClicked {
    //Hide overlay
    [_videoPlayerInterface setShouldRotate:NO];
    [_videoPlayerInterface.moviePlayerController pause];
    [self performSelector:@selector(toggleReveal) withObject:nil afterDelay:0.2];
}

- (void)toggleReveal {
    [self.revealViewController toggleDrawerAnimated:YES];
}

- (void)viewDidLoad {
    
    [super viewDidLoad];
    self.videoViewHeight.constant = 0;

    // Do any additional setup after loading the view.
    //Hide back button
    self.navigationController.navigationBarHidden = NO;
    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@" " style:UIBarButtonItemStylePlain target:nil action:nil];
    self.title = [Strings myVideos];

    //Set exclusive touch for all buttons
    self.videoVideo.exclusiveTouch = YES;
    self.table_RecentVideos.exclusiveTouch = YES;
    self.table_MyVideos.exclusiveTouch = YES;
    
    //Set Navigation Buttons
    self.btn_SelectAllEditing = [[OEXCheckBox alloc] initWithFrame:CGRectMake(0, 0, 40, 40)];
    [self.btn_SelectAllEditing addTarget:self action:@selector(selectAllChanged:) forControlEvents:UIControlEventTouchUpInside];
    self.progressController = [[ProgressController alloc] initWithOwner:self router:self.environment.router dataInterface:self.environment.interface];
    self.navigationItem.rightBarButtonItem = [self.progressController navigationItem];
    [self.progressController hideProgessView];
    
    // Initialize array of data to show on table
    self.arr_SubsectionData = [[NSMutableArray alloc] init];

    // Initialize the interface for API calling
    self.dataInterface = [OEXInterface sharedInterface];

    //Add custom button for drawer
    UIBarButtonItem *closeButton = [[UIBarButtonItem alloc] initWithImage:[UIImage MenuIcon] style:UIBarButtonItemStylePlain target:self action:@selector(leftNavigationBtnClicked)];
    closeButton.accessibilityLabel = [Strings accessibilityMenu];
    self.navigationItem.leftBarButtonItem = closeButton;

    //Fix for 20px issue for the table view
    self.automaticallyAdjustsScrollViewInsets = NO;
    [self.table_MyVideos setContentInset:UIEdgeInsetsMake(0, 0, 8, 0)];

    [self.dataInterface setNumberOfRecentDownloads:0];

    // Used for autorotation
    [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];

    // Show Custom editing View
    [self.customEditing.btn_Edit addTarget:self action:@selector(editTableClicked:) forControlEvents:UIControlEventTouchUpInside];
    [self.customEditing.btn_Delete addTarget:self action:@selector(deleteTableClicked:) forControlEvents:UIControlEventTouchUpInside];
    [self.customEditing.btn_Cancel addTarget:self action:@selector(cancelTableClicked:) forControlEvents:UIControlEventTouchUpInside];
    self.btn_SelectAllEditing.hidden = YES;
    self.isTableEditing = NO;           // Check Edit button is clicked
    self.selectAll = NO;        // Check if all are selected

    // set select all button color to white so it look prominent on blue navigation bar
    self.btn_SelectAllEditing.tintColor = [[OEXStyles sharedStyles] navigationItemTintColor];
    [self performSelector:@selector(reloadTable) withObject:self afterDelay:5.0];
}

- (void)reloadTable {
    [self.table_MyVideos reloadData];
}

- (void)activatePlayer {
    if(!_videoPlayerInterface) {
        //Initiate player object
        self.videoPlayerInterface = [[OEXVideoPlayerInterface alloc] init];
        [self.videoPlayerInterface enableFullscreenAutorotation];
        self.videoPlayerInterface.delegate = self;
        
        [self addChildViewController:self.videoPlayerInterface];
        [self.videoPlayerInterface didMoveToParentViewController:self];
        
        _videoPlayerInterface.videoPlayerVideoView = self.videoVideo;
        [self addPlayerObserver];
        if(_videoPlayerInterface) {
            [self.videoPlayerInterface videoPlayerShouldRotate];
        }
    }
}

- (void)resetPlayer {
    if(_videoPlayerInterface) {
        [self.videoPlayerInterface removeFromParentViewController];
        
        [self.videoPlayerInterface.moviePlayerController stop];
        [self removePlayerObserver];
        [_videoPlayerInterface resetPlayer];
        _videoPlayerInterface = nil;
    }
}

#pragma update total download progress

- (void)downloadCompleteNotification:(NSNotification*)notification {
    NSDictionary* dict = notification.userInfo;

    NSURLSessionTask* task = [dict objectForKey:VIDEO_DL_COMPLETE_N_TASK];
    NSURL* url = task.originalRequest.URL;

    if([OEXInterface isURLForVideo:url.absoluteString]) {
        [self getMyVideosTableData];
    }
}

- (void)updateTotalDownloadProgress:(NSNotification* )notification {
    [self updateNavigationItemButtons];
}

- (void)getMyVideosTableData {
    // Initialize array
    self.arr_CourseData = [[NSMutableArray alloc] init];

    NSMutableArray* arrCourseAndVideo = [[NSMutableArray alloc] initWithArray: [_dataInterface coursesAndVideosForDownloadState:OEXDownloadStateComplete] ];

    // Populate both ALL & RECENT Videos Table data
    for(NSDictionary* dict in arrCourseAndVideo) {
        NSMutableDictionary* mutableDict = [dict mutableCopy];

        NSString* strSize = [[NSString alloc] initWithString: [self calculateVideosSizeInCourse:[mutableDict objectForKey:CAV_KEY_VIDEOS]] ];
        NSMutableArray* sortedArray = [mutableDict objectForKey:CAV_KEY_VIDEOS];
        NSSortDescriptor* sortDesc = [[NSSortDescriptor alloc] initWithKey:@"completedDate" ascending:NO selector:@selector(compare:)];
        [sortedArray sortUsingDescriptors:[NSArray arrayWithObject:sortDesc]];
        NSMutableArray* arr_SortedArray = [sortedArray mutableCopy];
        NSDictionary* videos = @{CAV_KEY_COURSE: [mutableDict objectForKey:CAV_KEY_COURSE],
                                 CAV_KEY_VIDEOS: [mutableDict objectForKey:CAV_KEY_VIDEOS],
                                 CAV_KEY_RECENT_VIDEOS: arr_SortedArray,
                                 CAV_KEY_VIDEOS_SIZE: strSize};

        [self.arr_CourseData addObject:videos];
    }

    [self cancelTableClicked:nil];
    [self.table_MyVideos reloadData];
    [self.table_RecentVideos reloadData];

    if([self.arr_CourseData count] == 0) {
        self.lbl_NoVideo.hidden = NO;
        self.table_RecentVideos.hidden = YES;
        [self.recentEditViewHeight setConstant:0.0];
    }
    else {
        self.lbl_NoVideo.hidden = YES;
        self.table_RecentVideos.hidden = NO;

        if(self.videoViewHeight.constant == 225) {
            [self.recentEditViewHeight setConstant:0.0f];
        }
        else {
            [self.recentEditViewHeight setConstant:EDIT_BUTTON_HEIGHT];
        }
    }
}

- (NSString*)calculateVideosSizeInCourse:(NSArray*)arrvideo {
    NSString* strSize = nil;

    double size = 0.0;

    for(OEXHelperVideoDownload* video in arrvideo) {
        double videoSize = [video.summary.size doubleValue];
        double sizeInMegabytes = (videoSize / 1024) / 1024;
        size += sizeInMegabytes;
    }

    strSize = [NSString stringWithFormat:@"%.2fMB", size];

    return strSize;
}


#pragma mark TableViewDataSourceDelegate

- (NSInteger)tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section {
    if(tableView == self.table_MyVideos) {
        return 1;
    }
    else {
        _selectedIndexPath = nil;

        return [[[self.arr_CourseData objectAtIndex:section] objectForKey:CAV_KEY_RECENT_VIDEOS] count];
    }
    return 1;
}

- (UIView*)tableView:(UITableView*)tableView viewForHeaderInSection:(NSInteger)section {
    if(tableView == self.table_MyVideos) {
        UIView* headerview = [[UIView alloc] initWithFrame:CGRectMake(0, 0, tableView.frame.size.width, ALL_HEADER_HEIGHT)];
        headerview.backgroundColor = GREY_COLOR;
        return headerview;
    }
    else {
        NSDictionary* dictVideo = [self.arr_CourseData objectAtIndex:section];
        OEXCourse* obj_course = [dictVideo objectForKey:CAV_KEY_COURSE];

        UIView* view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, tableView.frame.size.width, RECENT_HEADER_HEIGHT )];
        view.backgroundColor = GREY_COLOR;

        UILabel* courseTitle = [[UILabel alloc] initWithFrame:CGRectMake(20, 0, tableView.frame.size.width - 20, RECENT_HEADER_HEIGHT)];
        courseTitle.numberOfLines = 2;
        courseTitle.text = obj_course.name;
        courseTitle.font = [[OEXStyles sharedStyles] semiBoldSansSerifOfSize:14.0f];
        courseTitle.textColor = [UIColor colorWithRed:69.0 / 255.0 green:73.0 / 255.0 blue:81.0 / 255.0 alpha:1.0];
        [view addSubview:courseTitle];

        return view;
    }
    return nil;
}

- (CGFloat)tableView:(UITableView*)tableView heightForHeaderInSection:(NSInteger)section {
    if(tableView == self.table_MyVideos) {
        return ALL_HEADER_HEIGHT;
    }
    else {
        return RECENT_HEADER_HEIGHT;
    }
}

- (NSInteger)numberOfSectionsInTableView:(UITableView*)tableView {
    return [self.arr_CourseData count];
}

- (void)choseCourse:(OEXCourse*)course {
    [self cancelTableClicked:nil];
    // Navigate to nextview and pass array of HelperVideoDownload obj...
    [_videoPlayerInterface resetPlayer];
    _videoPlayerInterface = nil;
    [self.environment.router showVideoSubSectionFromViewController:self forCourse:course withCourseData:nil];
}

- (UITableViewCell*)tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath {
    if(tableView == self.table_MyVideos) {
        static NSString* cellIndentifier = @"PlayerCell";

        OEXFrontTableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:cellIndentifier];
        CourseCardView* infoView = cell.infoView;
        __typeof(self) owner = self;
        cell.infoView.tapAction = ^(CourseCardView* card){
            [owner choseCourse:card.course];
        };
        
        NSDictionary* dictVideo = [self.arr_CourseData objectAtIndex:indexPath.section];
        OEXCourse* obj_course = [dictVideo objectForKey:CAV_KEY_COURSE];
        
        // here banner text is ignored and replaced with video details

        NSInteger count = [[dictVideo objectForKey:CAV_KEY_VIDEOS] count];
        NSString* Vcount = nil;
        if(count == 1) {
            Vcount = [NSString stringWithFormat:@"%ld Video", (long)count];
        }
        else {
            Vcount = [NSString stringWithFormat:@"%ld Videos", (long)count];
        }
        NSString* videoDetails = [NSString stringWithFormat:@"%@, %@", Vcount, [dictVideo objectForKey:CAV_KEY_VIDEOS_SIZE]];
        
        [[CourseCardViewModel onMyVideos:obj_course collectionInfo:videoDetails] apply:infoView networkManager:self.environment.networkManager];
        
        return cell;
    }
    else {      // table_Recent
        static NSString* cellIndentifier = @"CellCourseVideo";
        OEXCourseVideosTableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:cellIndentifier];
        cell.btn_Download.hidden = YES;
        NSArray* videos = [[self.arr_CourseData objectAtIndex:indexPath.section] objectForKey:CAV_KEY_RECENT_VIDEOS];
        OEXHelperVideoDownload* obj_video = [videos objectAtIndex:indexPath.row];
        cell.lbl_Title.text = obj_video.summary.name;
        if([cell.lbl_Title.text length] == 0) {
            cell.lbl_Title.text = @"(Untitled)";
        }

        double size = [obj_video.summary.size doubleValue];
        float result = ((size / 1024) / 1024);
        cell.lbl_Size.text = [NSString stringWithFormat:@"%.2fMB", result];

        if(!obj_video.summary.duration) {
            cell.lbl_Time.text = @"NA";
        }
        else {
            cell.lbl_Time.text = [OEXDateFormatting formatSecondsAsVideoLength: obj_video.summary.duration];
        }

        //Played state
        UIImage* playedImage;
        if(obj_video.watchedState == OEXPlayedStateWatched) {
            playedImage = [UIImage imageNamed:@"ic_watched.png"];
        }
        else if(obj_video.watchedState == OEXPlayedStatePartiallyWatched) {
            playedImage = [UIImage imageNamed:@"ic_partiallywatched.png"];
        }
        else {
            playedImage = [UIImage imageNamed:@"ic_unwatched.png"];
        }
        cell.img_VideoWatchState.image = playedImage;

        // WHILE EDITING
        if(self.isTableEditing) {
            // Unhide the checkbox and set the tag
            cell.btn_CheckboxDelete.hidden = NO;
            if ([self isRTL]) {
                cell.btn_CheckboxDelete.alpha = 0;
                cell.courseVideoStateLeadingConstraint.constant = 60;
                [UIView animateWithDuration:0.2 animations:^{
                    [self.view layoutIfNeeded];
                    cell.btn_CheckboxDelete.alpha = 1;
                }];
            }
            cell.btn_CheckboxDelete.tag = (indexPath.section * 100) + indexPath.row;
            [cell.btn_CheckboxDelete addTarget:self action:@selector(selectCheckbox:) forControlEvents:UIControlEventValueChanged];
            cell.btn_CheckboxDelete.checked = obj_video.isSelected; // Toggle between selected and unselected checkbox
        }
        else {
            if ([self isRTL]) {
                cell.courseVideoStateLeadingConstraint.constant = 20;
                [UIView animateWithDuration:0.2 animations:^{
                    [self.view layoutIfNeeded];
                    cell.btn_CheckboxDelete.alpha = 0;
                } completion:^(BOOL finished) {
                    cell.btn_CheckboxDelete.hidden = YES;
                }];
                
            }
            else {
                cell.btn_CheckboxDelete.hidden = YES;
            }
            if(self.currentTappedVideo == obj_video && !self.isTableEditing) {
                [self setSelectedCellAtIndexPath:indexPath tableView:tableView];
                _selectedIndexPath = indexPath;
            }
        }

#ifdef __IPHONE_8_0
        if(IS_IOS8) {
            [cell setLayoutMargins:UIEdgeInsetsZero];
        }
#endif

        return cell;
    }

    return nil;
}

- (void)tableView:(UITableView*)tableView willDisplayCell:(UITableViewCell*)cell forRowAtIndexPath:(NSIndexPath*)indexPath {
    if(tableView == self.table_RecentVideos) {
        UIView* backview = [[UIView alloc] initWithFrame:CGRectMake(0, 0, tableView.frame.size.width, 50)];
        [backview setBackgroundColor:SELECTED_CELL_COLOR];
        cell.selectedBackgroundView = backview;
        if(indexPath == _selectedIndexPath) {
            [cell setSelected:YES animated:NO];
        }
    }
}

- (void)setSelectedCellAtIndexPath:(NSIndexPath*)indexPath tableView:(UITableView*)tableView {
    UITableViewCell* cell = [tableView cellForRowAtIndexPath:indexPath];
    [cell setSelected:YES animated:YES];
}

#pragma mark TableViewDelegate

- (void)tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath {
    // To avoid showing selected cell index of old video when new video is played
    _dataInterface.selectedCCIndex = -1;
    _dataInterface.selectedVideoSpeedIndex = -1;

    clickedIndexpath = indexPath;

    if(tableView == self.table_RecentVideos) {
        if(!_isTableEditing) {
            // Check for disabling the prev/next videos
            [self CheckIfFirstVideoPlayed:indexPath];

            [self CheckIfLastVideoPlayed:indexPath];

            //Deselect previously selected row

            [tableView reloadRowsAtIndexPaths:[NSArray arrayWithObjects:_selectedIndexPath, nil] withRowAnimation:UITableViewRowAnimationNone];
            _selectedIndexPath = indexPath;

            [self playVideoForIndexPath:indexPath];
        }
        else {
            _selectedIndexPath = nil;
        }

        [self.table_RecentVideos reloadData];
    }
}

#pragma mark - USED WHILE EDITING

- (void)cancelTableClicked:(id)sender {
    // set isSelected to NO for all the objects

    for(NSDictionary* dict in self.arr_CourseData) {
        for(OEXHelperVideoDownload* obj_video in [dict objectForKey : CAV_KEY_RECENT_VIDEOS]) {
            obj_video.isSelected = NO;
        }
    }

    [self.arr_SelectedObjects removeAllObjects];

    [self disableDeleteButton];

    // SHIFT THE PROGRESS TO LEFT
    self.TrailingSpaceCustomProgress.constant = ORIGINAL_RIGHT_SPACE_PROGRESSBAR;

    [self hideComponentsOnEditing:NO];
    [self.table_RecentVideos reloadData];
}

- (void)hideComponentsOnEditing:(BOOL)hide {
    self.isTableEditing = hide;
    self.btn_SelectAllEditing.hidden = !hide;

    self.customEditing.btn_Edit.hidden = hide;
    self.customEditing.btn_Cancel.hidden = !hide;
    self.customEditing.btn_Delete.hidden = !hide;
    self.customEditing.imgSeparator.hidden = !hide;

    self.btn_SelectAllEditing.checked = NO;
    self.selectAll = NO;
    
    [self updateNavigationItemButtons];
}

- (void)deleteTableClicked:(id)sender {
    if(_arr_SelectedObjects.count > 0) {
        [self showAlert:OEXAlertTypeDeleteConfirmationAlert];
    }
}

- (void)editTableClicked:(id)sender {
    self.arr_SelectedObjects = [[NSMutableArray alloc] init];

    // SHIFT THE PROGRESS TO LEFT
    self.TrailingSpaceCustomProgress.constant = ORIGINAL_RIGHT_SPACE_PROGRESSBAR + SHIFT_LEFT;

    [self hideComponentsOnEditing:YES];

    [self.table_RecentVideos reloadData];
}

- (void)selectCheckbox:(id)sender {
    NSInteger section = ([sender tag]) / 100;
    NSInteger row = ([sender tag]) % 100;

    NSArray* videos = [[self.arr_CourseData objectAtIndex:section] objectForKey:CAV_KEY_RECENT_VIDEOS];
    OEXHelperVideoDownload* obj_video = [videos objectAtIndex:row];

    // change status of the object and reload table

    if(obj_video.isSelected) {
        obj_video.isSelected = NO;
        [self.arr_SelectedObjects removeObject:obj_video];
    }
    else {
        obj_video.isSelected = YES;

        [self.arr_SelectedObjects addObject:obj_video];
    }

    [self checkIfAllSelected];

    [self.table_RecentVideos reloadData];

    [self disableDeleteButton];
}

- (void)disableDeleteButton {
    if([self.arr_SelectedObjects count] == 0) {
        self.customEditing.btn_Delete.enabled = NO;
        [self.customEditing.btn_Delete setBackgroundColor:[UIColor darkGrayColor]];
    }
    else {
        [self.customEditing.btn_Delete setBackgroundColor:[UIColor clearColor]];
        self.customEditing.btn_Delete.enabled = YES;
    }
}

- (void)checkIfAllSelected {
    // check if all the boxes checked on table then show SelectAll checkbox checked
    BOOL flagBreaked = NO;

    for(NSDictionary* dict in self.arr_CourseData) {
        for(OEXHelperVideoDownload* obj_video in [dict objectForKey : CAV_KEY_RECENT_VIDEOS]) {
            if(!obj_video.isSelected) {
                self.selectAll = NO;
                flagBreaked = YES;
                break;
            }
            else {
                self.selectAll = YES;
            }
        }

        if(flagBreaked) {
            break;
        }
    }

    self.btn_SelectAllEditing.checked = self.selectAll;
}

- (IBAction)selectAllChanged:(id)sender {
    if(self.selectAll) {
        // de-select all the videos to delete

        self.selectAll = NO;

        for(NSDictionary* dict in self.arr_CourseData) {
            for(OEXHelperVideoDownload* obj_video in [dict objectForKey : CAV_KEY_RECENT_VIDEOS]) {
                obj_video.isSelected = NO;
                [self.arr_SelectedObjects removeObject:obj_video];
            }
        }
    }
    else {
        // remove all objects to avoids number problem
        [self.arr_SelectedObjects removeAllObjects];

        // select all the videos to delete

        self.selectAll = YES;

        for(NSDictionary* dict in self.arr_CourseData) {
            for(OEXHelperVideoDownload* obj_video in [dict objectForKey : CAV_KEY_RECENT_VIDEOS]) {
                obj_video.isSelected = YES;
                [self.arr_SelectedObjects addObject:obj_video];
            }
        }
    }

    [self.table_RecentVideos reloadData];

    [self disableDeleteButton];
}

- (void)playVideoForIndexPath:(NSIndexPath*)indexPath {
    NSArray* videos = [[self.arr_CourseData objectAtIndex:indexPath.section] objectForKey:CAV_KEY_RECENT_VIDEOS];

    self.currentTappedVideo = [videos objectAtIndex:indexPath.row];

    [self activatePlayer];

    // Set the path of the downloaded videos
    [_dataInterface downloadAllTranscriptsForVideo:self.currentTappedVideo];

    NSFileManager* filemgr = [NSFileManager defaultManager];
    NSString* slink = [self.currentTappedVideo.filePath stringByAppendingPathExtension:@"mp4"];
    if(![filemgr fileExistsAtPath:slink]) {
        NSError* error = nil;
        [filemgr createSymbolicLinkAtPath:slink withDestinationPath:self.currentTappedVideo.filePath error:&error];

        if(error) {
            [self showAlert:OEXAlertTypePlayBackErrorAlert];
        }
    }

    self.video_containerView.hidden = NO;
    [_videoPlayerInterface setShouldRotate:YES];
    [self.videoPlayerInterface.moviePlayerController stop];
    self.currentVideoURL = [NSURL fileURLWithPath:self.currentTappedVideo.filePath];
    [self handleComponentsFrame];

    self.lbl_videoHeader.text = [NSString stringWithFormat:@"%@ ", self.currentTappedVideo.summary.name];
    self.lbl_videobottom.text = [NSString stringWithFormat:@"%@ ", self.currentTappedVideo.summary.name];
    self.lbl_section.text = [NSString stringWithFormat:@"%@\n%@", self.currentTappedVideo.summary.sectionPathEntry.name, self.currentTappedVideo.summary.chapterPathEntry.name];

    [_videoPlayerInterface playVideoFor:self.currentTappedVideo];

    // Send Analytics
    [_dataInterface sendAnalyticsEvents:OEXVideoStatePlay withCurrentTime:self.videoPlayerInterface.moviePlayerController.currentPlaybackTime forVideo:self.currentTappedVideo];
}

- (void)handleComponentsFrame {
    [UIView animateWithDuration:ANIMATION_DURATION animations:^{
        self.videoViewHeight.constant = 225;
        [self.recentEditViewHeight setConstant:0.0f];
        [self.view layoutIfNeeded];
    } completion:^(BOOL finished) {
    }];
}

- (void)updateNavigationItemButtons {
    NSMutableArray *barButtons = [[NSMutableArray alloc] init];
    if(_isTableEditing) {
        [barButtons addObject:[[UIBarButtonItem alloc] initWithCustomView:self.btn_SelectAllEditing]];
    }
    if(![self.progressController progressView].hidden){
        [barButtons addObject:[self.progressController navigationItem]];
    }
    if(barButtons.count != self.navigationItem.rightBarButtonItems.count) {
        self.navigationItem.rightBarButtonItems = barButtons;
    }
}

#pragma mark - CollectionView Delegate

- (CGSize)collectionView:(UICollectionView *)collectionView
                  layout:(UICollectionViewLayout *)collectionViewLayout
  sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    return CGSizeMake(collectionView.frame.size.width / 2, 44.0f);
}

- (NSInteger)collectionView:(UICollectionView*)collectionView numberOfItemsInSection:(NSInteger)section {
    return 2;
}

// The cell that is returned must be retrieved from a call to -dequeueReusableCellWithReuseIdentifier:forIndexPath:
- (UICollectionViewCell*)collectionView:(UICollectionView*)collectionView cellForItemAtIndexPath:(NSIndexPath*)indexPath {
    OEXTabBarItemsCell* cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"tabCell" forIndexPath:indexPath];

    NSString* title;

    switch(indexPath.row) {
        case 0:
            title = [Strings allVideos].oex_uppercaseStringInCurrentLocale;
            break;

        case 1:
            title = [Strings recentVideos].oex_uppercaseStringInCurrentLocale;
            break;

        default:
            break;
    }

    cell.title.text = title;

    if(cellSelectedIndex == indexPath.row) {
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
    if(indexPath.row == cellSelectedIndex) {
        return;
    }

    self.videoViewHeight.constant = 0;
    self.video_containerView.hidden = YES;
    cellSelectedIndex = indexPath.row;
    self.currentTappedVideo = nil;
    _selectedIndexPath = nil;
    [self resetPlayer];

    switch(indexPath.row)
    {
        case 0: //All Videos

            self.table_MyVideos.hidden = NO;
            self.recentVideoView.hidden = YES;
            self.customEditing.hidden = YES;
            self.btn_SelectAllEditing.hidden = YES;
            self.TrailingSpaceCustomProgress.constant = ORIGINAL_RIGHT_SPACE_PROGRESSBAR;
            [self cancelTableClicked:nil];

            //Analytics Screen record
            [[OEXAnalytics sharedAnalytics] trackScreenWithName: @"My Videos - All Videos"];

            break;

        case 1: //Recent Videos
            if([self.arr_CourseData count] == 0) {
                [self.recentEditViewHeight setConstant:0.0];
            }
            else {
                [self.recentEditViewHeight setConstant:EDIT_BUTTON_HEIGHT];
            }
            self.table_MyVideos.hidden = YES;
            self.recentVideoView.hidden = NO;
            self.customEditing.hidden = NO;

            if(self.isTableEditing) {
                self.btn_SelectAllEditing.hidden = NO;
                self.TrailingSpaceCustomProgress.constant = ORIGINAL_RIGHT_SPACE_PROGRESSBAR + SHIFT_LEFT;
            }
            
            //Analytics Screen record
            [[OEXAnalytics sharedAnalytics] trackScreenWithName: @"My Videos - Recent Videos"];

            break;

        default:
            break;
    }

    [self.collectionView reloadData];
}

- (void)playbackStateChanged:(NSNotification*)notification {
    switch([_videoPlayerInterface.moviePlayerController playbackState])
    {
        case MPMoviePlaybackStateStopped:
            OEXLogInfo(@"VIDEO", @"Stopped");
            OEXLogInfo(@"VIDEO", @"Player current current duration %f total duration %f ", self.videoPlayerInterface.moviePlayerController.currentPlaybackTime, self.videoPlayerInterface.moviePlayerController.duration);
            break;
        case MPMoviePlaybackStatePlaying:

            if(_currentTappedVideo.watchedState == OEXPlayedStateWatched) {
                OEXLogInfo(@"VIDEO", @"Playing watched video");
            }
            else {
                //Buffering view
                OEXLogInfo(@"VIDEO", @"Playing unwatched video");
                if(_currentTappedVideo.watchedState != OEXPlayedStatePartiallyWatched) {
                    [_dataInterface markVideoState:OEXPlayedStatePartiallyWatched
                                          forVideo:_currentTappedVideo];
                }
                _currentTappedVideo.watchedState = OEXPlayedStatePartiallyWatched;
            }

            break;
        case MPMoviePlaybackStatePaused:
            OEXLogInfo(@"VIDEO", @"Paused");
            break;
        case MPMoviePlaybackStateInterrupted:
            OEXLogInfo(@"VIDEO", @"Interrupted");
            break;
        case MPMoviePlaybackStateSeekingForward:
            OEXLogInfo(@"VIDEO", @"Seeking Forward");
            break;
        case MPMoviePlaybackStateSeekingBackward:
            OEXLogInfo(@"VIDEO", @"Seeking Backward");
            break;
    }

    [self.table_RecentVideos reloadData];
}

- (void)playbackEnded:(NSNotification*)notification {
    OEXLogInfo(@"VIDEO", @"Player current current duration %f total duration %f ", self.videoPlayerInterface.moviePlayerController.currentPlaybackTime, self.videoPlayerInterface.moviePlayerController.duration);

    int reason = [[[notification userInfo] valueForKey:MPMoviePlayerPlaybackDidFinishReasonUserInfoKey] intValue];
    if(reason == MPMovieFinishReasonPlaybackEnded) {
        int currentTime = self.videoPlayerInterface.moviePlayerController.currentPlaybackTime;
        int totalTime = self.videoPlayerInterface.moviePlayerController.duration;

        if(currentTime == totalTime && totalTime > 0) {
            [_dataInterface markLastPlayedInterval:0.0 forVideo:_currentTappedVideo];

            self.videoPlayerInterface.moviePlayerController.currentPlaybackTime = 0.0;

            if(cellSelectedIndex != 0) {
                _currentTappedVideo.watchedState = OEXPlayedStateWatched;
                [_dataInterface markVideoState:OEXPlayedStateWatched
                                      forVideo:_currentTappedVideo];
            }
            [self.table_RecentVideos reloadData];
        }
    }
    else if(reason == MPMovieFinishReasonUserExited) {
    }
    else if(reason == MPMovieFinishReasonPlaybackError) {
        if([_currentTappedVideo.summary.videoURL isEqualToString:@""]) {
            [self showAlert:OEXAlertTypePlayBackContentUnAvailable];
        }
    }
}

#pragma mark play previous video from the list

- (void)CheckIfFirstVideoPlayed:(NSIndexPath*)indexPath {
    if(indexPath.section == 0 && indexPath.row == 0) {
        // Post notification to hide the next button
        // We are playing the last video

        [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_HIDE_PREV_NEXT object:self userInfo:@{KEY_DISABLE_PREVIOUS: @"YES"}];
    }
    else {
        // Not the last video id playing.
        [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_HIDE_PREV_NEXT object:self userInfo:@{KEY_DISABLE_PREVIOUS: @"NO"}];
    }
}

- (void)playPreviousVideo {
    NSIndexPath* indexPath = [self getPreviousVideoIndex];
    if(indexPath) {
        [self CheckIfFirstVideoPlayed:indexPath];
        [self tableView:self.table_RecentVideos didSelectRowAtIndexPath:indexPath];
    }
}

- (NSIndexPath*)getPreviousVideoIndex {
    NSIndexPath* indexPath = nil;
    NSIndexPath* currentIndexPath = clickedIndexpath;
    NSInteger row = currentIndexPath.row;
    NSInteger section = currentIndexPath.section;

    // Check for the last video in the list
    if(currentIndexPath.section == 0) {
        if(currentIndexPath.row == 0) {
            //NSLog(@"Disable previous button");

            return nil;
        }
        else {
            indexPath = [NSIndexPath indexPathForRow:row - 1 inSection:section];
        }
    }
    else {
        if(row > 0) {
            indexPath = [NSIndexPath indexPathForRow:row - 1 inSection:section];
        }
        else {
            NSInteger rowcount = [self.table_RecentVideos numberOfRowsInSection:section - 1];
            indexPath = [NSIndexPath indexPathForRow:rowcount - 1 inSection:section - 1];
        }
    }

    return indexPath;
}

#pragma mark  Implement next video play functionality

- (void)CheckIfLastVideoPlayed:(NSIndexPath*)indexPath {
    NSInteger totalSections = [self.table_RecentVideos numberOfSections];
    // get last index of the table
    NSInteger totalRows = [self.table_RecentVideos numberOfRowsInSection:totalSections - 1];

    if(indexPath.section == totalSections - 1 && indexPath.row == totalRows - 1) {
        // Post notification to hide the next button
        // We are playing the last video
        [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_HIDE_PREV_NEXT object:self userInfo:@{KEY_DISABLE_NEXT: @"YES"}];
    }
    else {
        // Not the last video is playing.
        [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_HIDE_PREV_NEXT object:self userInfo:@{KEY_DISABLE_NEXT: @"NO"}];
    }
}

- (void)playNextVideo {
    NSIndexPath* indexPath = [self getNextVideoIndex];

    if(indexPath) {
        [self CheckIfLastVideoPlayed:indexPath];
        [self tableView:self.table_RecentVideos didSelectRowAtIndexPath:indexPath];
    }
}

- (void)showAlertForNextLecture {
    NSIndexPath* indexPath = [self getNextVideoIndex];

    if(indexPath) {
        [self showAlert:OEXAlertTypeNextVideoAlert];
    }
}

/// get next video index path

- (NSIndexPath*)getNextVideoIndex {
    NSIndexPath* indexPath = nil;
    NSIndexPath* currentIndexPath = clickedIndexpath;
    NSInteger row = currentIndexPath.row;
    NSInteger section = currentIndexPath.section;

    NSInteger totalSection = [self.table_RecentVideos numberOfSections];
    if(currentIndexPath.section >= (totalSection - 1)) {
        NSInteger rowcount = [self.table_RecentVideos numberOfRowsInSection:totalSection - 1];
        if(currentIndexPath.row >= rowcount - 1) {
            return nil;
        }
    }

    if([self.table_RecentVideos numberOfSections] > 1) {
        NSInteger rowcount = [self.table_RecentVideos numberOfRowsInSection:section];

        if(row + 1 < rowcount) {
            indexPath = [NSIndexPath indexPathForRow:row + 1 inSection:section];
        }
        else {
            NSInteger sectionCount = [self.table_RecentVideos numberOfSections];

            if(section + 1 < sectionCount) {
                indexPath = [NSIndexPath indexPathForRow:0 inSection:section + 1];
            }
        }
    }
    else {
        NSInteger rowcount = [self.table_RecentVideos numberOfRowsInSection:section];
        if(row + 1 < rowcount) {
            indexPath = [NSIndexPath indexPathForRow:row + 1 inSection:section];
        }
    }

    return indexPath;
}

/// get  current video indexPath

- (NSIndexPath*)getCurrentIndexPath {
    if([self.table_RecentVideos numberOfSections] > 1) {
        for(id array in self.arr_SubsectionData) {
            if([array containsObject:self.currentTappedVideo] && [array isKindOfClass:[NSArray class]]) {
                NSInteger row = [array indexOfObject:self.currentTappedVideo];
                NSInteger section = [self.arr_SubsectionData indexOfObject:array];
                return [NSIndexPath indexPathForRow:row inSection:section];
            }
        }
    }

    return [NSIndexPath indexPathForRow:0 inSection:0];
}

#pragma mark - Orientation methods

- (BOOL)shouldAutorotate {
    return YES;
}


#pragma mark Global Navigation

- (void)navigationStateChangedWithNotification:(NSNotification*)notification {
    OEXSideNavigationState state = [notification.userInfo[OEXSideNavigationChangedStateKey] unsignedIntegerValue];
    [self navigationChangedToState:state];
}

- (void)navigationChangedToState:(OEXSideNavigationState)state {
    switch(state) {
        case OEXSideNavigationStateVisible:
            if(cellSelectedIndex == 1) {
                [self addPlayerObserver];
            }
            [_videoPlayerInterface setShouldRotate:YES];
            break;
        case OEXSideNavigationStateHidden:
            [_videoPlayerInterface.moviePlayerController setFullscreen:NO];
            [_videoPlayerInterface setShouldRotate:NO];
            [self removePlayerObserver];
            [_videoPlayerInterface.moviePlayerController pause];
            break;
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    if(self.navigationController.topViewController != self) {
        [self.videoPlayerInterface.moviePlayerController pause];
    }

    [self removePlayerObserver];

    [[NSNotificationCenter defaultCenter] removeObserver:self name:OEXDownloadProgressChangedNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:DOWNLOAD_PROGRESS_NOTIFICATION object:nil];
}

- (void)addPlayerObserver {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playNextVideo) name:NOTIFICATION_NEXT_VIDEO object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playPreviousVideo) name:NOTIFICATION_PREVIOUS_VIDEO object:nil];

    //Add oserver
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(playbackStateChanged:)
                                                 name:MPMoviePlayerPlaybackStateDidChangeNotification object:_videoPlayerInterface.moviePlayerController];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(playbackEnded:)
                                                 name:MPMoviePlayerPlaybackDidFinishNotification object:_videoPlayerInterface.moviePlayerController];
}

- (void)removePlayerObserver {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NOTIFICATION_NEXT_VIDEO object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NOTIFICATION_PREVIOUS_VIDEO object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:MPMoviePlayerPlaybackStateDidChangeNotification object:_videoPlayerInterface.moviePlayerController];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:MPMoviePlayerPlaybackDidFinishNotification object:_videoPlayerInterface.moviePlayerController];
}

#pragma mark videoPlayer Delegate

- (void)movieTimedOut {
    if(!_videoPlayerInterface.moviePlayerController.isFullscreen) {
        [self showOverlayMessage:[Strings timeoutCheckInternetConnection]];
        [_videoPlayerInterface.moviePlayerController stop];
    }
    else {
        [self showAlert:OEXAlertTypeVideoTimeOutAlert];
    }
}

- (void) videoPlayerTapped:(UIGestureRecognizer *)sender {
    // TODO: Handle player tap
}

- (void)alertView:(UIAlertView*)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if(alertView.tag == 1001) {
        if(buttonIndex == 1) {
            [self playNextVideo];
        }
    }
    else if(alertView.tag == 1002) {
        if(buttonIndex == 1) {
            NSInteger deleteCount = 0;

            for(OEXHelperVideoDownload* selectedVideo in self.arr_SelectedObjects) {
                // make a copy of array to avoid GeneralException(updation of array in loop) - crashes app

                NSMutableArray* arrCopySubsection = [self.arr_CourseData mutableCopy];

                NSInteger index = -1;

                for(NSDictionary* dict in arrCopySubsection) {
                    index++;
                    NSMutableArray* arrvideos = [[dict objectForKey:CAV_KEY_RECENT_VIDEOS] mutableCopy];

                    for(OEXHelperVideoDownload* videos in arrvideos) {
                        if(selectedVideo == videos) {
                            [[[self.arr_CourseData objectAtIndex:index] objectForKey:CAV_KEY_RECENT_VIDEOS] removeObject:videos];

                            // remove for key CAV_KEY_VIDEOS also to maintain consistency.
                            // As it is unsorted array used to sort and put in array for key CAV_KEY_RECENT_VIDEOS

                            [[[self.arr_CourseData objectAtIndex:index] objectForKey:CAV_KEY_VIDEOS] removeObject:videos];

                            [[OEXInterface sharedInterface] deleteDownloadedVideoForVideoId:selectedVideo.summary.videoID completionHandler:^(BOOL success) {
                                selectedVideo.downloadState = OEXDownloadStateNew;
                                selectedVideo.downloadProgress = 0.0;
                                selectedVideo.isVideoDownloading = NO;
                            }];

                            deleteCount++;
                            // if no objects in a particular section then remove the array
                            if([[[self.arr_CourseData objectAtIndex:index] objectForKey:CAV_KEY_RECENT_VIDEOS] count] == 0) {
                                [self.arr_CourseData removeObject:dict];
                            }
                        }
                    }
                }
            }

            // if no objects to show
            if([self.arr_CourseData count] == 0) {
                self.btn_SelectAllEditing.hidden = YES;
                self.btn_SelectAllEditing.checked = NO;
                self.isTableEditing = NO;
                [self.recentEditViewHeight setConstant:0.0];
                self.lbl_NoVideo.hidden = NO;
                self.table_RecentVideos.hidden = YES;
            }

            [self.table_RecentVideos reloadData];
            [self.table_MyVideos reloadData];

            // clear all objects form array after deletion.
            // To obtain correct count on next deletion process.
            [self.arr_SelectedObjects removeAllObjects];
        }

        [self cancelTableClicked:nil];
    }
    else if(alertView.tag == 1005 || alertView.tag == 1006) {
    }

    if(self.alertCount > 0) {
        self.alertCount = _alertCount - 1;
    }
    if(self.alertCount == 0) {
        [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
        [_videoPlayerInterface setShouldRotate:YES];
        [_videoPlayerInterface orientationChanged:nil];
    }
}

- (void)showAlert:(OEXAlertType )OEXAlertType {
    self.alertCount = _alertCount + 1;

    if(self.alertCount >= 1) {
        [[UIDevice currentDevice] endGeneratingDeviceOrientationNotifications];
        [_videoPlayerInterface setShouldRotate:NO];
    }

    switch(OEXAlertType) {
        case OEXAlertTypeDeleteConfirmationAlert: {
            NSString* message = [Strings confirmDeleteMessage:_arr_SelectedObjects.count];
            UIAlertView* alert = [[UIAlertView alloc] initWithTitle:[Strings confirmDeleteTitle]
                                                            message:[NSString stringWithFormat:message, _arr_SelectedObjects.count]
                                                           delegate:self
                                                  cancelButtonTitle:[Strings cancel]
                                                  otherButtonTitles:[Strings delete], nil];
            alert.tag = 1002;
            [alert show];
        }

        break;

        case OEXAlertTypeNextVideoAlert: {
            UIAlertView* alert = [[UIAlertView alloc] initWithTitle:[Strings playbackCompleteTitle]
                                                            message:[Strings playbackCompleteMessage]
                                                           delegate:self
                                                  cancelButtonTitle:[Strings playbackCompleteContinueCancel]
                                                  otherButtonTitles:[Strings playbackCompleteContinue], nil];
            alert.tag = 1001;
            alert.delegate = self;
            [alert show];
        }
        break;

        case OEXAlertTypePlayBackErrorAlert: {
            UIAlertView* alert = [[UIAlertView alloc] initWithTitle:[Strings videoContentNotAvailable]
                                                            message:nil
                                                           delegate:self
                                                  cancelButtonTitle:[Strings close]
                                                  otherButtonTitles:nil, nil];

            alert.tag = 1003;
            [alert show];
        }

        break;

        case OEXAlertTypeVideoTimeOutAlert: {
            UIAlertView* alert = [[UIAlertView alloc] initWithTitle:[Strings timeoutAlertTitle]
                                                            message:[Strings timeoutCheckInternetConnection]
                                                           delegate:self
                                                  cancelButtonTitle:[Strings ok]
                                                  otherButtonTitles:nil];
            alert.tag = 1004;
            [alert show];
        }
        break;

        case OEXAlertTypePlayBackContentUnAvailable: {
            UIAlertView* alert = [[UIAlertView alloc] initWithTitle:[Strings videoContentNotAvailable]
                                                            message:nil
                                                           delegate:self
                                                  cancelButtonTitle:[Strings close]
                                                  otherButtonTitles:nil];
            alert.tag = 1005;
            [alert show];
        }
        break;

        default:
            break;
    }
}

- (BOOL) isRTL {
    return [UIApplication sharedApplication].userInterfaceLayoutDirection == UIUserInterfaceLayoutDirectionRightToLeft;
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return [OEXStyles sharedStyles].standardStatusBarStyle;
}

- (BOOL)prefersStatusBarHidden {
    return self.videoPlayerInterface.moviePlayerController.fullscreen;
}

@end
