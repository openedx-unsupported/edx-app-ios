//
//  OEXCourseDetailTableViewCell.m
//  edXVideoLocker
//
//  Created by Rahul Varma on 11/06/14.
//  Copyright (c) 2014 edX. All rights reserved.
//

#import "OEXCourseDetailTableViewCell.h"
#import "OEXInterface.h"
#import "OEXAppDelegate.h"
#import "OEXHelperVideoDownload.h"
#import "OEXCustomTabBarViewViewController.h"
#import "OEXGenericCourseTableViewController.h"
@interface OEXCourseDetailTableViewCell()
{
    NSIndexPath *_currentIndexPath;
    OEXVideoPathEntry *_currentVideoObject;
    OEXInterface * _dataInterface;
}
@end

@implementation OEXCourseDetailTableViewCell

- (void)awakeFromNib
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateTotalDownloadProgress:) name:TOTAL_DL_PROGRESS object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(dataAvailable:) name:NOTIFICATION_URL_RESPONSE object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reachabilityDidChange:) name:kReachabilityChangedNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(downloadCompleteNotification:)
                                                 name:VIDEO_DL_COMPLETE object:nil];
}

- (void)downloadCompleteNotification:(NSNotification *)notification
{
    NSDictionary * dict = notification.userInfo;
    
    NSURLSessionTask * task = [dict objectForKey:VIDEO_DL_COMPLETE_N_TASK];
    NSURL * url = task.originalRequest.URL;
    
    if ([OEXInterface isURLForVideo:url.absoluteString])
    {
        [self performSelector:@selector(reloadViewOnMainThread) withObject:self afterDelay:0.3];
    }
}


-(void)dealloc{
     [[NSNotificationCenter defaultCenter] removeObserver:self name:TOTAL_DL_PROGRESS object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NOTIFICATION_URL_RESPONSE object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:FL_MESSAGE object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kReachabilityChangedNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:VIDEO_DL_COMPLETE object:nil];
}
- (void)reachabilityDidChange:(NSNotification *)notification{
     [self performSelector:@selector(reloadViewOnMainThread) withObject:self afterDelay:0.3];
}
- (void)dataAvailable:(NSNotification *)notification
{
     [self performSelector:@selector(reloadViewOnMainThread) withObject:self afterDelay:0.3];
}

-(void)reloadViewOnMainThread
{
    dispatch_async(dispatch_get_main_queue(), ^{
        
        if([_cellViewController isKindOfClass:[OEXCustomTabBarViewViewController class]])
        {
            [self updateData];
        }else if([_cellViewController isKindOfClass:[OEXGenericCourseTableViewController class]])
        {
            [self updateGenericData];
        }
    });
   
}

