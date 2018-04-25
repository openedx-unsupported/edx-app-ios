//
//  OEXVideoSummaryTests.m
//  edXVideoLocker
//
//  Created by Akiva Leffert on 1/20/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>

#import "OEXConfig.h"
#import "OEXVideoEncoding.h"
#import "OEXVideoPathEntry.h"
#import "OEXVideoSummary.h"

@interface OEXVideoSummaryTests : XCTestCase


@end

@implementation OEXVideoSummaryTests

- (NSDictionary*)pathEntryWithName:(NSString*)name entryID:(NSString*)entryID category:(NSString*)category {
    
    return @{
             @"name" : name,
             @"id" : entryID,
             @"category" : category
             };
}

- (NSDictionary*) summaryWithEncoding:(NSDictionary*) encoding andOnlyOnWeb:(BOOL) onlyOnWeb {
    NSMutableDictionary *summary = [NSMutableDictionary new];
    [summary setObject:[NSNumber numberWithBool:onlyOnWeb] forKey:@"only_on_web"];
    
    if (encoding) {
        [summary setObject:encoding forKey:@"encoded_videos"];
    }
     
    return @{@"summary": summary};
}

- (NSDictionary*) summaryWithEncodings:(NSArray*) encodings andOnlyOnWeb:(BOOL) onlyOnWeb {
    return [self summaryWithEncodings:encodings andOnlyOnWeb: onlyOnWeb andAllSources:nil];
}

- (NSDictionary*) summaryWithEncodings:(NSArray*) encodings andOnlyOnWeb:(BOOL) onlyOnWeb andAllSources:(NSArray *)allSources {
    NSMutableDictionary *summary = [NSMutableDictionary new];
    NSMutableDictionary *allEncodings = [NSMutableDictionary new];
    [summary setObject:[NSNumber numberWithBool:onlyOnWeb] forKey:@"only_on_web"];

    for (NSDictionary *encoding in encodings) {
        for (NSString *name in encoding) {
            allEncodings[name] = encoding[name];
        }
    }
    if (allEncodings) {
        [summary setObject:allEncodings forKey:@"encoded_videos"];
    }
    if (allSources) {
        [summary setObject:allSources forKey:@"all_sources"];
    }

    return @{@"summary": summary};
}

- (NSDictionary*) encodingWithName:(NSString*) name andUrl:(NSString*) url {
    return @{name: @{
                     @"file_size": @0,
                     @"url": url
                     }};
}

- (OEXVideoSummary*) videoPipelineEnabledSummaryWith: (NSDictionary*)dictionary {
    OEXConfig *origConfig = [OEXConfig sharedConfig];
    OEXConfig *overrideConfig = [[OEXConfig alloc] initWithDictionary:@{@"USING_VIDEO_PIPELINE": @YES}];
    [OEXConfig setSharedConfig:overrideConfig];
    OEXVideoSummary* summary = [[OEXVideoSummary alloc] initWithDictionary:dictionary];
    [OEXConfig setSharedConfig:origConfig];
    return summary;
}

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
    NSDictionary* chapterEntry = [self pathEntryWithName:chapterName entryID:chapterID category:chapterCategory];
    
    NSString* sectionName = @"Section 4";
    NSString* sectionID = @"abc/123/456";
    NSString* sectionCategory = @"sequential";
    NSDictionary* sectionEntry = [self pathEntryWithName:sectionName entryID:sectionID category:sectionCategory];
    
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
    XCTAssertEqualObjects(summary.videoThumbnailURL, videoThumbnailURL);
    XCTAssertEqualObjects(@(summary.duration), duration);
    XCTAssertEqualObjects(summary.videoID, videoID);
    XCTAssertEqualObjects(summary.unitURL, unitURL);
    XCTAssertEqual(summary.displayPath.count, 2);
    XCTAssertEqualObjects(summary.chapterPathEntry.name, chapterName);
    XCTAssertEqualObjects(summary.chapterPathEntry.entryID, chapterID);
    XCTAssertEqual(summary.chapterPathEntry.category, OEXVideoPathEntryCategoryChapter);
    XCTAssertEqualObjects(summary.sectionPathEntry.name, sectionName);
    XCTAssertEqualObjects(summary.sectionPathEntry.entryID, sectionID);
    XCTAssertEqual(summary.sectionPathEntry.category, OEXVideoPathEntryCategorySection);
}

