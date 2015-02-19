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

@end

@implementation OEXImageCacheTests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testGetImageWithNilImageURL {
    XCTestExpectation *expectation =
    [self expectationWithDescription:@"Image nil Expectations"];
    
    OEXImageCache *imageCache =[OEXImageCache sharedInstance];
    [imageCache getImage:nil completionBlock:^(UIImage *displayImage, NSError *error) {
        
        XCTAssertNil(displayImage,"Image is not nil");
        [expectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:OEXDefaultRequestTimeout handler:^(NSError *error) {
        if (error) {
            XCTAssert(nil,@"Timeout Error: %@", error);
        }
    }];
}

-(void)testGetImageWithValidURL
{
 
    XCTestExpectation *expectation =
    [self expectationWithDescription:@"Valid Image Expectations"];
   
    OEXImageCache *imageCache =[OEXImageCache sharedInstance];
    [imageCache getImage:@"https://courses.edx.org/c4x/KIx/KIPractihx/asset/kix_pragmatic_course_banner608x211.jpg" completionBlock:^(UIImage *displayImage, NSError *error) {
        XCTAssertNotNil(displayImage,"Image is not valid");
        [expectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:OEXDefaultRequestTimeout handler:^(NSError *error) {
        if (error) {
            XCTAssert(nil,@"Timeout Error: %@", error);
        }
    }];
}

-(void)testCheckLocalImageCacheObjectDeallocation
{
    XCTestExpectation *expectation =
    [self expectationWithDescription:@"Valid Image Expectations"];
    NSString *imageURLString=@"https://courses.edx.org/c4x/KIx/KIPractihx/asset/kix_pragmatic_course_banner608x211.jpg";
    if(imageURLString){
        OEXImageCache *imageCache =[[OEXImageCache alloc]init];
        [imageCache getImage:imageURLString completionBlock:^(UIImage *displayImage, NSError *error) {
            XCTAssertNotNil(displayImage,"Image is not valid");
            [expectation fulfill];

        }];
    }
    [self waitForExpectationsWithTimeout:OEXDefaultRequestTimeout handler:^(NSError *error) {
        if (error) {
            XCTAssert(nil,@"Timeout Error: %@", error);
        }
    }];

}

-(void)testGetImageWithInvalidURL
{
    XCTestExpectation *expectation =
    [self expectationWithDescription:@"Image nil Expectations"];
    
    OEXImageCache *imageCache =[OEXImageCache sharedInstance];
    [imageCache getImage:@"Invalid URL" completionBlock:^(UIImage *displayImage, NSError *error) {
        XCTAssertNil(displayImage,"Image is not nil");
        [expectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:OEXDefaultRequestTimeout handler:^(NSError *error) {
        if (error) {
            XCTAssert(nil,@"Timeout Error: %@", error);
        }
    }];
}



@end
