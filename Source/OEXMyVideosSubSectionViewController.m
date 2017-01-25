//
//  OEXMyVideosSubSectionViewController.m
//  edXVideoLocker
//
//  Created by Rahul Varma on 30/06/14.
//  Copyright (c) 2014-2016 edX. All rights reserved.
//

#import "OEXMyVideosSubSectionViewController.h"

#import "edX-Swift.h"

#import "NSArray+OEXSafeAccess.h"
#import "NSString+OEXFormatting.h"

#import "OEXAppDelegate.h"
#import "OEXCourse.h"
#import "OEXCourseVideosTableViewCell.h"
#import "OEXCustomLabel.h"
#import "OEXDataParser.h"
#import "OEXDateFormatting.h"
#import "OEXInterface.h"
#import "OEXHelperVideoDownload.h"
#import "OEXStyles.h"
#import "OEXUserDetails.h"
#import "OEXVideoPathEntry.h"
#import "OEXVideoPlayerInterface.h"
#import "OEXVideoSummary.h"
#import "OEXRouter.h"
#import "Reachability.h"
#import "OEXCustomEditingView.h"


#define HEADER_HEIGHT 80.0
#define SHIFT_LEFT 40.0
#define ORIGINAL_RIGHT_SPACE_PROGRESSBAR 8
#define VIDEO_VIEW_HEIGHT  225

typedef NS_ENUM (NSUInteger, OEXAlertType) {
    OEXAlertTypeNextVideoAlert,
    OEXAlertTypeDeleteConfirmationAlert,
    OEXAlertTypePlayBackErrorAlert,
    OEXAlertTypeCannotPlayVideo,
    OEXAlertTypeVideoTimeOutAlert,
    OEXAlertTypePlayBackContentUnAvailable
};

@interface OEXMyVideosSubSectionViewController () <UITableViewDelegate>
{
    NSIndexPath* clickedIndexpath;
}

@property(strong, nonatomic) OEXVideoPlayerInterface* videoPlayerInterface;
@property(strong, nonatomic) OEXHelperVideoDownload* currentTappedVideo;
@property(strong, nonatomic) NSURL* currentVideoURL;
@property(strong, nonatomic) NSIndexPath* selectedIndexPath;
@property(nonatomic, assign) BOOL isTableEditing;
@property(nonatomic, assign) BOOL selectAll;
@property (nonatomic, strong) NSMutableArray* arr_SelectedObjects;
@property (nonatomic, strong) OEXInterface* dataInterface;
@property (nonatomic, strong) NSMutableArray* arr_SubsectionData;
@property(nonatomic) NSInteger alertCount;

@property (weak, nonatomic) IBOutlet OEXCustomLabel* lbl_videoHeader;
@property (weak, nonatomic) IBOutlet OEXCustomLabel* lbl_videobottom;
@property (weak, nonatomic)  IBOutlet OEXCustomLabel* lbl_section;
@property (weak, nonatomic) IBOutlet UIView* video_containerView;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint* videoViewHeight;
@property   (weak, nonatomic) IBOutlet UIView* videoVideo;

@property (weak, nonatomic) IBOutlet UITableView* table_SubSectionVideos;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint* contraintEditingView;
@property (weak, nonatomic) IBOutlet OEXCustomEditingView* customEditing;

@property (strong, nonatomic) OEXCheckBox* selectAllButton;
@property (strong, nonatomic) ProgressController *progressController;

@end

@implementation OEXMyVideosSubSectionViewController

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    //Add oserver
    [self addObservers];

    if(_videoPlayerInterface) {
        [self.videoPlayerInterface videoPlayerShouldRotate];
    }

    // To clear already selected items when traverese back from Download screen.
    [self cancelTableClicked:nil];

    self.table_SubSectionVideos.separatorInset = UIEdgeInsetsZero;
#ifdef __IPHONE_8_0
    if(IS_IOS8) {
        [self.table_SubSectionVideos setLayoutMargins:UIEdgeInsetsZero];
    }
