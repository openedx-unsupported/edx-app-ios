//
//  OEXDataParserTests.m
//  edXVideoLocker
//
//  Created by Akiva Leffert on 1/21/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>

#import "OEXAnnouncement.h"
#import "OEXDataParser.h"

@interface OEXDataParserTests : XCTestCase

@property (strong, nonatomic) OEXDataParser* parser;

@end

@implementation OEXDataParserTests

- (void)setUp {
    [super setUp];
    self.parser = [[OEXDataParser alloc] init];
}

- (void)testHandoutsValid {
    NSString* htmlString = @"<p>something</p";
    NSDictionary* handout = @{
                              @"handouts_html" : htmlString
                              };
    NSError* error = nil;
    NSData* handoutData = [NSJSONSerialization dataWithJSONObject:handout options:0 error:&error];
    NSString* handoutResult = [self.parser handoutsWithData:handoutData];

    XCTAssertNil(error);
    XCTAssertEqualObjects(htmlString, handoutResult);
}

- (void)testHandoutsNulls {
    NSDictionary* handout = @{
                              @"handouts_html" : [NSNull null]
                              };
    NSError* error = nil;
    NSData* handoutData = [NSJSONSerialization dataWithJSONObject:handout options:0 error:&error];
    NSString* handoutResult = [self.parser handoutsWithData:handoutData];
    
    XCTAssertNil(error);
    XCTAssertEqualObjects(@"", handoutResult);
}

- (void)testAnnouncementsValid {
    NSDictionary* announcementData1 = @{
                                    @"content" : @"foo",
                                    @"date" : @"bar",
                                    };
    NSDictionary* announcementData2 = @{
                                    @"content" : @"baz",
                                    @"date" : @"quux",
                                    };
    NSArray* unprocessedAnnouncements = @[announcementData1, announcementData2];
    NSError* error = nil;
    NSData* announcementsData = [NSJSONSerialization dataWithJSONObject:unprocessedAnnouncements options:0 error:&error];
    NSArray* announcements = [self.parser announcementsWithData:announcementsData];
    
    XCTAssertEqual(unprocessedAnnouncements.count, announcements.count);
    for(NSUInteger i = 0; i < unprocessedAnnouncements.count; i++) {
        OEXAnnouncement* announcement = announcements[i];
        NSDictionary* announcementData = unprocessedAnnouncements[i];
        XCTAssertEqualObjects(announcementData[@"content"], announcement.content);
        XCTAssertEqualObjects(announcementData[@"date"], announcement.heading);
    }
}

- (void)testAnnouncementsNulls {
    NSArray* unprocessedAnnouncements = @[@{
                                    @"content" : [NSNull null],
                                    @"date" : [NSNull null],
                                    }];
    NSError* error = nil;
    NSData* announcementsData = [NSJSONSerialization dataWithJSONObject:unprocessedAnnouncements options:0 error:&error];
    
    for(OEXAnnouncement* announcement in [self.parser announcementsWithData:announcementsData]) {
        XCTAssertNotNil(announcement.content);
        XCTAssertNotNil(announcement.heading);
    }
}

@end
