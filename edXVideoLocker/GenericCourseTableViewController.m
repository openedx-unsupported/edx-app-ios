//
//  GenericCourseTableViewController.m
//  edXVideoLocker
//
//  Created by Rahul Varma on 26/05/14.
//  Copyright (c) 2014 edX. All rights reserved.
//

#import "GenericCourseTableViewController.h"
#import "AppDelegate.h"
#import "CourseVideoDownloadTableViewController.h"
#import "CustomTabBarViewViewController.h"
#import "CourseDetailTableViewCell.h"
#import "DataParser.h"
#import "OpenInBrowserViewController.h"
#import "Reachability.h"
#import "StatusMessageViewController.h"
#import "HelperVideoDownload.h"
#import "UserDetails.h"
#import "EdxAuthentication.h"
#import "DownloadViewController.h"

@interface GenericCourseTableViewController ()
@property (nonatomic , strong) DataParser *obj_DataParser;
@property (nonatomic, weak) EdXInterface * dataInterface;
@property (weak, nonatomic) IBOutlet UIView *containerView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *containerHeightConstraint;
@property (nonatomic , strong) NSString *OpenInBrowser_URL;
// get open in browser URL
@property (nonatomic , strong) OpenInBrowserViewController *browser;
@property (weak, nonatomic) IBOutlet UITableView *table_Generic;
@property (weak, nonatomic) IBOutlet CustomNavigationView *customNavView;
@property (weak, nonatomic) IBOutlet DACircularProgressView *customProgressBar;
@property (weak, nonatomic) IBOutlet UIButton *btn_Downloads;


@end

@implementation GenericCourseTableViewController

#pragma mark - REACHABILITY

- (void)HideOfflineLabel:(BOOL)isOnline
{
    self.customNavView.lbl_Offline.hidden = isOnline;
    self.customNavView.view_Offline.hidden = isOnline;
    [self showBrowserView:isOnline];
    
    [self.customNavView adjustPositionIfOnline:isOnline];
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
        
        
        if([self.navigationController topViewController]==self)
        [self.navigationController popViewControllerAnimated:YES];
        
        
        
    }
}



-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if([[segue  identifier] isEqualToString:@"DownloadControllerSegue"])
    {
        DownloadViewController *obj_download = (DownloadViewController *)[segue destinationViewController];
        obj_download.isFromGenericViews = YES;
    }
}



- (void)viewWillAppear:(BOOL)animated
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

    // Add Open In Browser to the view and adjust the table accordingly
    self.containerHeightConstraint.constant = OPEN_IN_BROWSER_HEIGHT;
    [[OpenInBrowserViewController sharedInstance] addViewToContainerSuperview:self.containerView];
    
}



- (void)showBrowserView:(BOOL)isShown
{
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
        [self.view layoutIfNeeded];
    }
    
}

- (void)navigateBack
{
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    AppDelegate *appD = [[UIApplication sharedApplication] delegate];

    // Initialize the interface for API calling
    self.dataInterface = [EdXInterface sharedInterface];
    
    _obj_DataParser = [[DataParser alloc] initWithDataInterface:_dataInterface];

    // set Back button name to blank.
    self.navigationController.navigationBar.topItem.title = @"";

    
    //Fix for 20px issue for the table view
    self.automaticallyAdjustsScrollViewInsets = NO;
    
    // set the custom navigation view properties
    self.customNavView.lbl_TitleView.text = appD.str_NAVTITLE;
    [self.customNavView.btn_Back addTarget:self action:@selector(navigateBack) forControlEvents:UIControlEventTouchUpInside];
    
    //set custom progress bar properties
    
    [self.customProgressBar setProgressTintColor:PROGRESSBAR_PROGRESS_TINT_COLOR];
    
    [self.customProgressBar setTrackTintColor:PROGRESSBAR_TRACK_TINT_COLOR];
    
    [self.customProgressBar setProgress:_dataInterface.totalProgress animated:YES];
    
    //Add oserver
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateTotalDownloadProgress:) name:TOTAL_DL_PROGRESS object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(showFloatingView:) name:FL_MESSAGE object:nil];
    
    [[self.dataInterface progressViews] addObject:self.customProgressBar];
    [[self.dataInterface progressViews] addObject:self.btn_Downloads];
    [self.customProgressBar setHidden:YES];
    [self.btn_Downloads setHidden:YES];
    
    _browser = [OpenInBrowserViewController sharedInstance];
    
#ifdef __IPHONE_8_0
    if (IS_IOS8)
        [self.table_Generic setLayoutMargins:UIEdgeInsetsZero];
#endif
    
    
}

#pragma update total download progress

-(void)showFloatingView:(NSNotification * )notification {
    NSDictionary *progress = (NSDictionary *)notification.userInfo;
    
    NSArray * array = [progress objectForKey:FL_ARRAY];
    NSString * sString = @"";
    if (array.count > 1) {
        sString = NSLocalizedString(@"s", nil);
    }
}

-(void)updateTotalDownloadProgress:(NSNotification * )notification{
    
    [self.customProgressBar setProgress:_dataInterface.totalProgress animated:YES];
    [self performSelector:@selector(reloadTableOnMainThread) withObject:nil afterDelay:1.5];
}


- (void)reloadTableOnMainThread
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.table_Generic reloadData];
    });
}


