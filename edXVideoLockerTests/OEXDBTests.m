//
//  edXDBTests.m
//  edXVideoLocker
//
//  Created by Rahul Varma on 13/11/14.
//  Copyright (c) 2014 edX. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>


#import "OEXDBManager.h"
#import "OEXStorageFactory.h"
#import "ResourceData.h"


#define VIDEO_URL @"http://edx-course-videos.s3.amazonaws.com/HARAMPX1/HARAMPX1T314-V006100_MB2.mp4"
#define VIDEO_URL_1 @"http://edx-course-videos.s3.amazonaws.com/HARAMPX1/HARAMPX1T314-V006200_MB2.mp4"
#define VIDEO_URL_2 @"http://edx-course-videos.s3.amazonaws.com/HARAMPX1/HARAMPX1T314-V010700_MB2.mp4"


#define RESOURCE_URL @"http://mobile3.m.sandbox.edx.org/api/mobile/v0.5/video_outlines/courses/MITx/4.605x_2/3T2014"

#define VIDEO_ID @"i4x://HarvardX/AmPoX.1/video/c1d1047455d44f939d2c0185daf94075"
#define VIDEO_ID_1 @"i4x://HarvardX/AmPoX.1/video/c7cbd77bb9704a0993d8aab0592f9a93"
#define VIDEO_ID_2 @"i4x://HarvardX/AmPoX.1/video/813744f07eb64f6aa1f442aeceee27e1"

@interface OEXDBTests : XCTestCase

@end

@implementation OEXDBTests


- (void)testInsertIntoVideoData
{
    id obj_DBManger = [OEXStorageFactory getInstance];
    
    [obj_DBManger insertVideoData:@"sample"
                            Title:@"Video1"
                             Size:@"150000"
                        Durartion:@"200"
                         FilePath:@"/"
                    OEXDownloadState:1
                         VideoURL:VIDEO_URL
                          VideoID:VIDEO_ID
                          UnitURL:@"https://s3.amazonaws.com/edx-course-videos/har-just2/HARJUSTXT114-G010100_100"
                         CourseID:@"edX+Open_DemoX+edx_demo_course"
                             DMID:123
                      ChapterName:@"How to Navigate the Course"
                      SectionName:@"Video List"
                        TimeStamp:[NSDate date]
                   LastPlayedTime:234
                           is_Reg:YES
                      OEXPlayedState:2];
    
    VideoData *data = [obj_DBManger videoDataForVideoID:VIDEO_ID];
    
    if(data)
        XCTAssertNotNil(data, @"Data exists");
    else
        XCTAssertNil(data, @"Data nil");
    
}


- (void)testinsertResourceDataForURL
{
    id obj_DBManger = [OEXStorageFactory getInstance];
    
    [obj_DBManger insertResourceDataForURL:RESOURCE_URL];
    
    ResourceData *objRes = [obj_DBManger resourceDataForURL:RESOURCE_URL];
    
    if(objRes)
        XCTAssertNotNil(objRes, @"Data exists");
    else
        XCTAssertNil(objRes, @"Data not nil");
}



// Set if the resource is started
- (void)testStartedDownloadForResourceURL
{
    id obj_DBManger = [OEXStorageFactory getInstance];
    
    [obj_DBManger startedDownloadForResourceURL:RESOURCE_URL];
    
    OEXDownloadState state = [obj_DBManger downloadStateForResourceURL:RESOURCE_URL];
    
    if (state==OEXDownloadStatePartial)
    {
        XCTAssertTrue(state);
    }
    else
    {
        XCTAssertFalse(state);
    }
    
}

// Set if the resource is completed
- (void)testCompletedDownloadForResourceURL
{
    id obj_DBManger = [OEXStorageFactory getInstance];
    
    [obj_DBManger completedDownloadForResourceURL:RESOURCE_URL];
    
    OEXDownloadState state = [obj_DBManger downloadStateForResourceURL:RESOURCE_URL];
    
    if (state==OEXDownloadStateComplete)
    {
        XCTAssertTrue(state);
    }
    else
    {
        XCTAssertFalse(state);
    }
}



-(void)testDeleteResourceDataForURL
{
    id obj_DBManger = [OEXStorageFactory getInstance];
    
    [obj_DBManger deleteResourceDataForURL:RESOURCE_URL];
    
    ResourceData *objRes = [obj_DBManger resourceDataForURL:RESOURCE_URL];
    
    if(objRes)
    {
        XCTAssertTrue(objRes);
    }
    else
    {
        XCTAssertFalse(objRes);
    }
}




