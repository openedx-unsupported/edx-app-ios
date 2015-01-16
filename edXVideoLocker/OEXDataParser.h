//
//  OEXDataParser.h
//  edXVideoLocker
//
//  Created by Rahul Varma on 05/06/14.
//  Copyright (c) 2014 edX. All rights reserved.
//

#import <Foundation/Foundation.h>

@class OEXInterface;

@interface OEXDataParser : NSObject

- (id)parsedObjectWithData:(NSData *)data forURLString:(NSString *)URLString;
- (id)initWithDataInterface:(OEXInterface *)dataInterface;
- (id)getVideoSummaryList:(NSData *)receivedData ForURLString:(NSString *)URLString;
- (id)getLevel1DataForURLString:(NSString *)URL;
- (id)getLevel2Data:(NSString *)str_ChapName ForURLString:(NSString *)URL;
-(NSArray *)getAnnouncements:(NSData *)receivedData;
-(id)getHandouts:(NSData *)receivedData;
- (id)getCourseInfo:(NSData *)receivedData;

- (NSMutableArray *)getVideosOfCourseWithURLString:(NSString *)URL;

- (NSString *)getOpenInBrowserLink;

- (void)deactivate;

@end
