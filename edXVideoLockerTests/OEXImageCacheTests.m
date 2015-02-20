//
//  OEXImageCacheTests.m
//  edXVideoLocker
//
//  Created by Prashant Kurhade on 18/02/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import "OEXImageCache.h"
static const CGFloat OEXDefaultRequestTimeout = 60;
@interface OEXImageCacheTests : XCTestCase
{
    XCTestExpectation *expectation;
}
@end

@implementation OEXImageCacheTests

- (void)setUp {
    [super setUp];
    expectation =
    [self expectationWithDescription:@"Image Expectations"];
    [[NSNotificationCenter defaultCenter] addObserver:self  selector:@selector(setImageToImageView:)  name:OEXImageDownloadCompleteNotification object:nil];
}

- (void)tearDown {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [super tearDown];
}

- (void)setImageToImageView:(NSNotification *)notification {
    
    NSDictionary *dictObj = notification.userInfo;
    UIImage *image=[dictObj objectForKey:OEXNotificationUserInfoObjectImageKey];
    [expectation fulfill];
    if(image)
    {
        XCTAssertNotNil(image,"Image is nil");
    }
    else {
        XCTAssertNil(image,"Image is not nil");
    }
}

- (void)testGetImageWithNilImageURL {
    OEXImageCache *imageCache =[OEXImageCache sharedInstance];
    [imageCache getImage:nil];
    
    [self waitForExpectationsWithTimeout:OEXDefaultRequestTimeout handler:^(NSError *error) {
        if (error) {
            XCTAssert(nil,@"Timeout Error: %@", error);
        }
    }];
}


- (void)testGetImageWithInvalidImageURL {
    OEXImageCache *imageCache =[OEXImageCache sharedInstance];
    [imageCache getImage:@"Invalid Image URL"];
    
    [self waitForExpectationsWithTimeout:OEXDefaultRequestTimeout handler:^(NSError *error) {
        if (error) {
            XCTAssert(nil,@"Timeout Error: %@", error);
        }
    }];
}




@end
