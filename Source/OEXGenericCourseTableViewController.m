//
//  OEXGenericCourseTableViewController.m
//  edXVideoLocker
//
//  Created by Rahul Varma on 26/05/14.
//  Copyright (c) 2014 edX. All rights reserved.
//

#import "OEXGenericCourseTableViewController.h"

#import "DACircularProgressView.h"
#import "edX-Swift.h"

#import "NSArray+OEXSafeAccess.h"
#import "NSString+OEXFormatting.h"

#import "OEXAnalytics.h"
#import "OEXAppDelegate.h"
#import "OEXAuthentication.h"
#import "OEXCourseVideoDownloadTableViewController.h"
#import "OEXCustomNavigationView.h"
#import "OEXCourseDetailTableViewCell.h"
#import "OEXDataParser.h"
#import "OEXDownloadViewController.h"
#import "OEXOpenInBrowserViewController.h"
#import "OEXStatusMessageViewController.h"
#import "OEXHelperVideoDownload.h"
#import "OEXUserDetails.h"
#import "OEXVideoPathEntry.h"
#import "OEXVideoSummary.h"
#import "OEXRouter.h"

#import "Reachability.h"

@interface OEXGenericCourseTableViewController () <OEXStatusMessageControlling>

@property (nonatomic, weak) OEXInterface* dataInterface;
@property (weak, nonatomic) IBOutlet UIView* containerView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint* containerHeightConstraint;
@property (nonatomic, strong) NSString* OpenInBrowser_URL;
// get open in browser URL
@property (nonatomic, strong) OEXOpenInBrowserViewController* browser;
@property (weak, nonatomic) IBOutlet UITableView* table_Generic;
@property (weak, nonatomic) IBOutlet OEXCustomNavigationView* customNavView;
@property (weak, nonatomic) IBOutlet DACircularProgressView* customProgressBar;
@property (weak, nonatomic) IBOutlet UIButton* btn_Downloads;

@end

@implementation OEXGenericCourseTableViewController

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:OEXDownloadProgressChangedNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kReachabilityChangedNotification object:nil];
}

#pragma mark Status Messages

- (CGFloat)verticalOffsetForStatusController:(OEXStatusMessageViewController*)controller {
    return CGRectGetMaxY(self.customNavView.frame);
}

- (NSArray*)overlayViewsForStatusController:(OEXStatusMessageViewController*)controller {
    NSMutableArray* result = [[NSMutableArray alloc] init];
    [result oex_safeAddObjectOrNil:self.customNavView];
    [result oex_safeAddObjectOrNil:self.customProgressBar];
    [result oex_safeAddObjectOrNil:self.btn_Downloads];
    return result;
}

#pragma mark - REACHABILITY

- (void)HideOfflineLabel:(BOOL)isOnline {
    self.customNavView.lbl_Offline.hidden = isOnline;
    self.customNavView.view_Offline.hidden = isOnline;
    [self showBrowserView:isOnline];

    [self.customNavView adjustPositionIfOnline:isOnline];
}

- (void)reachabilityDidChange:(NSNotification*)notification {
    id <Reachability> reachability = [notification object];

    if([reachability isReachable]) {
        _dataInterface.reachable = YES;

        [self HideOfflineLabel:YES];
    }
    else {
        _dataInterface.reachable = NO;

        [self HideOfflineLabel:NO];

        if([self.navigationController topViewController] == self) {
            [self.navigationController popViewControllerAnimated:YES];
        }
    }
}

- (IBAction)downloadButtonPressed:(id)sender {
    [[OEXRouter sharedRouter] showDownloadsFromViewController:self];
}


- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:true animated:animated];

    // Add Observer
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reachabilityDidChange:) name:kReachabilityChangedNotification object:nil];

    // Check Reachability for OFFLINE
    if(_dataInterface.reachable) {
        [self HideOfflineLabel:YES];
    }
    else {
        [self HideOfflineLabel:NO];
    }

    // Add Open In Browser to the view and adjust the table accordingly
    self.containerHeightConstraint.constant = OPEN_IN_BROWSER_HEIGHT;
    [[OEXOpenInBrowserViewController sharedInstance] addViewToContainerSuperview:self.containerView];
}

- (void)showBrowserView:(BOOL)isShown {
    if(isShown && _browser.str_browserURL) {
        if([_browser.str_browserURL length] == 0) {
            self.containerHeightConstraint.constant = 0;
            [self.view layoutIfNeeded];
        }
        else {
            self.containerHeightConstraint.constant = OPEN_IN_BROWSER_HEIGHT;
            [self.view layoutIfNeeded];
        }
    }
    else {
        self.containerHeightConstraint.constant = 0;
        [self.view layoutIfNeeded];
    }
}

- (void)navigateBack {
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)viewDidLoad {
    [super viewDidLoad];

    // Initialize the interface for API calling
    self.dataInterface = [OEXInterface sharedInterface];

    // set Back button name to blank.
    self.navigationController.navigationBar.topItem.title = @"";

    //Fix for 20px issue for the table view
    self.automaticallyAdjustsScrollViewInsets = NO;

    // set the custom navigation view properties
    self.customNavView.lbl_TitleView.text = self.selectedChapter.name;
    [self.customNavView.btn_Back addTarget:self action:@selector(navigateBack) forControlEvents:UIControlEventTouchUpInside];

    //set custom progress bar properties

    [self.customProgressBar setProgressTintColor:PROGRESSBAR_PROGRESS_TINT_COLOR];

    [self.customProgressBar setTrackTintColor:PROGRESSBAR_TRACK_TINT_COLOR];

    [self.customProgressBar setProgress:_dataInterface.totalProgress animated:YES];

    //Add oserver

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateTotalDownloadProgress:) name:OEXDownloadProgressChangedNotification object:nil];

    [[self.dataInterface progressViews] addObject:self.customProgressBar];
    [[self.dataInterface progressViews] addObject:self.btn_Downloads];
    [self.customProgressBar setHidden:YES];
    [self.btn_Downloads setHidden:YES];

    _browser = [OEXOpenInBrowserViewController sharedInstance];