-(void)updateTotalDownloadProgress:(NSNotification * )notification{
   [self performSelector:@selector(reloadViewOnMainThread) withObject:self afterDelay:0.3];
}
-(void)updateGenericData
{
    OEXAppDelegate *appD = [[UIApplication sharedApplication] delegate];
    self.lbl_Title.text = _currentVideoObject.name;
    OEXGenericCourseTableViewController *viewController=(OEXGenericCourseTableViewController *)_cellViewController;
    NSMutableArray *arr_Videos = [_dataInterface videosForChapterID:viewController.selectedChapter.entryID sectionID:_currentVideoObject.entryID URL:appD.str_COURSE_OUTLINE_URL];
    
    self.lbl_Count.text = [NSString stringWithFormat:@"%lu",(unsigned long)arr_Videos.count];
    self.btn_Download.tag = _currentIndexPath.row;
    
    // check if all videos in that section are downloaded.
    
    [self.customProgressBar setProgressTintColor:PROGRESSBAR_PROGRESS_TINT_COLOR];
    [self.customProgressBar setTrackTintColor:PROGRESSBAR_TRACK_TINT_COLOR];
    self.customProgressBar.hidden = YES;
    
    for (OEXHelperVideoDownload *videosDownloaded in arr_Videos)
    {
        if (videosDownloaded.state == OEXDownloadStateNew)
        {
            self.btn_Download.hidden = NO;
            break;
        }
        else
        {
            self.btn_Download.hidden = YES;
        }
        
        if ([self.btn_Download isHidden])
        {
            float progress = [_dataInterface showBulkProgressViewForChapterID:viewController.selectedChapter.entryID sectionID:_currentVideoObject.entryID];
            
            if (progress < 0 || progress >= 1)
            {
                self.customProgressBar.hidden = YES;
            }
            else
            {
                self.customProgressBar.hidden = NO;
                self.customProgressBar.progress = progress;
            }
            
        }
        
        
    }
    
#ifdef  __IPHONE_8_0
    if (IS_IOS8)
        [self setLayoutMargins:UIEdgeInsetsZero];
#endif

}
-(void)updateData{
    OEXAppDelegate *appD = [[UIApplication sharedApplication] delegate];
    
    NSMutableArray *arr_Videos = [_dataInterface videosForChapterID:_currentVideoObject.entryID sectionID:nil URL:appD.str_COURSE_OUTLINE_URL];
    
    self.lbl_Count.hidden = NO;
    self.lbl_Count.text = [NSString stringWithFormat:@"%lu", (unsigned long)[arr_Videos count]];
    self.btn_Download.tag = _currentIndexPath.row;
    [self.customProgressBar setProgressTintColor:PROGRESSBAR_PROGRESS_TINT_COLOR];
    [self.customProgressBar setTrackTintColor:PROGRESSBAR_TRACK_TINT_COLOR];
    self.customProgressBar.hidden = YES;
    
    if (_dataInterface.reachable)
    {
        self.backgroundColor = [UIColor whiteColor];
        
        self.lbl_Title.text = _currentVideoObject.name;
        self.view_Disable.hidden = YES;
        self.userInteractionEnabled = YES;
        
        [self setAccessoryType:UITableViewCellAccessoryNone];
        
        // check if all videos in that section are downloaded.
        for (OEXHelperVideoDownload *videosDownloaded in arr_Videos)
        {
            if (videosDownloaded.state == OEXDownloadStateNew)
            {
                self.btn_Download.hidden = NO;
                break;
            }
            else
            {
                self.btn_Download.hidden = YES;
            }
        }
        
        if ([self.btn_Download isHidden])
        {
            //ELog(@"cell.customProgressBar.progress : %f", cell.customProgressBar.progress);
            
            float progress = [_dataInterface showBulkProgressViewForChapterID:_currentVideoObject.entryID sectionID:nil];
            
            if (progress < 0)
            {
                self.customProgressBar.hidden = YES;
            }
            else
            {
                self.customProgressBar.hidden = NO;
                self.customProgressBar.progress = progress;
            }
        }
    }
    else
    {
        self.view_Disable.hidden = YES;
        self.btn_Download.hidden = YES;
        self.lbl_Count.hidden = YES;
        [self setAccessoryType:UITableViewCellAccessoryDisclosureIndicator];
        OEXCustomTabBarViewViewController *viewController=(OEXCustomTabBarViewViewController *)_cellViewController;
        if ([viewController.offlineAvailableChapterIDs containsObject:_currentVideoObject.entryID]){
            self.backgroundColor = [UIColor whiteColor];
        }
        else {
            self.backgroundColor = [UIColor colorWithRed:(float)234/255 green:(float)234/255 blue:(float)237/255 alpha:1.0];
        }
        self.lbl_Title.text = _currentVideoObject.name;
    }
    
#ifdef __IPHONE_8_0
    
    if (IS_IOS8)
        [self setLayoutMargins:UIEdgeInsetsZero];
#endif

}

-(void)setDataWithObject:(NSIndexPath *)cellIndexPath videoObject:(OEXVideoPathEntry *)videoObject
{
    _currentIndexPath=cellIndexPath;
    _currentVideoObject=videoObject;
    if(!_dataInterface)
        _dataInterface = [OEXInterface sharedInterface];
    if([_cellViewController isKindOfClass:[OEXCustomTabBarViewViewController class]])
    {
        [self updateData];
    }else if([_cellViewController isKindOfClass:[OEXGenericCourseTableViewController class]])
    {
        [self updateGenericData];
    }
}


@end
