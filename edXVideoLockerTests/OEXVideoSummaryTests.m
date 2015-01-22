//
//  OEXVideoSummaryTests.m
//  edXVideoLocker
//
//  Created by Akiva Leffert on 1/20/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>

#import "OEXVideoPathEntry.h"
#import "OEXVideoSummary.h"

@interface OEXVideoSummaryTests : XCTestCase

@end

@implementation OEXVideoSummaryTests

- (void)testParser {
    NSString* sectionURL = @"http://edx/some_section";
    NSString* category = @"video";
    NSString* name = @"A video";
    NSString* videoURL = @"http://a/video.mpg";
    NSString* videoThumbnailURL = @"http://a/thumbs/video.mpg";
    NSNumber* duration = @1000;
    NSString* videoID = @"idx://video/video";
    NSNumber* size = @1123456;
    NSString* unitURL = @"http://123/456/";
    
    NSString* chapterID = @"abc/123";
    NSString* chapterName = @"Chapter 1";
    NSString* chapterCategory = @"chapter";
    NSDictionary* chapterEntry = @{
                                   @"name" : chapterName,
                                   @"id" : chapterID,
                                   @"category" : chapterCategory
                                   };
    
    NSString* sectionName = @"Section 4";
    NSString* sectionID = @"abc/123/456";
    NSString* sectionCategory = @"section";
    NSDictionary* sectionEntry = @{
                                   @"name" : sectionName,
                                   @"id" : sectionID,
                                   @"category" : sectionCategory
                                   };
    
    NSDictionary* info = @{
                           @"section_url" : sectionURL,
                           @"path" : @[chapterEntry, sectionEntry],
                           @"summary" : @{
                                   @"category" : category,
                                   @"name" : name,
                                   @"video_url" : videoURL,
                                   @"video_thumbnail_url": videoThumbnailURL,
                                   @"duration" : duration,
                                   @"id" : videoID,
                                   @"size" : size,
                                   },
                           @"unit_url" : unitURL
                           };
    
    OEXVideoSummary* summary = [[OEXVideoSummary alloc] initWithDictionary:info];
    
    XCTAssertEqualObjects(summary.sectionURL, sectionURL);
    XCTAssertEqualObjects(summary.category, category);
    XCTAssertEqualObjects(summary.name, name);
    XCTAssertEqualObjects(summary.videoURL, videoURL);
    XCTAssertEqualObjects(summary.videoThumbnailURL, videoThumbnailURL);
    XCTAssertEqualObjects(@(summary.duration), duration);
    XCTAssertEqualObjects(summary.videoID, videoID);
    XCTAssertEqualObjects(summary.size, size);
    XCTAssertEqualObjects(summary.unitURL, unitURL);
    XCTAssertEqual(summary.path.count, 2);
    XCTAssertEqualObjects(summary.chapterPathEntry.name, chapterName);
    XCTAssertEqualObjects(summary.chapterPathEntry.entryID, chapterID);
    XCTAssertEqualObjects(summary.chapterPathEntry.category, chapterCategory);
    XCTAssertEqualObjects(summary.sectionPathEntry.name, sectionName);
    XCTAssertEqualObjects(summary.sectionPathEntry.entryID, sectionID);
    XCTAssertEqualObjects(summary.sectionPathEntry.category, sectionCategory);
}

@end
