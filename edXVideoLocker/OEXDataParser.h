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
- (NSDictionary*)getVideoSummaryList:(NSData *)receivedData ForURLString:(NSString *)URLString;

/// @return Array of OEXVideoPathEntry
- (NSArray*)chaptersForURLString:(NSString *)URL;

/// @return Array of OEXVideoPathEntry
- (NSArray*)sectionsForChapterID:(NSString *)chapterID URLString:(NSString *)URL;

-(NSArray *)getAnnouncements:(NSData *)receivedData;
-(NSString*)getHandouts:(NSData *)receivedData;
- (NSDictionary*)getCourseInfo:(NSData *)receivedData;

- (NSArray *)getVideosOfCourseWithURLString:(NSString *)URL;

- (NSString *)getOpenInBrowserLink;

- (void)deactivate;

@end