#endif
    
    [[OEXAnalytics sharedAnalytics] trackScreenWithName:OEXAnalyticsScreenMyVideosCourseVideos courseID:self.course.course_id value:nil];
}

- (void)navigateBack {
    [self cancelTableClicked:nil];
    [self removePlayerObserver];
    [self.videoPlayerInterface.moviePlayerController pause];
    [self.videoPlayerInterface.moviePlayerController setFullscreen:NO];
    [self.videoPlayerInterface resetPlayer];
    self.videoPlayerInterface.videoPlayerVideoView = nil;
    [self.videoPlayerInterface willMoveToParentViewController:nil];
    [self.videoPlayerInterface removeFromParentViewController];
    self.videoPlayerInterface = nil;
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)removePlayerObserver {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NOTIFICATION_NEXT_VIDEO object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NOTIFICATION_PREVIOUS_VIDEO object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:MPMoviePlayerPlaybackStateDidChangeNotification object:_videoPlayerInterface.moviePlayerController];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:MPMoviePlayerPlaybackDidFinishNotification object:_videoPlayerInterface.moviePlayerController];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.

    //set exclusive touch for all btns
    self.view.exclusiveTouch = YES;
    self.videoVideo.exclusiveTouch = YES;

    [self setTitle:self.course.name];
    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@" " style:UIBarButtonItemStylePlain target:self action:@selector(navigateBack)];

    self.dataInterface = self.environment.interface;
    
    //Init video view and video player
    self.videoPlayerInterface = [[OEXVideoPlayerInterface alloc] init];
    [self.videoPlayerInterface enableFullscreenAutorotation];
    [self addChildViewController:self.videoPlayerInterface];
    [self.videoPlayerInterface didMoveToParentViewController:self];
    _videoPlayerInterface.videoPlayerVideoView = self.videoVideo;
    self.videoViewHeight.constant = 0;
    self.videoVideo.exclusiveTouch = YES;
    
    //Set Navigation Buttons
    self.selectAllButton = [[OEXCheckBox alloc] initWithFrame:CGRectMake(0, 0, 40, 40)];
    [self.selectAllButton addTarget:self action:@selector(selectAllChanged:) forControlEvents:UIControlEventTouchUpInside];
    self.progressController = [[ProgressController alloc] initWithOwner:self router:self.environment.router dataInterface:self.environment.interface];
    self.navigationItem.rightBarButtonItem = [self.progressController navigationItem];
    [self.progressController hideProgessView];

    //Fix for 20px issue for the table view
    self.automaticallyAdjustsScrollViewInsets = NO;

    // Call to populate data
    [self getSubsectionVideoDataFromArray];

    // Used for autorotation
    [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];

    // Show Custom editing View
    [self.customEditing.btn_Edit addTarget:self action:@selector(editTableClicked:) forControlEvents:UIControlEventTouchUpInside];
    [self.customEditing.btn_Delete addTarget:self action:@selector(deleteTableClicked:) forControlEvents:UIControlEventTouchUpInside];
    [self.customEditing.btn_Cancel addTarget:self action:@selector(cancelTableClicked:) forControlEvents:UIControlEventTouchUpInside];
    self.selectAllButton.hidden = YES;
    self.selectAllButton.accessibilityLabel = [Strings accessibilitySelectAll];

    // set select all button color to white so it look prominent on blue navigation bar
    self.selectAllButton.tintColor = [[OEXStyles sharedStyles] navigationItemTintColor];
    
    self.isTableEditing = NO;           // Check Edit button is clicked
    self.selectAll = NO;        // Check if all are selected
    
}

