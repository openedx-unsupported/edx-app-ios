//
//  EdxInterFaceTests.m
//  edXVideoLocker
//
//  Created by Abhishek Bhagat on 19/11/14.
//  Copyright (c) 2014 edX. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>

#import "NSArray+OEXFunctional.h"
#import "OEXHelperVideoDownload.h"
#import "OEXInterface.h"
#import "OEXUserDetails.h"
#import "OEXVideoSummary.h"
#import "OEXVideoPathEntry.h"
#import "OEXVideoSummary+OEXTestDataFactory.h"

@interface OEXInterfaceTests : XCTestCase

@property (strong, nonatomic) OEXInterface* interface;
@property (strong, nonatomic) NSString* outlineURL;
@property (strong, nonatomic) OEXVideoPathEntry* chapter1;
@property (strong, nonatomic) OEXVideoPathEntry* chapter2;
@property (strong, nonatomic) OEXVideoPathEntry* section1dot1;
@property (strong, nonatomic) OEXVideoPathEntry* section1dot2;
@property (copy, nonatomic) NSArray* videos;

@end

@implementation OEXInterfaceTests

- (void)setUp {
    [super setUp];
    self.outlineURL = @"http://abc/def";
    
    self.chapter1 = [[OEXVideoPathEntry alloc] initWithEntryID:@"chapterid1" name:@"Example" category:@"chapter"];
    self.section1dot1 = [[OEXVideoPathEntry alloc] initWithEntryID:@"section1dot1" name:@"Example" category:@"sequential"];
    self.section1dot2 = [[OEXVideoPathEntry alloc] initWithEntryID:@"section1dot2" name:@"Example" category:@"sequential"];
    OEXVideoPathEntry* section2dot1 = [[OEXVideoPathEntry alloc] initWithEntryID:@"section2dot1" name:@"Example" category:@"sequential"];
    
    self.chapter2 = [[OEXVideoPathEntry alloc] initWithEntryID:@"chapterid2" name:@"Example" category:@"chapter"];
    
    OEXVideoSummary* video1 = [OEXVideoSummary freshStubWithName:@"Test Video" path:@[self.chapter1, self.section1dot1]];
    OEXVideoSummary* video2 = [OEXVideoSummary freshStubWithName:@"Test Video" path:@[self.chapter1, self.section1dot1]];
    OEXVideoSummary* video3 = [OEXVideoSummary freshStubWithName:@"Test Video" path:@[self.chapter1, self.section1dot2]];
    OEXVideoSummary* video4 = [OEXVideoSummary freshStubWithName:@"Test Video" path:@[self.chapter2, section2dot1]];
    
    self.videos = [@[video1, video2, video3, video4] oex_map:^id(OEXVideoSummary* object) {
        OEXHelperVideoDownload* download = [[OEXHelperVideoDownload alloc] init];
        download.summary = object;
        return download;
    }];
    
    
    OEXUserDetails* user = [[OEXUserDetails alloc] init];
    user.username = @"someone";
    user.userId = [NSNumber numberWithInt:12345];
    
    self.interface = [[OEXInterface alloc] init];
    [self.interface activateIntefaceForUser:user];
    [self.interface storeVideoList:self.videos forURL:self.outlineURL];
}

- (void)testVideoChapterFiltering {
    NSArray* videos = [self.interface videosForChapterID:self.chapter1.entryID sectionID:nil URL:self.outlineURL];
    
    XCTAssertEqual(3, videos.count);
    XCTAssertGreaterThan(self.videos.count, videos.count);
}

- (void)testVideoSectionFiltering {
    NSArray* videos = [self.interface videosForChapterID:self.chapter1.entryID sectionID:self.section1dot1.entryID URL:self.outlineURL];
    XCTAssertEqual(2, videos.count);
    XCTAssertGreaterThan(self.videos.count, videos.count);
}

- (void)testVideoChapterNamesIrrelevant {
    XCTAssertEqualObjects(self.chapter1.name, self.chapter2.name);
    NSArray* chapter1Videos = [self.interface videosForChapterID:self.chapter1.entryID sectionID:nil URL:self.outlineURL];
    
    NSArray* chapter2Videos = [self.interface videosForChapterID:self.chapter2.entryID sectionID:nil URL:self.outlineURL];
    
    NSArray* chapter1VideoIDs = [chapter1Videos oex_map:^id(OEXHelperVideoDownload* video) {
        return video.summary.videoID;
    }];
    
    NSArray* chapter2VideoIDs = [chapter2Videos oex_map:^id(OEXHelperVideoDownload* video) {
        return video.summary.videoID;
    }];
    
    XCTAssertNotEqualObjects(chapter1VideoIDs, chapter2VideoIDs);
}

- (void)testVideoSectionNamesIrrelevant {
    XCTAssertEqualObjects(self.section1dot1.name, self.section1dot2.name);
    NSArray* section1Videos = [self.interface videosForChapterID:self.chapter1.entryID sectionID:self.section1dot1.entryID URL:self.outlineURL];
    
    NSArray* section2Videos = [self.interface videosForChapterID:self.chapter1.entryID sectionID:self.section1dot2.entryID URL:self.outlineURL];
    
    NSArray* section1VideoIDs = [section1Videos oex_map:^id(OEXHelperVideoDownload* video) {
        return video.summary.videoID;
    }];
    
    NSArray* section2VideoIDs = [section2Videos oex_map:^id(OEXHelperVideoDownload* video) {
        return video.summary.videoID;
    }];
    
    XCTAssertNotEqualObjects(section1VideoIDs, section2VideoIDs);
}


@end