- (void)testDisplayPathNesting {
    NSDictionary* dummyEntry = [self pathEntryWithName:@"foo" entryID:@"id1" category:@"madeup"];
    NSDictionary* chapterEntry = [self pathEntryWithName:@"chapter1" entryID:@"id2" category:@"chapter"];
    NSDictionary* sectionEntry = [self pathEntryWithName:@"section1" entryID:@"id3" category:@"sequential"];
    NSDictionary* info = @{
                           @"path" : @[dummyEntry, chapterEntry, dummyEntry, sectionEntry]
                           };
    OEXVideoSummary* summary = [[OEXVideoSummary alloc] initWithDictionary:info];
    XCTAssertEqual(summary.displayPath.count, 2);
    XCTAssertEqual(summary.chapterPathEntry.category, OEXVideoPathEntryCategoryChapter);
    XCTAssertEqual(summary.sectionPathEntry.category, OEXVideoPathEntryCategorySection);
}

- (void)testDisplayPathEmpty {
    NSDictionary* dummyEntry = [self pathEntryWithName:@"foo" entryID:@"id1" category:@"madeup"];
    NSDictionary* info = @{
                           @"path" : @[dummyEntry, dummyEntry]
                           };
    OEXVideoSummary* summary = [[OEXVideoSummary alloc] initWithDictionary:info];
    XCTAssertEqual(summary.displayPath.count, 0);
}

- (void)testWebOnlyVideo {
    OEXVideoSummary *summary = [[OEXVideoSummary alloc] initWithDictionary:[self summaryWithEncoding:nil andOnlyOnWeb:true]];
    XCTAssertTrue(summary.onlyOnWeb);
    XCTAssertFalse(summary.isSupportedVideo);
    XCTAssertFalse(summary.isDownloadableVideo);
}

- (void)testSupportedEncoding {
    NSDictionary *fallback = [self encodingWithName:OEXVideoEncodingMobileLow andUrl:@"https://www.example.com/video.mp4"];
    OEXVideoSummary *summary = [[OEXVideoSummary alloc] initWithDictionary:[self summaryWithEncoding:fallback andOnlyOnWeb:false]];
    
    XCTAssertTrue(summary.isSupportedVideo);
    XCTAssertNotNil(summary.videoURL);
    XCTAssertNotEqual(summary.videoURL, @"");
    XCTAssertTrue(summary.isDownloadableVideo);
    XCTAssertNotNil(summary.downloadURL);
    XCTAssertNotEqual(summary.downloadURL, @"");
}

- (void)testSupportedHLSEncoding {
    NSDictionary *hls = [self encodingWithName:OEXVideoEncodingHLS andUrl:@"https://www.example.com/video.m3u8"];
    OEXVideoSummary *summary = [[OEXVideoSummary alloc] initWithDictionary:[self summaryWithEncoding:hls andOnlyOnWeb:false]];
    
    XCTAssertTrue(summary.isSupportedVideo);
    XCTAssertNotNil(summary.videoURL);
    XCTAssertNotEqual(summary.videoURL, @"");
    XCTAssertFalse(summary.isDownloadableVideo);
    XCTAssertNil(summary.downloadURL);
    XCTAssertEqual(summary.size.intValue, 0);
}

- (void)testSupportedFallbackEncoding {
    NSDictionary *fallback = [self encodingWithName:OEXVideoEncodingFallback andUrl:@"https://www.example.com/video.mp4"];
    OEXVideoSummary *summary = [[OEXVideoSummary alloc] initWithDictionary:[self summaryWithEncoding:fallback andOnlyOnWeb:false]];
    
    XCTAssertTrue(summary.isSupportedVideo);
    XCTAssertNotNil(summary.videoURL);
    XCTAssertNotEqual(summary.videoURL, @"");
    XCTAssertTrue(summary.isDownloadableVideo);
    XCTAssertNotNil(summary.downloadURL);
    XCTAssertNotEqual(summary.downloadURL, @"");
}

- (void)testUnSupportedFallbackEncoding {
    NSDictionary *fallback = [self encodingWithName:OEXVideoEncodingYoutube andUrl:@"https://www.example.com/video.mp4"];
    OEXVideoSummary *summary = [[OEXVideoSummary alloc] initWithDictionary:[self summaryWithEncoding:fallback andOnlyOnWeb:false]];
    
    XCTAssertFalse(summary.isSupportedVideo);
    XCTAssertTrue(summary.isDownloadableVideo);
}

