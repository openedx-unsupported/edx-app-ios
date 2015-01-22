//
//  OEXCourseVideoDownloadTableViewController.h
//  edXVideoLocker
//
//  Created by Rahul Varma on 26/05/14.
//  Copyright (c) 2014 edX. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "OEXInterface.h"
#import "OEXCustomNavigationView.h"
#import "DACircularProgressView.h"
#import "OEXCustomLabel.h"
#import "OEXCustomEditingView.h"

@class OEXVideoSummary;

@interface OEXCourseVideoDownloadTableViewController : UIViewController <UIAlertViewDelegate, UITableViewDelegate, UITableViewDataSource>

@property (strong,nonatomic)  OEXHelperVideoDownload *lastAccessedVideo;
@property (nonatomic, assign) BOOL isFromGenericView;
@property (nonatomic, strong) NSMutableArray *arr_DownloadProgress;
@property (nonatomic, strong) NSMutableArray *arr_OfflineData;
@property (strong, nonatomic) NSArray *selectedPath; // OEXVideoPathEntry
@property (strong, nonatomic) NSURL * currentVideoURL;

@end
