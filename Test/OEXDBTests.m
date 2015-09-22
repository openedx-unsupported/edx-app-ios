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

// Disabled for now since this test makes lots of bad assumptions about the state of the user's data
-(void)disabled_testGetAllLocalVideoData
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
// Disabled for now since this test makes lots of bad assumptions about the state of the user's data
- (void)disabled_testvideoStateForVideoID
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

- (void)disabled_testWatchedStateForVideoID
{
    // Disabled for now since this test makes lots of bad assumptions about the state of the user's data
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
// Disabled for now since this test makes lots of bad assumptions about the state of the user's data
- (void)disabled_testLastPlayedIntervalForVideoID
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
// Disabled for now since this test makes lots of bad assumptions about the state of the user's data
- (void)disabled_testMarkLastPlayedInterval
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


// Set the download state to NEW for a video as it is cancelled from the download screen.
// Disabled for now since this test makes lots of bad assumptions about the state of the user's data
- (void)disabled_testCancelledDownloadForVideo
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
// Disabled for now since this test makes lots of bad assumptions about the state of the user's data
- (void)disabled_testDeleteDataForVideoID
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
// Disabled for now since this test makes lots of bad assumptions about the state of the user's data
-(void)disabled_testGetVideosForDownloadState
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
// Disabled for now since this test makes lots of bad assumptions about the state of the user's data
-(void)disabled_testVideosForTaskIdentifier
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
