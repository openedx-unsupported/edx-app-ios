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
    self.parser = [[OEXDataParser alloc] initWithDataInterface:nil];
}

- (void)testHandoutsValid {
    NSString* htmlString = @"<p>something</p";
    NSDictionary* handout = @{
                              @"handouts_html" : htmlString
                              };
    NSError* error = nil;
    NSData* handoutData = [NSJSONSerialization dataWithJSONObject:handout options:0 error:&error];
    NSString* handoutResult = [self.parser getHandouts:handoutData];

    XCTAssertNil(error);
    XCTAssertEqualObjects(htmlString, handoutResult);
}

- (void)testHandoutsNulls {
    NSDictionary* handout = @{
                              @"handouts_html" : [NSNull null]
                              };
    NSError* error = nil;
    NSData* handoutData = [NSJSONSerialization dataWithJSONObject:handout options:0 error:&error];
    NSString* handoutResult = [self.parser getHandouts:handoutData];
    
    XCTAssertNil(error);
    XCTAssertEqualObjects(@"", handoutResult);
}

- (void)testAnnouncementsValid {
    NSDictionary* announcement1 = @{
                                    @"content" : @"foo",
                                    @"heading" : @"bar",
                                    };
    NSDictionary* announcement2 = @{
                                    @"content" : @"baz",
                                    @"heading" : @"quux",
                                    };
    NSArray* unprocessedAnnouncements = @[announcement1, announcement2];
    NSError* error = nil;
    NSData* announcementsData = [NSJSONSerialization dataWithJSONObject:unprocessedAnnouncements options:0 error:&error];
    NSArray* announcements = [self.parser getAnnouncements:announcementsData];

    XCTAssertEqualObjects(announcements, unprocessedAnnouncements);
}

- (void)testAnnouncementsNulls {
    NSArray* unprocessedAnnouncements = @[@{
                                    @"content" : [NSNull null],
                                    @"date" : [NSNull null],
                                    }];
    NSError* error = nil;
    NSData* announcementsData = [NSJSONSerialization dataWithJSONObject:unprocessedAnnouncements options:0 error:&error];
    
    for(NSDictionary* info in [self.parser getAnnouncements:announcementsData]) {
        OEXAnnouncement* announcement = [[OEXAnnouncement alloc] initWithDictionary:info];
        
        XCTAssertNotNil(announcement.content);
        XCTAssertNotNil(announcement.heading);
    }
}

@end