- (void)didReceiveMemoryWarning
{
    ELog(@"MemoryWarning GenericCourseTableViewController");

    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{

    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{

    // Return the number of rows in the section.
    return [self.arr_TableCourseData count];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 44;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    AppDelegate *appD = [[UIApplication sharedApplication] delegate];

    CourseDetailTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"CellCourseDetail" forIndexPath:indexPath];

    cell.lbl_Title.text = [self.arr_TableCourseData objectAtIndex:indexPath.row];
    
    NSMutableArray *arr_Videos = [_dataInterface videosForChaptername:self.str_ClickedChapter andSectionName:[self.arr_TableCourseData objectAtIndex:indexPath.row] forURL:appD.str_COURSE_OUTLINE_URL];
    cell.lbl_Count.text = [NSString stringWithFormat:@"%lu",(unsigned long)arr_Videos.count];
    cell.btn_Download.tag = indexPath.row;
    [cell.btn_Download addTarget:self action:@selector(startDownloadSectionVideos:) forControlEvents:UIControlEventTouchUpInside];

    // check if all videos in that section are downloaded.
    
    [cell.customProgressBar setProgressTintColor:PROGRESSBAR_PROGRESS_TINT_COLOR];
    [cell.customProgressBar setTrackTintColor:PROGRESSBAR_TRACK_TINT_COLOR];
    cell.customProgressBar.hidden = YES;

    for (HelperVideoDownload *videosDownloaded in arr_Videos)
    {
        if (videosDownloaded.state == DownloadStateNew)
        {
            cell.btn_Download.hidden = NO;
            break;
        }
        else
        {
            cell.btn_Download.hidden = YES;
        }
        
        if ([cell.btn_Download isHidden])
        {
            float progress = [_dataInterface showBulkProgressViewForChapter:self.str_ClickedChapter andSectionName:[self.arr_TableCourseData objectAtIndex:indexPath.row]];
            
            if (progress < 0 || progress >= 1)
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
    
#ifdef  __IPHONE_8_0
if (IS_IOS8)
    [cell setLayoutMargins:UIEdgeInsetsZero];
#endif
    
    return cell;
}



#pragma mark TableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    AppDelegate *appD = [[UIApplication sharedApplication] delegate];
    
    [appD.str_NAVTITLE setString: [self.arr_TableCourseData objectAtIndex:indexPath.row]];
        
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    CourseVideoDownloadTableViewController *objVideo = [storyboard instantiateViewControllerWithIdentifier:@"CourseVideos"];
    objVideo.isFromGenericView = YES;
    objVideo.str_SelectedChapName = self.str_ClickedChapter;
    objVideo.arr_DownloadProgress = [_dataInterface videosForChaptername:self.str_ClickedChapter andSectionName:[self.arr_TableCourseData objectAtIndex:indexPath.row] forURL:appD.str_COURSE_OUTLINE_URL];
    [self.navigationController pushViewController:objVideo animated:YES];
    [self.table_Generic deselectRowAtIndexPath:indexPath animated:YES];
    
}





- (void)startDownloadSectionVideos:(id)sender
{
    
    AppDelegate *appD = [[UIApplication sharedApplication] delegate];
    
    if ([EdXInterface shouldDownloadOnlyOnWifi])
    {
        if (![appD.reachability isReachableViaWiFi])
        {
            [[StatusMessageViewController sharedInstance] showMessage:NSLocalizedString(@"NO_WIFI_MESSAGE", nil)
                                                     onViewController:self.view
                                                             messageY:64
                                                           components:@[self.customNavView, self.customProgressBar, self.btn_Downloads]
                                                           shouldHide:YES];
            
            return;
        }
        
    }
    

    NSInteger tagValue = [sender tag];
    NSMutableArray *arr_Videos = [_dataInterface videosForChaptername:self.str_ClickedChapter
                                                       andSectionName:[self.arr_TableCourseData objectAtIndex:tagValue]
                                                               forURL:appD.str_COURSE_OUTLINE_URL];
    
    int count = 0;
    NSMutableArray * validArray = [[NSMutableArray alloc] init];
    for (HelperVideoDownload * video in arr_Videos) {
        if (video.state == DownloadStateNew) {
            count++;
            [validArray addObject:video];
        }
    }
    
    
    // Analytics Bulk Video Download From SubSection 
    if (_dataInterface.selectedCourseOnFront.course_id)
    {
        [Analytics trackSubSectionBulkVideoDownload: self.str_ClickedChapter
                                         Subsection: [self.arr_TableCourseData objectAtIndex:tagValue]
                                           CourseID: _dataInterface.selectedCourseOnFront.course_id
                                         VideoCount: [validArray count]];
        

    }
   
    
    NSString * sString = @"";
    if (count > 1) {
        sString = NSLocalizedString(@"s", nil);
    }
    
  NSInteger  downloadingCount=[_dataInterface downloadMultipleVideosForRequestStrings:validArray];
    
    if (downloadingCount>0)
    {
                   [[StatusMessageViewController sharedInstance] showMessage:[NSString stringWithFormat:@"%@ %ld %@%@", NSLocalizedString(@"DOWNLOADING", nil),downloadingCount , NSLocalizedString(@"VIDEO", nil) , sString]
                                                     onViewController:self.view
                                                             messageY:64
                                                           components:@[self.customNavView, self.customProgressBar, self.btn_Downloads]
                                                           shouldHide:YES];
            [self.table_Generic reloadData];
        }else{
            
            [[StatusMessageViewController sharedInstance] showMessage:NSLocalizedString(@"UNABLE_TO_DOWNLOAD", nil)
                                                     onViewController:self.view
                                                             messageY:64
                                                           components:@[self.customNavView, self.customProgressBar, self.btn_Downloads]
                                                           shouldHide:YES];
            
        }
    
}


-(void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:TOTAL_DL_PROGRESS object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kReachabilityChangedNotification object:nil];
}


@end
