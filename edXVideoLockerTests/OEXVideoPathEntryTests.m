//
//  OEXVideoPathEntryTests.m
//  edXVideoLocker
//
//  Created by Akiva Leffert on 1/20/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>

#import "OEXVideoPathEntry.h"

@interface OEXVideoPathEntryTests : XCTestCase

@end

@implementation OEXVideoPathEntryTests

- (void)testParser {
    NSString* name = @"Introduction";
    NSString* entryID = @"idx://abc/123/foo";
    NSString* category = @"Video";
    
    NSDictionary* input = @{
                            @"name" : name,
                            @"id" : entryID,
                            @"category" : category
                            };
    
    
    OEXVideoPathEntry* entry = [[OEXVideoPathEntry alloc] initWithDictionary:input];
    XCTAssertEqualObjects(entry.name, name);
    XCTAssertEqualObjects(entry.entryID, entryID);
    XCTAssertEqualObjects(entry.category, category);
}


@end
