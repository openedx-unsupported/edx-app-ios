//
//  OEXStorageInterface.h
//  edXLibrary
//
//  Created by Rahul Varma on 07/11/14.
//  Copyright (c) 2014-2016 edX, Inc. All rights reserved.
//

#import "VideoData.h"
#import "LastAccessed.h"
#import "ResourceData.h"

#import "OEXConstants.h"

NS_ASSUME_NONNULL_BEGIN

@protocol OEXStorageInterface <NSObject>

// Save all table data at a time
- (void)saveCurrentStateToDB;

- (void)openDatabaseForUser:(NSString*)userName;

#pragma mark - ResourceData Method

// Insert Resource data
- (void)insertResourceDataForURL:(NSString*)url;

// Set if the resource is started
- (void)startedDownloadForResourceURL:(NSString*)url;

// Get the resource data (JSON/image,etc.) for a URL
- (ResourceData*)resourceDataForURL:(NSString*)url;

// Set if the resource is completed
- (void)completedDownloadForResourceURL:(NSString*)url;

// Get the download state for resource
- (OEXDownloadState)downloadStateForResourceURL:(NSString*)url;

- (void)deleteResourceDataForURL:(NSString*)url;

- (NSData* _Nullable)dataForURLString:(NSString*)url;

- (void)updateData:(NSData*)data ForURLString:(NSString*)URLString;

- (VideoData*)getVideoDataForVideoID:(NSString*)videoId;

#pragma mark - Existing methods refactored with new DB

- (NSArray*)getAllLocalVideoData;

//Add new record to Video data
- (void)startedDownloadForURL:(NSString*)downloadUrl andVideoId:(NSString*)videoId;

// Get a Video data for passed videoID
- (VideoData*)videoDataForVideoID:(NSString*)video_id;

- (NSArray*)getVideosForDownloadUrl:(NSString*)downloadUrl;

// Get a last accesses data for passed CourseID
- (LastAccessed* _Nullable)lastAccessedDataForCourseID:(NSString*)courseID;

// Set a last accesses data for a course.
- (void)setLastAccessedSubsection:(NSString*)subsectionID andSubsectionName:(NSString*)subsectionName forCourseID:(nullable NSString*)courseID OnTimeStamp:(NSString*)timestamp;

// Get Video Download state for videoID
- (OEXDownloadState)videoStateForVideoID:(NSString*)video_id;

// Get Video Watched state for videoID
- (OEXPlayedState)watchedStateForVideoID:(NSString*)video_id;

// Get Video last played time for videoID
- (float)lastPlayedIntervalForVideoID:(NSString*)video_id;

// Set Video last played time for videoID
- (void)markLastPlayedInterval:(float)playedInterval forVideoID:(NSString*)video_id;

// Set Video watched state for videoID
- (void)markPlayedState:(OEXPlayedState)state forVideoID:(NSString*)video_id;

// Returns the data of the video to resume download.
- (NSData* _Nullable)resumeDataForVideoID:(NSString*)video_id;

// Set the video details & set the download state to PARTIAL for a video.
- (void)startedDownloadForVideo:(VideoData*)videoData;

// Set the video details & set the download state to NEW for a video.
- (void)onlineEntryForVideo:(VideoData*)videoData;

// Set the video details & set the download state to DOWNLOADED for a video.
- (void)completedDownloadForVideo:(VideoData*)videoData;

// Set the download state to NEW for a video as it is cancelled from the download screen.
- (void)cancelledDownloadForVideo:(VideoData*)videoData;

//Set DM_ID (task identifier) value 0
- (void)pausedAllDownloads;

// Set the download state to NEW for a video and delete the entry form the sandbox.
- (void)deleteDataForVideoID:(NSString*)video_id;

// Get array of videoData entries with download state passed.
- (NSArray*)getVideosForDownloadState:(OEXDownloadState)state;

// Get videoData entrie with dm_id passed.
- (VideoData*)videoDataForTaskIdentifier:(NSUInteger)dTaskId;

// Get array of videoData entries with dm_id passed.
- (NSArray*)videosForTaskIdentifier:(NSUInteger)dTaskId;

- (NSArray*)getAllDownloadingVideosForURL:(NSString*)url;

// Update the is_resgistered column on refresh
- (void)unregisterAllEntries;
- (void)setRegisteredCoursesAndDeleteUnregisteredData:(NSString*)courseid;
- (void)deleteUnregisteredItems;

- (void)createDatabaseDirectory;

- (void)activate;
- (void)deactivate;

#pragma mark - PRIVATE - POST GA DB Interface/Protocol Implementation

#pragma - insertion query
// All the operations will have a "where" clause to filter data as per the logged-in User.

//inserting the video data only if the video is played online or started downloading.
- (VideoData*)insertVideoData:(NSString*)username
                        Title:(NSString*)title
                         Size:(NSString*)size
                     Duration:(NSString*)duration
                DownloadState:(OEXDownloadState)download_state
                     VideoURL:(NSString*)video_url
                      VideoID:(NSString*)video_id
                      UnitURL:(NSString*)unit_url
                     CourseID:(NSString*)enrollment_id
                         DMID:(int)dm_id
                  ChapterName:(NSString*)chapter_name
                  SectionName:(NSString*)section_name
                    TimeStamp:(nullable NSDate*)downloadCompleteDate
               LastPlayedTime:(float)last_played_offset
                       is_Reg:(BOOL)is_registered
                  PlayedState:(OEXPlayedState)played_state;

#pragma - deletion query

//deleting the video data only if the video is deleted in online of offline mode.
- (void)deleteVideoData:(NSString*)username
                       :(NSString*)video_id;

#pragma - Fetch / selection query

//select the video data to show up for a user
- (NSArray*)getAllVideoDataFor:(NSString*)username;

- (NSArray*)getVideoDataFor:(NSString*)username
                    VideoID:(NSString*)video_id;

- (NSArray*)getVideoDataFor:(NSString*)username
               EnrollmentID:(NSString*)enrollment_id;

#pragma - update query

- (NSArray*)getRecordsForOperation:(NSString*)username
                           VideoID:(NSString*)video_id;

// Update the video data with last played time when playing is paused
- (void)updateLastPlayedTime:(NSString*)username
                     VideoID:(NSString*)video_id
          WithLastPlayedTime:(float)last_played_offset;

// Update the video data with download state
- (void)updateDownloadState:(NSString*)username
                    VideoID:(NSString*)video_id
          WithDownloadState:(int)download_state;

// Update the video data with played state
- (void)updatePlayedState:(NSString*)username
                  VideoID:(NSString*)video_id
          WithPlayedState:(int)played_state;

// Update the video downloaded timestamp
- (void)updateDownloadTimestamp:(NSString*)username
                        VideoID:(NSString*)video_id
                  WithTimeStamp:(NSDate*)downloadCompleteDate;

// Update the course state if it is registered or no
- (void)updateCourseRegisterState:(NSString*)username
                         CourseID:(NSString*)enrollment_id
                       Withis_Reg:(BOOL)is_registered;

@end

NS_ASSUME_NONNULL_END
