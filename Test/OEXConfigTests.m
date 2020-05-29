//
//  OEXConfigTests.m
//  edXVideoLocker
//
//  Created by Jotiram Bhagat on 23/02/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>

#import "edX-Swift.h"

#import "OEXConfig.h"
#import "OEXFacebookConfig.h"
#import "OEXGoogleConfig.h"
#import "OEXNewRelicConfig.h"
#import "OEXSegmentConfig.h"
#import "OEXZeroRatingConfig.h"

@interface OEXConfigTests : XCTestCase
@end

@implementation OEXConfigTests

-(void)testFacebookNoConfig{
    NSDictionary *configDictionary=@{};
    OEXConfig *config=[[OEXConfig alloc] initWithDictionary:configDictionary];
    OEXFacebookConfig *facebookConfig=[config facebookConfig];
    XCTAssert(!facebookConfig.enabled,@"Facebook config should not be enabled");
    XCTAssertNil(facebookConfig.appId,@"Facebook appID should be nil");
}

-(void)testFacebookEmptyConfig{
    NSDictionary *configDictionary=@{@"FACEBOOK":@{}};
    OEXConfig *config=[[OEXConfig alloc] initWithDictionary:configDictionary];
    OEXFacebookConfig *facebookConfig=[config facebookConfig];
    XCTAssert(!facebookConfig.enabled,@"Facebook config should not be enabled");
    XCTAssertNil(facebookConfig.appId,@"Facebook appID should be nil");
}

-(void)testFacebookConfigEnabled{
    NSDictionary *configDictionary=@{@"FACEBOOK":@{@"ENABLED":@YES ,
                                                           @"FACEBOOK_APP_ID":@"facebook_appID"}
                                             };
    OEXConfig *config=[[OEXConfig alloc] initWithDictionary:configDictionary];
    OEXFacebookConfig *facebookConfig=[config facebookConfig];
    XCTAssert(facebookConfig.enabled,@"Facebook config should be enabled");
    XCTAssertNotNil(facebookConfig.appId,@"Facebook appID should not be nil ");
    
}


/// Google config tests

-(void)testGoogleNoConfig{
    NSDictionary *configDictionary=@{};
    OEXConfig *config=[[OEXConfig alloc] initWithDictionary:configDictionary];
    OEXGoogleConfig *googleConfig=[config googleConfig];
    XCTAssert(!googleConfig.enabled,@"Google config should not be enabled");
    XCTAssertNil(googleConfig.apiKey,@"Google_plus_key should be nil");
}


-(void)testGoogleEmptyConfig{
    NSDictionary *configDictionary=@{@"GOOGLE":@{}};
    OEXConfig *config=[[OEXConfig alloc] initWithDictionary:configDictionary];
    OEXGoogleConfig *googleConfig=[config googleConfig];
    XCTAssert(!googleConfig.enabled,@"Google config should not be enabled");
    XCTAssertNil(googleConfig.apiKey,@"Google_plus_key should be nil");
}


-(void)testGoogleConfigEnabled{
    NSDictionary *configDictionary=@{@"GOOGLE":@{@"ENABLED":@YES ,
                                                       @"GOOGLE_PLUS_KEY":@"google_plus_key"}
                                           };
    OEXConfig *config=[[OEXConfig alloc] initWithDictionary:configDictionary];
    OEXGoogleConfig *googleConfig=[config googleConfig];
    XCTAssert(googleConfig.enabled,@"Google config should be enabled");
    XCTAssertNotNil(googleConfig.apiKey,@"Google_plus_key should not be nil");
}



//NewRelic Config tests


-(void)testNewRelicNoConfig{
    NSDictionary *configDictionary=@{};
    OEXConfig *config=[[OEXConfig alloc] initWithDictionary:configDictionary];
    OEXNewRelicConfig *newRelicConfig=[config newRelicConfig];
    XCTAssert(!newRelicConfig.enabled,@"New Relic config should not be enabled");
    XCTAssertNil(newRelicConfig.apiKey,@"New Relic config api key should be nil");
}