- (void)addObservers {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playNextVideo) name:NOTIFICATION_NEXT_VIDEO object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playPreviousVideo) name:NOTIFICATION_PREVIOUS_VIDEO object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateTotalDownloadProgress:) name:OEXDownloadProgressChangedNotification object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(playbackStateChanged:)
                                                 name:MPMoviePlayerPlaybackStateDidChangeNotification object:_videoPlayerInterface.moviePlayerController];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(playbackEnded:)
                                                 name:MPMoviePlayerPlaybackDidFinishNotification object:_videoPlayerInterface.moviePlayerController];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(downloadCompleteNotification:)
                                                 name:OEXDownloadEndedNotification object:nil];
}

#pragma update total download progress

- (void)downloadCompleteNotification:(NSNotification*)notification {
    NSDictionary* dict = notification.userInfo;

    NSURLSessionTask* task = [dict objectForKey:VIDEO_DL_COMPLETE_N_TASK];
    NSURL* url = task.originalRequest.URL;

    if([OEXInterface isURLForVideo:url.absoluteString]) {
        [self getSubsectionVideoDataFromArray];
    }
}

- (void)updateTotalDownloadProgress:(NSNotification* )notification {
    [self updateNavigationItemButtons];
}

- (void)getSubsectionVideoDataFromArray {
    // Initialize array
    self.arr_CourseData = [[NSMutableArray alloc] init];

    // Initialize array of data to show on table
    self.arr_SubsectionData = [[NSMutableArray alloc] init];

    NSMutableArray* arrCourseAndVideo = [[NSMutableArray alloc] initWithArray: [_dataInterface coursesAndVideosForDownloadState:OEXDownloadStateComplete] ];

    /*
    <__NSArrayM 0x10c7a3e40>(

            {
                course = "<Course: 0x10c78f730>";
                videos =     (
                              "<HelperVideoDownload: 0x10c7aa6b0>"
                              );
            }

     )
    */

    for(NSDictionary* dict in arrCourseAndVideo) {
        OEXCourse* course = [dict objectForKey:CAV_KEY_COURSE];

        if([course.name isEqualToString:self.title]) {
            self.arr_CourseData = [dict objectForKey:CAV_KEY_VIDEOS];
        }
    }

    // arr_CourseData --> array of all HelperVideoDownload objects in clicked Course

    for(OEXHelperVideoDownload* video in self.arr_CourseData) {
        NSMutableArray* arr_section = [[NSMutableArray alloc] init];

        // Sorting the data with chapter name and section name
        for(OEXHelperVideoDownload* objvideo in self.arr_CourseData) {
            // Compare both chapter and section
            if([video.summary.chapterPathEntry isEqual:objvideo.summary.chapterPathEntry] && [video.summary.sectionPathEntry isEqual:objvideo.summary.sectionPathEntry]) {
                [arr_section addObject:objvideo];
            }
        }

        // To Remove the duplicate or rather not add it to the main array.
        // To avoid the re-arranging and other processing
        NSMutableArray* arr_CheckDup = [arr_section mutableCopy];

        for(OEXHelperVideoDownload* objvideoCheck in arr_CheckDup) {
            for(NSMutableArray* check in self.arr_SubsectionData) {
                for(OEXHelperVideoDownload* objV in check) {
                    if([objvideoCheck.summary.chapterPathEntry isEqual:objV.summary.chapterPathEntry] && [objvideoCheck.summary.sectionPathEntry isEqual:objV.summary.sectionPathEntry]) {
                        [arr_section removeObject:objvideoCheck];
                    }
                }
            }
        }

        if([arr_section count] > 0) {
            [self.arr_SubsectionData addObject:arr_section];
        }
    }
    [self.table_SubSectionVideos reloadData];
}

- (BOOL)ChapterNameAlreadyDisplayed:(NSInteger)section {
    OEXHelperVideoDownload* video = [[self.arr_SubsectionData oex_safeObjectAtIndex:section] oex_safeObjectAtIndex:0];

    //  Below for loop check to resolve MOB-447
    //  Multiple headers for the same Section appear in My Videos
    BOOL ChapnameExists = NO;
    int i;

    for(i = 0; i < section; i++) {
        OEXHelperVideoDownload* videoCompare = [[self.arr_SubsectionData objectAtIndex:i] objectAtIndex:0];

        if([video.summary.chapterPathEntry isEqual:videoCompare.summary.chapterPathEntry]) {
            ChapnameExists = YES;
        }
    }

    return ChapnameExists;
}

