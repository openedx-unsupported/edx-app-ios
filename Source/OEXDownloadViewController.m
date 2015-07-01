//
//  OEXDownloadViewController.m
//  edXVideoLocker
//
//  Created by Rahul Varma on 13/06/14.
//  Copyright (c) 2014 edX. All rights reserved.
//

#import "OEXDownloadViewController.h"

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
@property(strong, nonatomic) IBOutlet NSLayoutConstraint* recentDownloadViewHeight;
@property(strong, nonatomic) IBOutlet OEXCustomLabel* lbl_DownloadedText;
@property (strong, nonatomic) IBOutlet UITableView* table_Downloads;
@property (strong, nonatomic) IBOutlet OEXCustomButton *btn_View;

@end

@implementation OEXDownloadViewController

- (IBAction)navigateToDownloadedVideos {
    [[OEXRouter sharedRouter] showMyVideos];
}

#pragma mark - REACHABILITY

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:NO animated:animated];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:DOWNLOAD_PROGRESS_NOTIFICATION object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:OEXDownloadEndedNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kReachabilityChangedNotification object:nil];
    [self.navigationController setNavigationBarHidden:NO animated:animated];

}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:YES animated:animated];
    // Add Observer
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reachabilityDidChange:) name:kReachabilityChangedNotification object:nil];

    // Check Reachability for OFFLINE
    if(_edxInterface.reachable) {
        [self HideOfflineLabel:YES];
    }
    else {
        [self HideOfflineLabel:NO];
    }   // Add Open In Browser to the view and adjust the table accordingly
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self downloadCompleteNotification:nil];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [[UIDevice currentDevice] endGeneratingDeviceOrientationNotifications];
    
    [[OEXStyles sharedStyles] applyMockNavigationBarStyleToView:self.customNavView label:self.customNavView.lbl_TitleView leftIconButton:self.customNavView.btn_Back];
    [[OEXStyles sharedStyles] applyMockBackButtonStyleToButton:self.customNavView.btn_Back];
    
    // Do any additional setup after loading the view.
#ifdef __IPHONE_8_0
    if(IS_IOS8) {
        [self.table_Downloads setLayoutMargins:UIEdgeInsetsZero];
    }
#endif

    self.recentDownloadViewHeight.constant = 0;

    //Initialize Downloading arr
    self.arr_downloadingVideo = [[NSMutableArray alloc] init];

    _edxInterface = [OEXInterface sharedInterface];

    [self reloadDownloadingVideos];

    // set the custom navigation view properties
    self.title = OEXLocalizedString(@"Downloads", nil);

    [self showDownloadedVideo];

    //Listen to notification
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(downloadProgressNotification:) name:DOWNLOAD_PROGRESS_NOTIFICATION object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(downloadCompleteNotification:)
                                                 name:OEXDownloadEndedNotification object:nil];
    
    [self.lbl_DownloadedText setTextAlignment:NSTextAlignmentNatural];
    [self.btn_View setClipsToBounds:true];
}

- (void)reloadDownloadingVideos {
    [self.arr_downloadingVideo removeAllObjects];

    NSMutableArray* array = [_edxInterface coursesAndVideosForDownloadState:OEXDownloadStatePartial];

    NSMutableDictionary* duplicationAvoidingDict = [[NSMutableDictionary alloc] init];

    for(NSDictionary* dict in array) {
        NSArray* array = [dict objectForKey:CAV_KEY_VIDEOS];

        for(OEXHelperVideoDownload* video in array) {
            if(video.DownloadProgress < 100) {
                [self.arr_downloadingVideo addObject:video];
                [duplicationAvoidingDict setObject:@"object" forKey:video.summary.videoURL];
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

        cell.lbl_title.text = downloadingVideo.summary.name;

        if([cell.lbl_title.text length] == 0) {
            cell.lbl_title.text = @"(Untitled)";
        }

        if(!downloadingVideo.summary.duration) {
            cell.lbl_time.text = @"NA";
        }
        else {
            cell.lbl_time.text = [OEXDateFormatting formatSecondsAsVideoLength: downloadingVideo.summary.duration];
        }

        float result = (([downloadingVideo.summary.size doubleValue] / 1024) / 1024);
        cell.lbl_totalSize.text = [NSString stringWithFormat:@"%.2fMB", result];
        float progress = (float)downloadingVideo.DownloadProgress;
        [cell.progressView setProgress:progress];
        //
        cell.btn_cancel.tag = indexPath.row;

        [cell.btn_cancel addTarget:self action:@selector(btnCancelPressed:) forControlEvents:UIControlEventTouchUpInside];
    }
}

- (void)tableView:(UITableView*)tableView willDisplayCell:(OEXDownloadTableCell*)cell forRowAtIndexPath:(NSIndexPath*)indexPath {
    OEXHelperVideoDownload* downloadingVideo = [self.arr_downloadingVideo objectAtIndex:indexPath.row];
    float progress = (float)downloadingVideo.DownloadProgress / 100;
    [cell.progressView setProgress:progress];
}

- (void)downloadProgressNotification:(NSNotification*)notification {
    NSDictionary* progress = (NSDictionary*)notification.userInfo;
    NSURLSessionTask* task = [progress objectForKey:DOWNLOAD_PROGRESS_NOTIFICATION_TASK];
    NSString* url = [task.originalRequest.URL absoluteString];
    for(OEXHelperVideoDownload* video in _arr_downloadingVideo) {
        if([video.summary.videoURL isEqualToString:url]) {
//            //NSLog(@"progress for video  %@   id  %@ download  %f", video.name , video.str_VideoTitle , video.DownloadProgress);
            [self updateProgressForVisibleRows];
            break;
        }
    }
}

- (void)downloadCompleteNotification:(NSNotification*)notification {
//    [UIView animateWithDuration:ANIMATION_DURATION animations:^{
//
////        self.edxInterface.numberOfRecentDownloads++;
//
//    } completion:^(BOOL finished) {
//            }];
}

/// Update progress for visible rows

- (void)updateProgressForVisibleRows {
    NSArray* array = [self.table_Downloads visibleCells];

    BOOL needReload = NO;

    if(![self.table_Downloads isDecelerating] || ![self.table_Downloads isDragging]) {
        for(OEXDownloadTableCell* cell in array) {
            NSIndexPath* indexPath = [self.table_Downloads indexPathForCell:cell];
            OEXHelperVideoDownload* video = [self.arr_downloadingVideo objectAtIndex:indexPath.row];
            float progress = video.DownloadProgress;
            cell.progressView.progress = progress / 100;
            if(progress == 100) {
                needReload = YES;
            }
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
                    video.state = OEXDownloadStateNew;
                });
        }];
    }
}

- (void)showDownloadedVideo {
    if(self.edxInterface.numberOfRecentDownloads > 0) {
        self.lbl_DownloadedText.text = OEXLocalizedStringPlural(@"VIDEOS_DOWNLOADED", self.edxInterface.numberOfRecentDownloads, nil);
        self.recentDownloadViewHeight.constant = RECENT_DOWNLOADEDVIEW_HEIGHT;
    }
    else {
        self.lbl_DownloadedText.text = @"";
        self.recentDownloadViewHeight.constant = 0;
    }
}

@end
