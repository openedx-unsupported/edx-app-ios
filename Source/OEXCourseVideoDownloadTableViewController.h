//
//  OEXCourseVideoDownloadTableViewController.h
//  edXVideoLocker
//
//  Created by Rahul Varma on 26/05/14.
//  Copyright (c) 2014-2016 edX. All rights reserved.
//

#import "OEXInterface.h"
#import "OEXCustomNavigationView.h"
#import "DACircularProgressView.h"
#import "OEXCustomLabel.h"
#import "OEXCustomEditingView.h"

@class OEXCourse;
@class OEXVideoSummary;

NS_ASSUME_NONNULL_BEGIN

@interface OEXCourseVideoDownloadTableViewController : UIViewController

@property (strong, nonatomic) OEXCourse* course;
@property (strong, nonatomic)  OEXHelperVideoDownload* lastAccessedVideo;
@property (nonatomic, strong) NSArray* arr_DownloadProgress;
@property (strong, nonatomic) NSArray* selectedPath;    // OEXVideoPathEntry

@end

NS_ASSUME_NONNULL_END
