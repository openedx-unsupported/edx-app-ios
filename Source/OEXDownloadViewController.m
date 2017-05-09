//
//  OEXDownloadViewController.m
//  edXVideoLocker
//
//  Created by Rahul Varma on 13/06/14.
//  Copyright (c) 2014-2015 edX. All rights reserved.
//

#import "OEXDownloadViewController.h"

#import "edX-Swift.h"

#import "NSString+OEXFormatting.h"
#import "OEXAppDelegate.h"
#import "OEXCustomLabel.h"
#import "OEXDateFormatting.h"
#import "OEXDownloadTableCell.h"
#import "OEXOpenInBrowserViewController.h"
#import "OEXHelperVideoDownload.h"
#import "OEXInterface.h"
#import "OEXNetworkConstants.h"
#import "OEXRouter.h"
#import "OEXStyles.h"
#import "OEXVideoSummary.h"
#import "Reachability.h"
#import "SWRevealViewController.h"
#import "OEXCustomButton.h"

#define RECENT_DOWNLOADEDVIEW_HEIGHT 76

@interface OEXDownloadViewController ()

@property(strong, nonatomic) NSMutableArray* arr_downloadingVideo;
@property(strong, nonatomic) OEXInterface* edxInterface;
@property (strong, nonatomic) IBOutlet UITableView* table_Downloads;
@property (strong, nonatomic) IBOutlet OEXCustomButton *btn_View;
@property (strong, nonatomic) NSNumberFormatter* percentFormatter;
@end

@implementation OEXDownloadViewController

- (IBAction)navigateToDownloadedVideos {
    [[OEXRouter sharedRouter] showMyVideos];
}

#pragma mark - REACHABILITY

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:NO animated:animated];
    [[OEXAnalytics sharedAnalytics] trackScreenWithName:OEXAnalyticsScreenDownloads];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:DOWNLOAD_PROGRESS_NOTIFICATION object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:OEXDownloadEndedNotification object:nil];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self downloadCompleteNotification:nil];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [[UIDevice currentDevice] endGeneratingDeviceOrientationNotifications];
    
    // Do any additional setup after loading the view.
#ifdef __IPHONE_8_0
    if(IS_IOS8) {
        [self.table_Downloads setLayoutMargins:UIEdgeInsetsZero];
    }
#endif

    //Initialize Downloading arr
    self.arr_downloadingVideo = [[NSMutableArray alloc] init];

    _edxInterface = [OEXInterface sharedInterface];

    [self reloadDownloadingVideos];

    // set the custom navigation view properties
    self.title = [Strings downloads];

    //Listen to notification
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(downloadProgressNotification:) name:DOWNLOAD_PROGRESS_NOTIFICATION object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(downloadCompleteNotification:)
                                                 name:OEXDownloadEndedNotification object:nil];
    
    [self.btn_View setClipsToBounds:true];
    self.percentFormatter = [[NSNumberFormatter alloc] init];
    self.percentFormatter.numberStyle = NSNumberFormatterPercentStyle;
    
}

- (void)reloadDownloadingVideos {
    [self.arr_downloadingVideo removeAllObjects];

    NSArray* array = [_edxInterface coursesAndVideosForDownloadState:OEXDownloadStatePartial];

    NSMutableDictionary* duplicationAvoidingDict = [[NSMutableDictionary alloc] init];

    for(NSDictionary* dict in array) {
        NSArray* array = [dict objectForKey:CAV_KEY_VIDEOS];

        for(OEXHelperVideoDownload* video in array) {
            if(video.downloadProgress < OEXMaxDownloadProgress) {
                [self.arr_downloadingVideo addObject:video];
                if (video != nil && video.summary != nil) {
                    NSString* key = video.summary.videoURL;
                    if (key) {
                        duplicationAvoidingDict[key] = @"object";
                    }
                }
            }
        }
    }

    [self.table_Downloads reloadData];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView*)tableView {
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    return [self.arr_downloadingVideo count];
}

- (CGFloat)tableView:(UITableView*)tableView heightForRowAtIndexPath:(NSIndexPath*)indexPath {
    return 78;
}

- (UITableViewCell*)tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath {
    OEXDownloadTableCell* cell = [tableView dequeueReusableCellWithIdentifier:@"CellDownloads" forIndexPath:indexPath];

    [self configureCell:cell forIndexPath:indexPath];
#ifdef __IPHONE_8_0
    if(IS_IOS8) {
        [cell setLayoutMargins:UIEdgeInsetsZero];
    }
#endif

    return cell;
}

