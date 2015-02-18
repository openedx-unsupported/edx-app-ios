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
   __block BOOL isComplete=NO;
    OEXImageCache *imageCache =[OEXImageCache sharedInstance];
    [imageCache getImage:nil completionBlock:^(UIImage *displayImage) {
        isComplete=YES;
        XCTAssertNil(displayImage,"Image is not nil");
    }];
    while (!isComplete) {
        NSTimeInterval const interval = 0.002;
        if (! [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate dateWithTimeIntervalSinceNow:interval]]) {
            [NSThread sleepForTimeInterval:interval];
        }
    }
}

-(void)testGetImageWithValidURL
{
 
    __block BOOL isComplete=NO;
   
    OEXImageCache *imageCache =[OEXImageCache sharedInstance];
    [imageCache getImage:@"https://courses.edx.org/c4x/KIx/KIPractihx/asset/kix_pragmatic_course_banner608x211.jpg" completionBlock:^(UIImage *displayImage) {
        isComplete=YES;
        XCTAssertNotNil(displayImage,"Image is not valid");
    }];
    while (!isComplete) {
        NSTimeInterval const interval = 0.002;
        if (! [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate dateWithTimeIntervalSinceNow:interval]]) {
            [NSThread sleepForTimeInterval:interval];
        }
    }
}

-(void)testCheckLocalImageCacheObjectDeallocation
{
    __block BOOL isComplete=NO;
    NSString *imageURLString=@"https://courses.edx.org/c4x/KIx/KIPractihx/asset/kix_pragmatic_course_banner608x211.jpg";
    if(imageURLString){
        OEXImageCache *imageCache =[[OEXImageCache alloc]init];
        [imageCache getImage:imageURLString completionBlock:^(UIImage *displayImage) {
            isComplete=YES;
            XCTAssertNotNil(displayImage,"Image is not valid");

        }];
    }
    while (!isComplete) {
        NSTimeInterval const interval = 0.002;
        if (! [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate dateWithTimeIntervalSinceNow:interval]]) {
            [NSThread sleepForTimeInterval:interval];
        }
    }

}

-(void)testGetImageWithInvalidURL
{
    __block BOOL isComplete=NO;
    
    OEXImageCache *imageCache =[OEXImageCache sharedInstance];
    [imageCache getImage:@"Invalid URL" completionBlock:^(UIImage *displayImage) {
        isComplete=YES;
        XCTAssertNil(displayImage,"Image is not nil");
    }];
    while (!isComplete) {
        NSTimeInterval const interval = 0.002;
        if (! [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate dateWithTimeIntervalSinceNow:interval]]) {
            [NSThread sleepForTimeInterval:interval];
        }
    }
}



@end