-(void)testDataForURLString
{
    id obj_DBManger = [OEXStorageFactory getInstance];
    
    NSData *data = [obj_DBManger dataForURLString:RESOURCE_URL];
    
    if(data)
        XCTAssertNotNil(data, @"Data exists");
    else
        XCTAssertNil(data, @"Data returned is nil.");
}




//  -(void)updateData:(NSData *)data ForURLString:(NSString *)URLString;




#pragma mark - Existing methods refactored with new DB

-(void)testGetAllLocalVideoData
{
    id obj_Manager = [OEXStorageFactory getInstance];
    NSArray *arrResult = [obj_Manager getAllLocalVideoData];
    if ([arrResult count]>0)
    {
        XCTAssertNotNil(arrResult, @"data available");
    }
    else
        XCTAssertNotNil(arrResult, @"No local video is available");
    
}



//Add new record to Video data
- (void)testStartedDownloadForURL
{
    id obj_Manager = [OEXStorageFactory getInstance];
    [obj_Manager startedDownloadForURL:VIDEO_URL_1 andVideoId:VIDEO_ID_1];
    VideoData *data = [obj_Manager videoDataForVideoID:VIDEO_ID_1];
    
    if(data)
        XCTAssertNotNil(data, @"Data exists");
    else
        XCTAssertNil(data, @"Data nil");
}



// Get a Video data for passed videoID
- (void)testVideoDataForVideoID
{
    id obj_Manager = [OEXStorageFactory getInstance];
    VideoData *data = [obj_Manager videoDataForVideoID:VIDEO_ID_1];
    if(data)
        XCTAssertNotNil(data, @"Data exists");
    else
        XCTAssertNil(data, @"Data nil");
}


/*
// Get a last accesses data for passed CourseURL
- (void)testLastAccessedDataForCourseURL
{
    id obj_Manager = [StorageFactory getInstance];
    LastAccessed *data = [obj_Manager lastAccessedDataForCourseURL:COURSE_URL];
    if(data)
        XCTAssertNotNil(data, @"LastAccessed exists");
    else
        XCTAssertNil(data, @"LastAccessed does not exists");
    
}




// Set a last accesses data for a course.
- (void)testSetLastAccessedVideo
{
    id obj_Manager = [StorageFactory getInstance];
    [obj_Manager setLastAccessedVideo:VIDEO_ID andVideoURL:VIDEO_URL forCourseURL:COURSE_URL];
    LastAccessed *data = [obj_Manager lastAccessedDataForCourseURL:COURSE_URL];
    if(data)
        XCTAssertNotNil(data, @"Data exists");
    else
        XCTAssertNil(data, @"Data nil");
    
    
}
 */



// Get Video Download state for videoID
- (void)testvideoStateForVideoID
{
    id obj_Manager = [OEXStorageFactory getInstance];
    
    VideoData *data = [[obj_Manager getAllLocalVideoData] firstObject];
    
    OEXDownloadState state = [obj_Manager videoStateForVideoID:data.video_id];
    
    if (state==OEXDownloadStateComplete || state==OEXDownloadStateNew || state==OEXDownloadStatePartial)
    {
        XCTAssertTrue(state);
    }
    else
    {
        XCTAssertFalse(state);
    }
}





// Get Video Watched state for videoID
- (void)testWatchedStateForVideoID
{
    id obj_Manager = [OEXStorageFactory getInstance];
    OEXPlayedState state = [obj_Manager watchedStateForVideoID:VIDEO_ID];
    
    if (state==OEXPlayedStatePartiallyWatched || state==OEXPlayedStateUnwatched || state==OEXPlayedStateWatched)
    {
        XCTAssertTrue(state);
    }
    else
    {
        XCTAssertFalse(state);
    }
}




// Get Video last played time for videoID
- (void)testLastPlayedIntervalForVideoID
{
    id obj_Manager = [OEXStorageFactory getInstance];
    float time = [obj_Manager lastPlayedIntervalForVideoID:VIDEO_ID];
    
    if (time >= 0.0)
    {
        XCTAssertTrue(time);
    }
    else
    {
        XCTAssertFalse(time);
    }
    
}


// Set Video last played time for videoID
- (void)testMarkLastPlayedInterval
{
    id obj_Manager = [OEXStorageFactory getInstance];
    [obj_Manager markLastPlayedInterval:0.20 forVideoID:VIDEO_ID];
    float time = [obj_Manager lastPlayedIntervalForVideoID:VIDEO_ID];
    if (time >= 0.0)
    {
        XCTAssertTrue(time);
    }
    else
    {
        XCTAssertFalse(time);
    }
    
}