#pragma mark TableViewDataSourceDelegate

- (NSInteger)numberOfSectionsInTableView:(UITableView*)tableView {
    _selectedIndexPath = nil;
    return [self.arr_SubsectionData count];
}

- (NSInteger)tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section {
    return [[self.arr_SubsectionData objectAtIndex:section] count];
}

- (UIView*)tableView:(UITableView*)tableView viewForHeaderInSection:(NSInteger)section {
    if([[self.arr_SubsectionData objectAtIndex:section] count] == 0) {
        return nil;
    }

    OEXHelperVideoDownload* video = [[self.arr_SubsectionData objectAtIndex:section] objectAtIndex:0];

    BOOL ChapnameExists = [self ChapterNameAlreadyDisplayed:section];

    UIView* viewMain;
    UIView* viewTop;
    UIView* viewBottom;
    UILabel* chapTitle;
    UILabel* sectionTitle;

    NSString *headerTitle = video.summary.sectionPathEntry.name;
    if (!headerTitle.length) {
        headerTitle = [Strings untitled];
    }
    
    float mainViewWidth = SCREEN_WIDTH;
    
    if(ChapnameExists) {
        
        viewMain = [[UIView alloc] initWithFrame:CGRectMake(0, 0, mainViewWidth, 30 )];
        viewBottom = [[UIView alloc] initWithFrame:CGRectMake(0, 0, mainViewWidth, 30 )];
        viewBottom.backgroundColor = GREY_COLOR;
        [viewMain addSubview:viewBottom];

        sectionTitle = [[UILabel alloc] initWithFrame:CGRectMake(20, 0, mainViewWidth - 20, 30)];
        sectionTitle.text = headerTitle;
        sectionTitle.font = [[OEXStyles sharedStyles] semiBoldSansSerifOfSize:14.0f];
        sectionTitle.textColor = [UIColor blackColor];
        [viewMain addSubview:sectionTitle];
    }
    else {
        viewMain = [[UIView alloc] initWithFrame:CGRectMake(0, 0, mainViewWidth, HEADER_HEIGHT )];

        viewTop = [[UIView alloc] initWithFrame:CGRectMake(0, 0, mainViewWidth, 50 )];
        viewTop.backgroundColor = [UIColor colorWithRed:62.0 / 255.0 green:66.0 / 255.0 blue:71.0 / 255.0 alpha:1.0];
        [viewMain addSubview:viewTop];

        viewBottom = [[UIView alloc] initWithFrame:CGRectMake(0, 50, mainViewWidth, 30 )];
        viewBottom.backgroundColor = GREY_COLOR;
        [viewMain addSubview:viewBottom];

        NSString *chapterName = video.summary.chapterPathEntry.name;
        if (!chapterName.length) {
            chapterName = [Strings untitled];
        }
        
        chapTitle = [[UILabel alloc] initWithFrame:CGRectMake(20, 0, mainViewWidth - 20, 50)];
        chapTitle.text = chapterName;
        chapTitle.font = [[OEXStyles sharedStyles] semiBoldSansSerifOfSize:14.0f];
        chapTitle.textColor = [UIColor whiteColor];
        [viewMain addSubview:chapTitle];

        sectionTitle = [[UILabel alloc] initWithFrame:CGRectMake(20, 50, mainViewWidth - 20, 30)];
        sectionTitle.text = headerTitle;
        sectionTitle.font = [[OEXStyles sharedStyles] semiBoldSansSerifOfSize:14.0f];
        sectionTitle.textColor = [UIColor blackColor];
        [viewMain addSubview:sectionTitle];
    }

    return viewMain;
}

