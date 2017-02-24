//
//  OEXVideoSummaryList.h
//  edXVideoLocker
//
//  Created by Rahul Varma on 17/06/14.
//  Copyright (c) 2014 edX. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class OEXVideoEncoding;
@class OEXVideoPathEntry;

@interface OEXVideoSummary : NSObject

- (id)initWithDictionary:(NSDictionary*)dictionary;
// TODO: Factor the video code to get this from the block instead of the video summary
- (id)initWithDictionary:(NSDictionary*)dictionary videoID:(NSString*)videoID name:(NSString*)name;

/// Generate a simple stub video summary. Used only for testing
- (id)initWithVideoID:(NSString*)videoID name:(NSString*)name path:(NSArray<OEXVideoPathEntry*>*)path;
/// Generate a simple stub video summary. Used only for testing
- (id)initWithVideoID:(NSString*)videoID name:(NSString*)name encodings:(NSDictionary<NSString*, OEXVideoEncoding *> *)encodings;

@property (readonly, nonatomic, copy, nullable) NSString* sectionURL;     // used for OPEN IN BROWSER

@property (readonly, strong, nonatomic, nullable) OEXVideoPathEntry* chapterPathEntry;
@property (readonly, strong, nonatomic, nullable) OEXVideoPathEntry* sectionPathEntry;

@property (readonly, nonatomic, strong, nullable) OEXVideoEncoding* preferredEncoding;

/// displayPath : OEXVideoPathEntry array
/// This is just the list [chapterPathEntry, sectionPathEntry], filtering out nil items
@property (readonly, copy, nonatomic, nullable) NSArray* displayPath;

@property (readonly, nonatomic, copy, nullable) NSString* category;
// This property is deprecated. We should be reading it from the CourseBlock itself
@property (readonly, nonatomic, copy, nullable) NSString* name;
@property (readonly, nonatomic, copy, nullable) NSString* videoURL;
@property (readonly, nonatomic, copy, nullable) NSString* videoThumbnailURL;
// TODO: Make this readonly again, once we completely migrate to the new API
@property (nonatomic, assign) double duration;
@property (readonly, nonatomic, copy, nullable) NSString* videoID;
@property (readonly, nonatomic, copy, nullable) NSNumber* size;   // in bytes
@property (readonly, nonatomic, copy, nullable) NSString* unitURL;
@property (readonly, nonatomic, assign) BOOL onlyOnWeb;
@property (readonly, nonatomic, assign) BOOL isYoutubeVideo;
@property (readonly, nonatomic, assign) BOOL isSupportedVideo;
@property (nonatomic, strong) NSDictionary* encodings;

// For CC
// de - German
// en - English
// zh - Chinese
// es - Spanish
// pt - Portuguese
// fr - French

@property (readonly, nonatomic, strong, nullable) NSDictionary* transcripts;


@end


NS_ASSUME_NONNULL_END