-(void)testNewRelicEmptyConfig{
    NSDictionary *configDictionary=@{@"NEW_RELIC":@{}};
    OEXConfig *config=[[OEXConfig alloc] initWithDictionary:configDictionary];
    OEXNewRelicConfig *newRelicConfig=[config newRelicConfig];
    XCTAssert(!newRelicConfig.enabled,@"New Relic config should not be enabled");
    XCTAssertNil(newRelicConfig.apiKey,@"New Relic config api key should be nil");
}

-(void)testNewRelicConfigEnabled{
    NSDictionary *configDictionary=@{@"NEW_RELIC":@{@"ENABLED":@YES ,
                                                         @"NEW_RELIC_KEY":@"New_Relic_key"}
                                             };
    OEXConfig *config=[[OEXConfig alloc] initWithDictionary:configDictionary];
    OEXNewRelicConfig *newRelicConfig=[config newRelicConfig];
    XCTAssert(newRelicConfig.enabled,@"New Relic config should be enabled");
    XCTAssertNotNil(newRelicConfig.apiKey,@"New Relic config api key should not be nil");
}

//SegmentIO

-(void)testSegmentIONoConfig{
    NSDictionary *configDictionary=@{};
    OEXConfig *config=[[OEXConfig alloc] initWithDictionary:configDictionary];
    OEXSegmentConfig *segmentConfig=[config segmentConfig];
    XCTAssert(!segmentConfig.enabled,@"Segment config should not be enabled");
    XCTAssertNil(segmentConfig.apiKey,@"Segment config api key should be nil");
}

-(void)testSegmentEmptyConfig{
    NSDictionary *configDictionary=@{@"SEGMENT_IO":@{}};
    OEXConfig *config=[[OEXConfig alloc] initWithDictionary:configDictionary];
    OEXSegmentConfig *segmentConfig=[config segmentConfig];
    XCTAssert(!segmentConfig.enabled,@"Segment config should not be enabled");
    XCTAssertNil(segmentConfig.apiKey,@"Segment config api key should be nil");
}

-(void)testSegmentConfigEnabled{
    NSDictionary *configDictionary=@{@"SEGMENT_IO":@{@"ENABLED":@YES ,
                                                     @"SEGMENT_IO_WRITE_KEY":@"Segment_io_write_key"}
                                     };
    OEXConfig *config=[[OEXConfig alloc] initWithDictionary:configDictionary];
    OEXSegmentConfig *segmentConfig=[config segmentConfig];
    XCTAssert(segmentConfig.enabled,@"Segment config should be enabled");
    XCTAssertNotNil(segmentConfig.apiKey,@"Segment config api key should not be nil");
}


//Zero Rating Config tests

-(void)testZeroRatingConfig{
    NSDictionary *configDictionary=@{};
    OEXConfig *config=[[OEXConfig alloc] initWithDictionary:configDictionary];
    OEXZeroRatingConfig *zeroRatingConfig=[config zeroRatingConfig];
    XCTAssert(!zeroRatingConfig.enabled,@"Zero_Rating config should not be enabled");
    XCTAssert([zeroRatingConfig.carriers count]==0,@"Carriers array should be empty");
}

-(void)testZeroRatingEmptyConfig{
    NSDictionary *configDictionary=@{@"ZERO_RATING":@{}};
    OEXConfig *config=[[OEXConfig alloc] initWithDictionary:configDictionary];
    OEXZeroRatingConfig *zeroRatingConfig=[config zeroRatingConfig];
    XCTAssert(!zeroRatingConfig.enabled,@"Zero_Rating config should not be enabled");
    XCTAssert([zeroRatingConfig.carriers count]==0,@"Carriers array should be empty");
}

-(void)testZeroRatingConfigEnabled{
    NSDictionary *configDictionary=@{@"ZERO_RATING":@{@"ENABLED":@YES ,
                                                  @"CARRIERS":@[@"1234",
                                                                @"3242"]} };
    OEXConfig *config=[[OEXConfig alloc] initWithDictionary:configDictionary];
    OEXZeroRatingConfig *zeroRatingConfig=[config zeroRatingConfig];
    XCTAssert(zeroRatingConfig.enabled,@" Zero_Rating config should be enabled");
    XCTAssert([zeroRatingConfig.carriers count]==2,@"Carriers array should not be empty");
}

@end
