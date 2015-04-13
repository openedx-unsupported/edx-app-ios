//
//  OEXHelperVideoDownload.h
//  edXVideoLocker
//
//  Created by Rahul Varma on 28/05/14.
//  Copyright (c) 2014 edX. All rights reserved.
//

#import <Foundation/Foundation.h>

@class OEXVideoSummary;

@interface OEXHelperVideoDownload : NSObject

@property (nonatomic, strong) OEXVideoSummary* summary;

@property (nonatomic, assign) double DownloadProgress;
@property (nonatomic, strong) NSString* filePath;

@property (nonatomic, assign) BOOL isVideoDownloading;  // used to get if the video downloading is in progress
@property (nonatomic, assign) OEXDownloadState state;
@property (nonatomic, assign) OEXPlayedState watchedState;
@property (nonatomic, strong) NSDate* completedDate;
@property (nonatomic, assign) NSTimeInterval lastPlayedInterval;

@property (nonatomic, assign) BOOL isSelected;  // Used only while editing.

@property (nonatomic, strong) NSString* course_url;
@property (nonatomic, strong) NSString* course_id;

@end