- (void)testYoutubeEncoding {
    NSDictionary *youtube = [self encodingWithName:OEXVideoEncodingYoutube andUrl:@"https://www.youtube.com/watch?v=abc123"];
    OEXVideoSummary *summary = [[OEXVideoSummary alloc] initWithDictionary:[self summaryWithEncoding:youtube andOnlyOnWeb:false]];
    
    XCTAssertFalse(summary.isSupportedVideo);
    XCTAssertFalse(summary.isDownloadableVideo);
    XCTAssertNil(summary.downloadURL);
    XCTAssertTrue(summary.isYoutubeVideo);
}

-(void) testPrefferedHLSEncodingDownloadPipelineEnabled {
    NSDictionary *hls = [self encodingWithName:OEXVideoEncodingHLS andUrl:@"https://www.example.com/video.m3u8"];
    NSNumber *mobileLowSize = [NSNumber numberWithInt:3];
    NSDictionary *mobileLow = @{OEXVideoEncodingMobileLow: @{
                                        @"file_size": mobileLowSize,
                                        @"url": @"https://www.example.com/video.mp4"
                                        }};
    NSDictionary *fallback = [self encodingWithName:OEXVideoEncodingFallback andUrl:@"https://www.example.com/video.mp4"];
    OEXVideoSummary *summary = [self videoPipelineEnabledSummaryWith:[self summaryWithEncodings:@[hls, mobileLow, fallback] andOnlyOnWeb:false]];
    XCTAssertTrue(summary.isSupportedVideo);
    XCTAssertNotNil(summary.videoURL);
    XCTAssertNotEqual(summary.videoURL, @"");
    XCTAssertTrue(summary.isDownloadableVideo);
    XCTAssertNotNil(summary.downloadURL);
    XCTAssertNotEqual(summary.downloadURL, @"");
    XCTAssertNotEqual(summary.downloadURL, summary.videoURL);
    XCTAssertEqual(summary.preferredEncoding.name, OEXVideoEncodingHLS);
    XCTAssertNotNil(summary.size);
    NSNumber *hlsSize = (NSNumber *) [hls objectForKey:@"file_size"];
    XCTAssertNotEqual(summary.size.integerValue, hlsSize.integerValue);
    XCTAssertEqual(summary.size.integerValue, mobileLowSize.integerValue);
}

- (void)testSupportedYoutubeFallbackEncodingDownload {
    NSDictionary *youtube = [self encodingWithName:OEXVideoEncodingYoutube andUrl:@"https://www.youtube.com/watch?v=abc123"];
    NSDictionary *fallback = [self encodingWithName:OEXVideoEncodingFallback andUrl:@"https://www.example.com/video.mp4"];
    OEXVideoSummary *summary = [[OEXVideoSummary alloc] initWithDictionary:[self summaryWithEncodings:@[youtube, fallback] andOnlyOnWeb:false]];
    
    XCTAssertTrue(summary.isSupportedVideo);
    XCTAssertNotNil(summary.videoURL);
    XCTAssertNotEqual(summary.videoURL, @"");
    XCTAssertTrue(summary.isDownloadableVideo);
    XCTAssertNotNil(summary.downloadURL);
    XCTAssertNotEqual(summary.downloadURL, @"");
    XCTAssertFalse(summary.isYoutubeVideo);
}

- (void)testSupportedYoutubeHLSEncodingDownload {
    NSDictionary *youtube = [self encodingWithName:OEXVideoEncodingYoutube andUrl:@"https://www.youtube.com/watch?v=abc123"];
    NSDictionary *hls = [self encodingWithName:OEXVideoEncodingHLS andUrl:@"https://www.example.com/video.m3u8"];
    OEXVideoSummary *summary = [[OEXVideoSummary alloc] initWithDictionary:[self summaryWithEncodings:@[youtube, hls] andOnlyOnWeb:false]];
    
    XCTAssertTrue(summary.isSupportedVideo);
    XCTAssertNotNil(summary.videoURL);
    XCTAssertNotEqual(summary.videoURL, @"");
    XCTAssertFalse(summary.isDownloadableVideo);
    XCTAssertNil(summary.downloadURL);
    XCTAssertFalse(summary.isYoutubeVideo);
}

- (void)testSupportedYoutubeHLSInFallbackEncodingDownload {
    NSDictionary *youtube = [self encodingWithName:OEXVideoEncodingYoutube andUrl:@"https://www.youtube.com/watch?v=abc123"];
    NSDictionary *hlsInFallback = [self encodingWithName:OEXVideoEncodingFallback andUrl:@"https://www.example.com/video.m3u8"];
    OEXVideoSummary *summary = [[OEXVideoSummary alloc] initWithDictionary:[self summaryWithEncodings:@[youtube, hlsInFallback] andOnlyOnWeb:false]];
    
    XCTAssertTrue(summary.isSupportedVideo);
    XCTAssertNotNil(summary.videoURL);
    XCTAssertNotEqual(summary.videoURL, @"");
    XCTAssertFalse(summary.isDownloadableVideo);
    XCTAssertNil(summary.downloadURL);
    XCTAssertFalse(summary.isYoutubeVideo);
}

