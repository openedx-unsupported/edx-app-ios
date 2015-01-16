//
//  OEXHelperVideoDownload.h
//  edXVideoLocker
//
//  Created by Rahul Varma on 28/05/14.
//  Copyright (c) 2014 edX. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface OEXHelperVideoDownload : NSObject

@property (nonatomic, strong) NSString *category;
@property (nonatomic, assign) double duration;
@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSNumber *size;

@property (nonatomic, strong) NSString *str_VideoURL;
@property (nonatomic, strong) NSString *str_VideoTitle;
@property (nonatomic, assign) double DownloadProgress;
@property (nonatomic, strong) NSString * filePath;

@property (nonatomic, assign) BOOL isVideoDownloading; // used to get if the video downloading is in progress
@property (nonatomic, assign) OEXDownloadState state;
@property (nonatomic, assign) OEXPlayedState watchedState;
@property (nonatomic, strong) NSString *ChapterName;    // used to keep a track for offline mode
@property (nonatomic, strong) NSString *SectionName;    // used to keep a track for offline mode
@property (nonatomic, strong) NSDate * completedDate;
@property (nonatomic, assign) NSTimeInterval lastPlayedInterval;

@property (nonatomic, assign) BOOL isSelected;  // Used only while editing.


// For Closed Captioning
@property (nonatomic , strong) NSString *HelperSrtGerman;
@property (nonatomic , strong) NSString *HelperSrtEnglish;
@property (nonatomic , strong) NSString *HelperSrtChinese;
@property (nonatomic , strong) NSString *HelperSrtSpanish;
@property (nonatomic , strong) NSString *HelperSrtPortuguese;
@property (nonatomic , strong) NSString *HelperSrtFrench;


@property (nonatomic , strong) NSString *video_id;
@property (nonatomic , strong) NSString *unit_url;

// GA changes
@property (nonatomic , strong) NSString *course_url;
@property (nonatomic , strong) NSString *course_id;

// used for last accessed subsection
@property (nonatomic , strong) NSString *subSectionID;

@end
