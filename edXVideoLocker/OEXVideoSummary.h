//
//  OEXVideoSummaryList.h
//  edXVideoLocker
//
//  Created by Rahul Varma on 17/06/14.
//  Copyright (c) 2014 edX. All rights reserved.
//

#import <Foundation/Foundation.h>

@class OEXVideoPathEntry;

@interface OEXVideoSummary : NSObject

- (id)initWithDictionary:(NSDictionary*)dictionary;

/// Generate a simple stub video summary. Used only for testing
/// path : OEXVideoPathEntry array
- (id)initWithVideoID:(NSString*)videoID name:(NSString*)name path:(NSArray*)path;

@property (readonly, nonatomic, copy) NSString *sectionURL;   // used for OPEN IN BROWSER

@property (readonly, strong, nonatomic) OEXVideoPathEntry* chapterPathEntry;
@property (readonly, strong, nonatomic) OEXVideoPathEntry* sectionPathEntry;

/// displayPath : OEXVideoPathEntry array
/// This is just the list [chapterPathEntry, sectionPathEntry], filtering out nil items
@property (readonly, copy, nonatomic) NSArray* displayPath;

@property (readonly, nonatomic, copy) NSString *category;
@property (readonly, nonatomic, copy) NSString *name;
@property (readonly, nonatomic, copy) NSString *videoURL;
@property (readonly, nonatomic, copy) NSString *videoThumbnailURL;
@property (readonly, nonatomic, assign) double duration;
@property (readonly, nonatomic, copy) NSString *videoID;
@property (readonly, nonatomic, copy) NSNumber *size; // in bytes
@property (readonly, nonatomic, copy) NSString *unitURL;


// For CC
// de - German
// en - English
// zh - Chinese
// es - Spanish
// pt - Portuguese
// fr - French

@property (readonly, nonatomic, strong) NSDictionary *transcripts;
@property (readonly, nonatomic, strong) NSString *srtGerman;
@property (readonly, nonatomic, strong) NSString *srtEnglish;
@property (readonly, nonatomic, strong) NSString *srtChinese;
@property (readonly, nonatomic, strong) NSString *srtSpanish;
@property (readonly, nonatomic, strong) NSString *srtPortuguese;
@property (readonly, nonatomic, strong) NSString *srtFrench;

@end