- (void)testSupportedYoutubeHLSEncodingAllSourcesDownload {
    NSDictionary *youtube = [self encodingWithName:OEXVideoEncodingYoutube andUrl:@"https://www.youtube.com/watch?v=abc123"];
    NSDictionary *hls = [self encodingWithName:OEXVideoEncodingHLS andUrl:@"https://www.example.com/video.m3u8"];
    NSArray *all_sources = @[
        @"https://www.example.com/video.m3u8",
        @"https://player.vimeo.com/external/225003478.m3u8?s=6438b130458bd0eb38f7625ffa26623caee8ff7c",
        @"https://player.vimeo.com/external/225003478.hd.mp4?s=bb4df4d286c4326e7b53074f30b05c845ebd3912&profile_id=174",
    ];
    NSDictionary *summaryDict = [self summaryWithEncodings:@[youtube, hls] andOnlyOnWeb:false andAllSources:all_sources];
    OEXVideoSummary *summary = [[OEXVideoSummary alloc] initWithDictionary:summaryDict];

    XCTAssertTrue(summary.isSupportedVideo);
    XCTAssertNotNil(summary.videoURL);
    XCTAssertNotEqual(summary.videoURL, @"");
    XCTAssertTrue([summary.videoURL isEqualToString:all_sources[0]]);
    XCTAssertTrue(summary.isDownloadableVideo);
    XCTAssertNotNil(summary.downloadURL);
    XCTAssertNotEqual(summary.downloadURL, @"");
    XCTAssertTrue([summary.downloadURL isEqualToString:all_sources[2]]);
    XCTAssertFalse(summary.isYoutubeVideo);
}

- (void)testSupportedYoutubeHLSInFallbackEncodingAllSourcesDownload {
    NSDictionary *youtube = [self encodingWithName:OEXVideoEncodingYoutube andUrl:@"https://www.youtube.com/watch?v=abc123"];
    NSDictionary *hls = [self encodingWithName:OEXVideoEncodingFallback andUrl:@"https://www.example.com/video.m3u8"];
    NSArray *all_sources = @[
                             @"https://www.example.com/video.m3u8",
                             @"https://player.vimeo.com/external/225003478.m3u8?s=6438b130458bd0eb38f7625ffa26623caee8ff7c",
                             @"https://player.vimeo.com/external/225003478.hd.mp4?s=bb4df4d286c4326e7b53074f30b05c845ebd3912&profile_id=174",
                             ];
    NSDictionary *summaryDict = [self summaryWithEncodings:@[youtube, hls] andOnlyOnWeb:false andAllSources:all_sources];
    OEXVideoSummary *summary = [[OEXVideoSummary alloc] initWithDictionary:summaryDict];
    
    XCTAssertTrue(summary.isSupportedVideo);
    XCTAssertNotNil(summary.videoURL);
    XCTAssertNotEqual(summary.videoURL, @"");
    XCTAssertTrue([summary.videoURL isEqualToString:all_sources[0]]);
    XCTAssertTrue(summary.isDownloadableVideo);
    XCTAssertTrue([summary.downloadURL isEqualToString:all_sources[2]]);
    XCTAssertFalse(summary.isYoutubeVideo);
}

- (void)testSupportedFallbackEncodingDownloadPipelineEnabled {
    NSDictionary *youtube = [self encodingWithName:OEXVideoEncodingYoutube andUrl:@"https://www.youtube.com/watch?v=abc123"];
    NSDictionary *hls = [self encodingWithName:OEXVideoEncodingFallback andUrl:@"https://www.example.com/video.m3u8"];
    NSArray *all_sources = @[@"https://www.example.com/video.mp4"];
    OEXVideoSummary *summary = [self videoPipelineEnabledSummaryWith:[self summaryWithEncodings:@[youtube, hls] andOnlyOnWeb:false andAllSources:all_sources]];
    XCTAssertTrue(summary.isSupportedVideo);
    XCTAssertNotNil(summary.videoURL);
    XCTAssertNotEqual(summary.videoURL, @"");
    XCTAssertFalse(summary.isDownloadableVideo);
    XCTAssertNil(summary.downloadURL);
    XCTAssertFalse(summary.isYoutubeVideo);
}

@end
