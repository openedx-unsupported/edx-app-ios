//
//  OEXVideoSummaryList.h
//  edXVideoLocker
//
//  Created by Rahul Varma on 17/06/14.
//  Copyright (c) 2014 edX. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class OEXVideoPathEntry;

@interface OEXVideoSummary : NSObject

- (id)initWithDictionary:(NSDictionary*)dictionary;
// TODO: Factor the video code to get this from the block instead of the video summary
- (id)initWithDictionary:(NSDictionary*)dictionary videoID:(NSString*)videoID name:(NSString*)name;

/// Generate a simple stub video summary. Used only for testing
/// path : OEXVideoPathEntry array
- (id)initWithVideoID:(NSString*)videoID name:(NSString*)name path:(NSArray*)path;

@property (readonly, nonatomic, copy, nullable) NSString* sectionURL;     // used for OPEN IN BROWSER

@property (readonly, strong, nonatomic, nullable) OEXVideoPathEntry* chapterPathEntry;
@property (readonly, strong, nonatomic, nullable) OEXVideoPathEntry* sectionPathEntry;

/// displayPath : OEXVideoPathEntry array
/// This is just the list [chapterPathEntry, sectionPathEntry], filtering out nil items
@property (readonly, copy, nonatomic, nullable) NSArray* displayPath;

@property (readonly, nonatomic, copy, nullable) NSString* category;
@property (readonly, nonatomic, copy, nullable) NSString* name;
@property (readonly, nonatomic, copy, nullable) NSString* videoURL;
@property (readonly, nonatomic, copy, nullable) NSString* videoThumbnailURL;
// TODO: Make this readonly again, once we completely migrate to the new API
@property (nonatomic, assign) double duration;
@property (readonly, nonatomic, copy, nullable) NSString* videoID;
@property (readonly, nonatomic, copy, nullable) NSNumber* size;   // in bytes
@property (readonly, nonatomic, copy, nullable) NSString* unitURL;
@property (readonly, nonatomic, assign) BOOL onlyOnWeb;

// For CC
// de - German
// en - English
// zh - Chinese
// es - Spanish
// pt - Portuguese
// fr - French

@property (readonly, nonatomic, strong, nullable) NSDictionary* transcripts;

// TODO: Get rid of these and build any info from a list of known locales
@property (readonly, nonatomic, strong, nullable) NSString* srtGerman;
@property (readonly, nonatomic, strong, nullable) NSString* srtEnglish;
@property (readonly, nonatomic, strong, nullable) NSString* srtChinese;
@property (readonly, nonatomic, strong, nullable) NSString* srtSpanish;
@property (readonly, nonatomic, strong, nullable) NSString* srtPortuguese;
@property (readonly, nonatomic, strong, nullable) NSString* srtFrench;

@end


NS_ASSUME_NONNULL_END