- (void)tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (void)configureCell:(OEXDownloadTableCell*)cell forIndexPath:(NSIndexPath*)indexPath {
    if([self.arr_downloadingVideo count] > indexPath.row) {
        OEXHelperVideoDownload* downloadingVideo = [self.arr_downloadingVideo objectAtIndex:indexPath.row];

        
        NSString* videoName = downloadingVideo.summary.name;
        if([videoName length] == 0) {
            videoName = @"(Untitled)";
        }
        cell.lbl_title.text = videoName;

        if(!downloadingVideo.summary.duration) {
            cell.lbl_time.text = @"NA";
        }
        else {
            cell.lbl_time.text = [OEXDateFormatting formatSecondsAsVideoLength: downloadingVideo.summary.duration];
        }

        float result = (([downloadingVideo.summary.size doubleValue] / 1024) / 1024);
        cell.lbl_totalSize.text = [NSString stringWithFormat:@"%.2fMB", result];
        float progress = (float)downloadingVideo.downloadProgress;
        [cell.progressView setProgress:progress];
        //
        cell.btn_cancel.tag = indexPath.row;
        cell.btn_cancel.accessibilityLabel = [Strings cancel];

        [cell.btn_cancel addTarget:self action:@selector(btnCancelPressed:) forControlEvents:UIControlEventTouchUpInside];
        
        cell.accessibilityLabel = [self downloadStatusAccessibilityLabelForVideoName:videoName percentComplete:(progress / OEXMaxDownloadProgress)];
    }
}

- (void)tableView:(UITableView*)tableView willDisplayCell:(OEXDownloadTableCell*)cell forRowAtIndexPath:(NSIndexPath*)indexPath {
    OEXHelperVideoDownload* downloadingVideo = [self.arr_downloadingVideo objectAtIndex:indexPath.row];
    float progress = (float)downloadingVideo.downloadProgress / OEXMaxDownloadProgress;
    [cell.progressView setProgress:progress];
}

- (void)downloadProgressNotification:(NSNotification*)notification {
    dispatch_async(dispatch_get_main_queue(), ^(void){
        @autoreleasepool {
            NSDictionary* progress = (NSDictionary*)notification.userInfo;
            NSURLSessionTask* task = [progress objectForKey:DOWNLOAD_PROGRESS_NOTIFICATION_TASK];
            NSString* url = [task.originalRequest.URL absoluteString];
            
            for(OEXHelperVideoDownload* video in _arr_downloadingVideo) {
                if([video.summary.videoURL isEqualToString:url]) {
                    [self updateProgressForVisibleRows];
                    break;
                }
            }
        }
    });
}

- (void)downloadCompleteNotification:(NSNotification*)notification {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self updateProgressForVisibleRows];
    });
}

/// Update progress for visible rows

- (NSString*)downloadStatusAccessibilityLabelForVideoName:(NSString*)video percentComplete:(double)percentage {
    NSNumberFormatter* formatter = [[NSNumberFormatter alloc] init];
    formatter.numberStyle = NSNumberFormatterPercentStyle;
    NSString* formatted = [formatter stringFromNumber:@(percentage)];
    return [Strings accessibilityDownloadViewCellWithVideoName:video percentComplete:formatted](percentage);
}

- (void)updateProgressForVisibleRows {
    NSArray* array = [self.table_Downloads visibleCells];

    BOOL needReload = NO;

    if(![self.table_Downloads isDecelerating] || ![self.table_Downloads isDragging]) {
        for(OEXDownloadTableCell* cell in array) {
            NSIndexPath* indexPath = [self.table_Downloads indexPathForCell:cell];
            OEXHelperVideoDownload* video = [self.arr_downloadingVideo objectAtIndex:indexPath.row];
            float progress = video.downloadProgress;
            cell.progressView.progress = progress / OEXMaxDownloadProgress;
            if(progress == OEXMaxDownloadProgress) {
                needReload = YES;
            }
            
            cell.accessibilityLabel = [self downloadStatusAccessibilityLabelForVideoName:video.summary.name percentComplete:(progress / OEXMaxDownloadProgress)];
        }
    }

    if(needReload) {
        [self.arr_downloadingVideo removeAllObjects];
        [self reloadDownloadingVideos];
    }
}

- (IBAction)btnCancelPressed:(UIButton*)button {
    NSIndexPath* indexPath = [NSIndexPath indexPathForRow:button.tag inSection:0];

    OEXInterface* edxInterface = [OEXInterface sharedInterface];
    if(indexPath.row < [self.arr_downloadingVideo count]) {
        OEXHelperVideoDownload* video = [self.arr_downloadingVideo objectAtIndex:indexPath.row];

        [self.table_Downloads beginUpdates];
        [self.table_Downloads deleteRowsAtIndexPaths:[NSArray arrayWithObjects:indexPath, nil] withRowAnimation:UITableViewRowAnimationFade];
        [self.arr_downloadingVideo removeObjectAtIndex:indexPath.row];
        [self.table_Downloads endUpdates];
        [self.table_Downloads reloadData];

        [edxInterface cancelDownloadForVideo:video completionHandler:^(BOOL success){
            dispatch_async(dispatch_get_main_queue(), ^{
                    video.downloadState = OEXDownloadStateNew;
                });
        }];
    }
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return [OEXStyles sharedStyles].standardStatusBarStyle;
}

@end