#ifdef __IPHONE_8_0
    if(IS_IOS8) {
        [self.table_Generic setLayoutMargins:UIEdgeInsetsZero];
    }
#endif
}

#pragma update total download progress

- (void)updateTotalDownloadProgress:(NSNotification* )notification {
    [self.customProgressBar setProgress:_dataInterface.totalProgress animated:YES];
    [self performSelector:@selector(reloadTableOnMainThread) withObject:nil afterDelay:1.5];
}

- (void)reloadTableOnMainThread {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.table_Generic reloadData];
    });
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView*)tableView {
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    return [self.arr_TableCourseData count];
}

- (CGFloat)tableView:(UITableView*)tableView heightForRowAtIndexPath:(NSIndexPath*)indexPath {
    return 44;
}

- (UITableViewCell*)tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath {
    OEXCourseDetailTableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:@"CellCourseDetail" forIndexPath:indexPath];

    OEXVideoPathEntry* section = [self.arr_TableCourseData oex_safeObjectAtIndex:indexPath.row];
    cell.lbl_Title.text = section.name;

    NSMutableArray* arr_Videos = [_dataInterface videosForChapterID:self.selectedChapter.entryID sectionID:section.entryID URL:self.course.video_outline];

    cell.lbl_Count.text = [NSString stringWithFormat:@"%lu", (unsigned long)arr_Videos.count];
    cell.btn_Download.tag = indexPath.row;
    [cell.btn_Download addTarget:self action:@selector(startDownloadSectionVideos:) forControlEvents:UIControlEventTouchUpInside];

    // check if all videos in that section are downloaded.

    [cell.customProgressBar setProgressTintColor:PROGRESSBAR_PROGRESS_TINT_COLOR];
    [cell.customProgressBar setTrackTintColor:PROGRESSBAR_TRACK_TINT_COLOR];
    cell.customProgressBar.hidden = YES;

    for(OEXHelperVideoDownload* videosDownloaded in arr_Videos) {
        if(videosDownloaded.downloadState == OEXDownloadStateNew) {
            cell.btn_Download.hidden = NO;
            break;
        }
        else {
            cell.btn_Download.hidden = YES;
        }

        if([cell.btn_Download isHidden]) {
            float progress = [_dataInterface showBulkProgressViewForCourse:self.course chapterID:self.selectedChapter.entryID sectionID:section.entryID];

            if(progress < 0 || progress >= 1) {
                cell.customProgressBar.hidden = YES;
            }
            else {
                cell.customProgressBar.hidden = NO;
                cell.customProgressBar.progress = progress;
            }
        }
    }

#ifdef  __IPHONE_8_0
    if(IS_IOS8) {
        [cell setLayoutMargins:UIEdgeInsetsZero];
    }
#endif

    return cell;
}

#pragma mark TableViewDelegate

- (void)tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath {
    OEXVideoPathEntry* section = [self.arr_TableCourseData oex_safeObjectAtIndex:indexPath.row];
    NSArray* downloadProgress = [_dataInterface videosForChapterID:self.selectedChapter.entryID sectionID:section.entryID URL:self.course.video_outline];
    [[OEXRouter sharedRouter] showCourseVideoDownloadsFromViewController:self forCourse:self.course lastAccessedVideo:nil downloadProgress:downloadProgress selectedPath:@[self.selectedChapter, section]];
    [self.table_Generic deselectRowAtIndexPath:indexPath animated:YES];
}

- (void)startDownloadSectionVideos:(id)sender {
    OEXAppDelegate* appD = [[UIApplication sharedApplication] delegate];

    if([OEXInterface shouldDownloadOnlyOnWifi]) {
        if(![appD.reachability isReachableViaWiFi]) {
            [[OEXStatusMessageViewController sharedInstance]
             showMessage:[Strings noWifiMessage] onViewController:self
            ];

            return;
        }
    }

    NSInteger tagValue = [sender tag];
    OEXVideoPathEntry* section = [self.arr_TableCourseData oex_safeObjectAtIndex:tagValue];
    NSArray* videos = [_dataInterface videosForChapterID:self.selectedChapter.entryID sectionID:section.entryID URL:self.course.video_outline];

    int count = 0;
    NSMutableArray* validArray = [[NSMutableArray alloc] init];
    for(OEXHelperVideoDownload* video in videos) {
        if(video.downloadState == OEXDownloadStateNew) {
            count++;
            [validArray addObject:video];
        }
    }

    // Analytics Bulk Video Download From SubSection
    if(self.course.course_id) {
        OEXVideoPathEntry* section = [self.arr_TableCourseData oex_safeObjectAtIndex:tagValue];
        [[OEXAnalytics sharedAnalytics] trackSubSectionBulkVideoDownload: self.selectedChapter.entryID
                                                              Subsection: section.entryID
                                                                CourseID: self.course.course_id
                                                              VideoCount: [validArray count]];
    }

    NSInteger downloadingCount = [_dataInterface downloadVideos:validArray];

    if(downloadingCount > 0) {
        NSString* message = [Strings videosDownloadingWithCount:downloadingCount formatted:nil];
        [[OEXStatusMessageViewController sharedInstance] showMessage:message onViewController:self];
        [self.table_Generic reloadData];
    }
    else {
        [[OEXStatusMessageViewController sharedInstance] showMessage:[Strings unableToDownload] onViewController:self];
    }
}

@end