// Set Video watched state for videoID
- (void)testMarkPlayedState
{
    id obj_Manager = [OEXStorageFactory getInstance];
    [obj_Manager markPlayedState:OEXPlayedStatePartiallyWatched forVideoID:VIDEO_ID_1];
    OEXPlayedState state = [obj_Manager watchedStateForVideoID:VIDEO_ID_1];
    
    if (state==OEXPlayedStatePartiallyWatched)
    {
        XCTAssertTrue(state);
    }
    else
    {
        XCTAssertFalse(state);
    }
}


// Set Video Download state for videoID
- (void)testMarkDownloadState
{
    id obj_Manager = [OEXStorageFactory getInstance];
    [obj_Manager markDownloadState:OEXDownloadStateComplete forVideoID:VIDEO_ID_2];
    
    OEXDownloadState state = [obj_Manager videoStateForVideoID:VIDEO_ID_2];
    
    if (state==OEXDownloadStateComplete)
    {
        XCTAssertTrue(state);
    }
    else
    {
        XCTAssertFalse(state);
    }
    
}


// Store the video data when download stopped
//- (BOOL)storeResumeData:(NSData *)data forVideoID:(NSString *)video_id;



// Returns the data of the video to resume download.
- (void)testResumeDataForVideoID
{
    id obj_Manager = [OEXStorageFactory getInstance];
    NSData *data = [obj_Manager resumeDataForVideoID:VIDEO_ID_2];
    
    if(data)
        XCTAssertNotNil(data, @"Data exists");
    else
        XCTAssertNil(data, @"Data returned is nil.");
}



// Set the video details & set the download state to PARTIAL for a video.
// - (void)startedDownloadForVideo:(VideoData *)videoData ------ Simliar to startedDownloadForURL method


// Set the video details & set the download state to NEW for a video.
// - (void)onlineEntryForVideo ----- Unused



// Set the video details & set the download state to DOWNLOADED for a video.
- (void)testCompletedDownloadForVideo
{
   id obj_Manager = [OEXStorageFactory getInstance];
   
    VideoData *data = [[obj_Manager getAllLocalVideoData] firstObject];

    
    [obj_Manager completedDownloadForVideo:data];
    OEXDownloadState state = [obj_Manager videoStateForVideoID:VIDEO_URL];
    
    if (state==OEXDownloadStateComplete)
    {
        XCTAssertTrue(state);
    }
    else
    {
        XCTAssertFalse(state);
    }
}



// Set the download state to NEW for a video as it is cancelled from the download screen.
- (void)testCancelledDownloadForVideo
{
    id obj_Manager = [OEXStorageFactory getInstance];
    VideoData *data = [obj_Manager videoDataForVideoID:VIDEO_URL];
    [obj_Manager cancelledDownloadForVideo:data];
    OEXDownloadState state = [obj_Manager videoStateForVideoID:VIDEO_URL];
    
    if (state==OEXDownloadStateNew)
    {
        XCTAssertTrue(state);
    }
    else
    {
        XCTAssertFalse(state);
    }
}




// Set the download state to NEW for a video and delete the entry form the sandbox.
- (void)testDeleteDataForVideoID
{
    id obj_Manager = [OEXStorageFactory getInstance];
    [obj_Manager deleteDataForVideoID:VIDEO_ID_1];
    OEXDownloadState state = [obj_Manager videoStateForVideoID:VIDEO_URL];
    
    if (state==OEXDownloadStateNew)
    {
        XCTAssertTrue(state);
    }
    else
    {
        XCTAssertFalse(state);
    }
    
    
}


// Get array of videoData entries with download state passed.
-(void)testGetVideosForDownloadState
{
    id obj_Manager = [OEXStorageFactory getInstance];
    NSArray *arrResult = [obj_Manager getVideosForDownloadState:OEXDownloadStateNew];
    if ([arrResult count]>0)
    {
        XCTAssertNotNil(arrResult, @"data available");
    }
    else
        XCTAssertNotNil(arrResult, @"No video available with OEXDownloadStateNew.");
    
}

// Get videoData entrie with dm_id passed.
//-(void)videoDataForTaskIdentifier ------- retuns nil in implemntation

// Get array of videoData entries with dm_id passed.
-(void)testVideosForTaskIdentifier
{
    id obj_Manager = [OEXStorageFactory getInstance];
    NSArray *arrResult = [obj_Manager videosForTaskIdentifier:(int)1];
    if ([arrResult count]>0)
    {
        XCTAssertNotNil(arrResult, @"data available");
    }
    else
        XCTAssertNotNil(arrResult, @"No video available with taskIdentifier = 1.");
    
}



@end