- (CGFloat)tableView:(UITableView*)tableView heightForHeaderInSection:(NSInteger)section {
    BOOL ChapnameExists = [self ChapterNameAlreadyDisplayed:section];

    if(ChapnameExists) {
        return 30;
    }
    else {
        return HEADER_HEIGHT;
    }
}

- (UITableViewCell*)tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath {
    static NSString* cellIndentifier = @"CellCourseVideo";

    OEXCourseVideosTableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:cellIndentifier];

    NSArray* videos = [self.arr_SubsectionData objectAtIndex:indexPath.section];
    cell.btn_Download.hidden = YES;
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

    if(self.isTableEditing) {
        // Unhide the checkbox and set the tag
        cell.btn_CheckboxDelete.hidden = NO;
        if ([self isRTL]) {
            cell.subSectionCourseVideoStateLeadingConstraint.constant = 60;
        }
        cell.btn_CheckboxDelete.tag = (indexPath.section * 100) + indexPath.row;
        [cell.btn_CheckboxDelete addTarget:self action:@selector(selectCheckbox:) forControlEvents:UIControlEventTouchUpInside];

        // Toggle between selected and unselected checkbox
        cell.btn_CheckboxDelete.checked = obj_video.isSelected;
    }
    else {
        cell.btn_CheckboxDelete.hidden = YES;
        cell.btn_CheckboxDelete.hidden = YES;
        cell.subSectionCourseVideoStateLeadingConstraint.constant = 10;
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

- (void)tableView:(UITableView*)tableView willDisplayCell:(UITableViewCell*)cell forRowAtIndexPath:(NSIndexPath*)indexPath {
    UIView* backview = [[UIView alloc] initWithFrame:CGRectMake(0, 0, tableView.frame.size.width, 50)];
    [backview setBackgroundColor:SELECTED_CELL_COLOR];
    cell.selectedBackgroundView = backview;
    if(indexPath == _selectedIndexPath) {
        [cell setSelected:YES animated:NO];
    }
}

- (void)setSelectedCellAtIndexPath:(NSIndexPath*)indexPath tableView:(UITableView*)tableView {
    UITableViewCell* cell = [tableView cellForRowAtIndexPath:indexPath];
    [cell setSelected:YES animated:YES];
}

- (void)tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath {
    // To avoid showing selected cell index of old video when new video is played
    _dataInterface.selectedCCIndex = -1;
    _dataInterface.selectedVideoSpeedIndex = -1;

    clickedIndexpath = indexPath;

    if(!_isTableEditing) {
        // To check and diable the Previous button on the player
        [self CheckIfFirstVideoPlayed:indexPath];

        // To check and diable the NExt button on the player
        [self CheckIfLastVideoPlayed:indexPath];

        [tableView reloadRowsAtIndexPaths:[NSArray arrayWithObjects:_selectedIndexPath, nil] withRowAnimation:UITableViewRowAnimationNone];
        _selectedIndexPath = indexPath;

        [self playVideoForIndexPath:indexPath];
    }

    [tableView reloadData];
}

- (void)playVideoForIndexPath:(NSIndexPath*)indexPath {
    NSArray* videos = [self.arr_SubsectionData objectAtIndex:indexPath.section];

    OEXHelperVideoDownload* obj = [videos objectAtIndex:indexPath.row];

    // Set the path of the downloaded videos
    [_dataInterface downloadAllTranscriptsForVideo:obj];

    //stop current video
    [_videoPlayerInterface.moviePlayerController stop];

    self.currentTappedVideo = obj;
    self.currentVideoURL = [NSURL fileURLWithPath:self.currentTappedVideo.filePath];
    self.lbl_videoHeader.text = [NSString stringWithFormat:@"%@ ", self.currentTappedVideo.summary.name];
    self.lbl_videobottom.text = [NSString stringWithFormat:@"%@ ", obj.summary.name];
    self.lbl_section.text = [NSString stringWithFormat:@"%@\n%@", self.currentTappedVideo.summary.sectionPathEntry.name, self.currentTappedVideo.summary.chapterPathEntry.name];
    [self.table_SubSectionVideos deselectRowAtIndexPath:indexPath animated:NO];
    self.contraintEditingView.constant = 0;
    [self handleComponentsFrame];
    [_videoPlayerInterface playVideoFor:obj];

    // Send Analytics
    [_dataInterface sendAnalyticsEvents:OEXVideoStatePlay withCurrentTime:self.videoPlayerInterface.moviePlayerController.currentPlaybackTime forVideo:self.currentTappedVideo];
}

- (void)handleComponentsFrame {
    [UIView animateWithDuration:ANIMATION_DURATION animations:^{
        self.videoViewHeight.constant = VIDEO_VIEW_HEIGHT;
        [self.view layoutIfNeeded];
    } completion:^(BOOL finished) {
    }];
}

- (void)playbackStateChanged:(NSNotification*)notification {
    switch([_videoPlayerInterface.moviePlayerController playbackState])
    {
        case MPMoviePlaybackStateStopped:
            break;
        case MPMoviePlaybackStatePlaying:

            if(_currentTappedVideo.watchedState == OEXPlayedStateWatched) {
            }
            else {
                //Buffering view

                if(_currentTappedVideo.watchedState != OEXPlayedStatePartiallyWatched) {
                    [_dataInterface markVideoState:OEXPlayedStatePartiallyWatched
                                          forVideo:_currentTappedVideo];
                }
                _currentTappedVideo.watchedState = OEXPlayedStatePartiallyWatched;
            }

            break;
            break;
        case MPMoviePlaybackStatePaused:
            break;
        case MPMoviePlaybackStateInterrupted:
            break;
        case MPMoviePlaybackStateSeekingForward:
            break;
        case MPMoviePlaybackStateSeekingBackward:
            break;
        default:
            break;
    }
    [self.table_SubSectionVideos reloadData];
}

- (void)markPlayedStateOnVideoStopped {
    int currentTime = self.videoPlayerInterface.moviePlayerController.currentPlaybackTime;
    int totalTime = self.videoPlayerInterface.moviePlayerController.duration;

    if(currentTime == totalTime && totalTime > 0) {
        self.videoPlayerInterface.moviePlayerController.currentPlaybackTime = 0.0;

        _currentTappedVideo.watchedState = OEXPlayedStateWatched;
        [_dataInterface markVideoState:OEXPlayedStateWatched
                              forVideo:_currentTappedVideo];

        [self.table_SubSectionVideos reloadData];
    }
}

- (void)playbackEnded:(NSNotification*)notification {
    int reason = [[[notification userInfo] valueForKey:MPMoviePlayerPlaybackDidFinishReasonUserInfoKey] intValue];
    if(reason == MPMovieFinishReasonPlaybackEnded) {
        [self markPlayedStateOnVideoStopped];
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
        [self tableView:self.table_SubSectionVideos didSelectRowAtIndexPath:indexPath];
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
            NSInteger rowcount = [self.table_SubSectionVideos numberOfRowsInSection:section - 1];
            indexPath = [NSIndexPath indexPathForRow:rowcount - 1 inSection:section - 1];
        }
    }

    return indexPath;
}

