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

@class OEXCourse;
@class OEXVideoSummary;

@interface OEXCourseVideoDownloadTableViewController : UIViewController

@property (strong, nonatomic) OEXCourse* course;
@property (strong,nonatomic)  OEXHelperVideoDownload *lastAccessedVideo;
@property (nonatomic, strong) NSArray *arr_DownloadProgress;
@property (strong, nonatomic) NSArray *selectedPath; // OEXVideoPathEntry
@property (strong, nonatomic) NSURL * currentVideoURL;

@end