#pragma mark - Implement next video play functionality

- (void)CheckIfLastVideoPlayed:(NSIndexPath*)indexPath {
    NSInteger totalSections = [self.table_SubSectionVideos numberOfSections];
    // get last index of the table
    NSInteger totalRows = [self.table_SubSectionVideos numberOfRowsInSection:totalSections - 1];

    if(indexPath.section == totalSections - 1 && indexPath.row == totalRows - 1) {
        // Post notification to hide the next button
        // We are playing the last video
        [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_HIDE_PREV_NEXT object:self userInfo:@{KEY_DISABLE_NEXT: @"YES"}];
    }
    else {
        // Not the last video id playing.
        [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_HIDE_PREV_NEXT object:self userInfo:@{KEY_DISABLE_NEXT: @"NO"}];
    }
}

- (void)playNextVideo {
    NSIndexPath* indexPath = [self getNextVideoIndex];
    if(indexPath) {
        [self CheckIfLastVideoPlayed:indexPath];

        [self tableView:self.table_SubSectionVideos didSelectRowAtIndexPath:indexPath];
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

    NSInteger totalSection = [self.table_SubSectionVideos numberOfSections];

    // Check for the last video in the list
    if(currentIndexPath.section >= (totalSection - 1)) {
        NSInteger rowcount = [self.table_SubSectionVideos numberOfRowsInSection:totalSection - 1];
        if(currentIndexPath.row >= rowcount - 1) {
            return nil;
        }
    }
    // If there are more than one section in the table
    if([self.table_SubSectionVideos numberOfSections] > 1) {
        NSInteger rowcount = [self.table_SubSectionVideos numberOfRowsInSection:section];

        if(row + 1 < rowcount) {
            indexPath = [NSIndexPath indexPathForRow:row + 1 inSection:section];
        }
        else {
            NSInteger sectionCount = [self.table_SubSectionVideos numberOfSections];

            if(section + 1 < sectionCount) {
                indexPath = [NSIndexPath indexPathForRow:0 inSection:section + 1];
            }
        }
    }
    else {
        // If there is only one section in the table

        NSInteger rowcount = [self.table_SubSectionVideos numberOfRowsInSection:section];
        if(row + 1 < rowcount) {
            indexPath = [NSIndexPath indexPathForRow:row + 1 inSection:section];
        }
    }

    return indexPath;
}

/// get  current video indexPath

- (NSIndexPath*)getCurrentIndexPath {
    if([self.table_SubSectionVideos numberOfSections] > 1) {
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

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    if(self.navigationController.topViewController != self) {
        [self.videoPlayerInterface.moviePlayerController pause];
    }

    [self removePlayerObserver];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kReachabilityChangedNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:OEXDownloadEndedNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:OEXDownloadProgressChangedNotification object:nil];
}

#pragma mark - USED WHILE EDITING

- (void)cancelTableClicked:(id)sender {
    // set isSelected to NO for all the objects
    for(NSArray* arr in self.arr_SubsectionData) {
        for(OEXHelperVideoDownload* videos in arr) {
            videos.isSelected = NO;
        }
    }

    [self.arr_SelectedObjects removeAllObjects];

    [self disableDeleteButton];

    [self hideComponentsOnEditing:NO];
    [self.table_SubSectionVideos reloadData];
}

- (void)hideComponentsOnEditing:(BOOL)hide {
    self.isTableEditing = hide;
    self.selectAllButton.hidden = !hide;

    self.customEditing.btn_Edit.hidden = hide;
    self.customEditing.btn_Cancel.hidden = !hide;
    self.customEditing.btn_Delete.hidden = !hide;
    self.customEditing.imgSeparator.hidden = !hide;

    self.selectAll = NO;
    
    [self updateNavigationItemButtons];
}

- (void)deleteTableClicked:(id)sender {
    if(_arr_SelectedObjects.count > 0) {
        [self showAlert:OEXAlertTypeDeleteConfirmationAlert];
    }
    else {
    }
}

- (void)pop {
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)editTableClicked:(id)sender {
    self.arr_SelectedObjects = [[NSMutableArray alloc] init];

    [self hideComponentsOnEditing:YES];

    [self.table_SubSectionVideos reloadData];
}

- (void)selectCheckbox:(id)sender {
    NSInteger section = ([sender tag]) / 100;
    NSInteger row = ([sender tag]) % 100;

    NSArray* videos = [self.arr_SubsectionData objectAtIndex:section];

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

    [self.table_SubSectionVideos reloadData];
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

    for(NSArray* arr in self.arr_SubsectionData) {
        for(OEXHelperVideoDownload* videos in arr) {
            if(!videos.isSelected) {
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
    self.selectAllButton.checked = self.selectAll;
}

- (IBAction)selectAllChanged:(id)sender {
    if(self.selectAll) {
        // de-select all the videos to delete

        self.selectAll = NO;

        for(NSArray* arr in self.arr_SubsectionData) {
            for(OEXHelperVideoDownload* videos in arr) {
                videos.isSelected = NO;
                [self.arr_SelectedObjects removeObject:videos];
            }
        }
    }
    else {
        // remove all objects to avoids number problem
        [self.arr_SelectedObjects removeAllObjects];

        // select all the videos to delete

        self.selectAll = YES;

        for(NSArray* arr in self.arr_SubsectionData) {
            for(OEXHelperVideoDownload* videos in arr) {
                videos.isSelected = YES;
                [self.arr_SelectedObjects addObject:videos];
            }
        }
    }

    [self.table_SubSectionVideos reloadData];

    [self disableDeleteButton];
}

- (void)updateNavigationItemButtons {
    NSMutableArray *barButtons = [[NSMutableArray alloc] init];
    if(_isTableEditing) {
        [barButtons addObject:[[UIBarButtonItem alloc] initWithCustomView:self.selectAllButton]];
    }
    if(![self.progressController progressView].hidden){
        [barButtons addObject:[self.progressController navigationItem]];
    }
    if(barButtons.count != self.navigationItem.rightBarButtonItems.count) {
        self.navigationItem.rightBarButtonItems = barButtons;
    }
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
                NSMutableArray* arrCopySubsection = [self.arr_SubsectionData copy];

                for(NSMutableArray* arr in arrCopySubsection) {
                    NSMutableArray* arrCopy = [arr copy];

                    for(OEXHelperVideoDownload* videos in arrCopy) {
                        if(selectedVideo == videos) {
                            [arr removeObject:videos];

                            [[OEXInterface sharedInterface] deleteDownloadedVideoForVideoId:selectedVideo.summary.videoID completionHandler:^(BOOL success) {
                                selectedVideo.downloadState = OEXDownloadStateNew;
                                selectedVideo.downloadProgress = 0.0;
                                selectedVideo.isVideoDownloading = NO;
                            }];
                            deleteCount++;

                            // if no objects in a particular section then remove the array
                            if([arr count] == 0) {
                                [self.arr_SubsectionData removeObject:arr];
                            }
                        }
                    }
                }
            }

            // if no objects to show
            if([self.arr_SubsectionData count] == 0) {
                self.selectAllButton.hidden = YES;
                [self performSelector:@selector(pop) withObject:nil afterDelay:1.0];
            }
            else {
                // clear all objects form array after deletion.
                // To obtain correct count on next deletion process.

                [self.arr_SelectedObjects removeAllObjects];

                [self.table_SubSectionVideos reloadData];
            }

            [self cancelTableClicked:nil];
        }
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

        case OEXAlertTypeDeleteConfirmationAlert: {
            NSString* message = [Strings confirmDeleteMessage:_arr_SelectedObjects.count];
            UIAlertView* alert = [[UIAlertView alloc] initWithTitle:[Strings confirmDeleteTitle]
                                                            message:message
                                                           delegate:self
                                                  cancelButtonTitle:[Strings cancel]
                                                  otherButtonTitles:[Strings delete], nil];
            alert.tag = 1002;
            [alert show];
        }
        break;

        case OEXAlertTypePlayBackErrorAlert: {
            UIAlertView* alert = [[UIAlertView alloc] initWithTitle:[Strings videoContentNotAvailable]
                                                            message:nil
                                                           delegate:self
                                                  cancelButtonTitle:[Strings close]
                                                  otherButtonTitles:nil];

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

#pragma mark - Actions

- (UIStatusBarStyle)preferredStatusBarStyle {
    return [OEXStyles sharedStyles].standardStatusBarStyle;
}

- (BOOL)prefersStatusBarHidden {
    return self.videoPlayerInterface.moviePlayerController.fullscreen;
}

@end
