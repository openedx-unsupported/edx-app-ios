//
//  OEXVideoSummaryList.m
//  edXVideoLocker
//
//  Created by Rahul Varma on 17/06/14.
//  Copyright (c) 2014 edX. All rights reserved.
//

#import "OEXVideoSummary.h"

#import "edX-Swift.h"
#import "OEXVideoEncoding.h"
#import "OEXVideoPathEntry.h"
#import "NSMutableDictionary+OEXSafeAccess.h"
#import "NSArray+OEXFunctional.h"
#import "NSArray+OEXSafeAccess.h"
#import "NSMutableDictionary+OEXSafeAccess.h"

@interface OEXVideoSummary ()

@property (nonatomic, copy) NSString* sectionURL;       // used for OPEN IN BROWSER

/// path : OEXVideoPathEntry array
@property (nonatomic, copy) NSArray* path;
@property (strong, nonatomic) OEXVideoPathEntry* chapterPathEntry;
@property (strong, nonatomic) OEXVideoPathEntry* sectionPathEntry;

@property (nonatomic, copy) NSString* category;
@property (nonatomic, copy) NSString* name;
@property (nonatomic, copy) NSString* videoThumbnailURL;
//@property (nonatomic, assign) double duration;
@property (nonatomic, copy) NSString* videoID;
@property (nonatomic, copy) NSString* unitURL;
@property (nonatomic, assign) BOOL onlyOnWeb;

// [String:OEXVideoEncoding]
@property (nonatomic, strong) NSDictionary* encodings;

@property (nonatomic, strong) NSDictionary* transcripts;

@end

@implementation OEXVideoSummary

- (id)initWithDictionary:(NSDictionary*)dictionary {
    self = [super init];
    if(self != nil) {
        //Section url
        if([[dictionary objectForKey:@"section_url"] isKindOfClass:[NSString class]]) {
            self.sectionURL = [dictionary objectForKey:@"section_url"];
        }

        self.path = [[dictionary objectForKey:@"path"] oex_map:^(NSDictionary* pathEntryDict){
            return [[OEXVideoPathEntry alloc] initWithDictionary:pathEntryDict];
        }];

        self.unitURL = [dictionary objectForKey:@"unit_url"];

        NSDictionary* summary = [dictionary objectForKey:@"summary"];

        // Data from inside summary dictionary
        self.category = [summary objectForKey:@"category"];

        self.name = [summary objectForKey:@"name"];
        if([self.name length] == 0 || self.name == nil) {
            self.name = [Strings untitled];
        }
        
        // The new course outline API sends the video info as encodings instead of as a single video_url.
        // Once finish the transition to the new API we can remove setting the video url from the top level
        NSString* videoURL = [summary objectForKey:@"video_url"];
        NSNumber* videoSize = [summary objectForKey:@"size"];
        
        NSDictionary* rawEncodings = OEXSafeCastAsClass(summary[@"encoded_videos"], NSDictionary);
        NSMutableDictionary* encodings = [[NSMutableDictionary alloc] init];
        [rawEncodings enumerateKeysAndObjectsUsingBlock:^(NSString* name, NSDictionary* encodingInfo, BOOL *stop) {
            OEXVideoEncoding* encoding = [[OEXVideoEncoding alloc] initWithDictionary:encodingInfo name:name];
            [encodings safeSetObject:encoding forKey:name];
        }];
        if(!encodings[OEXVideoEncodingFallback]) {
            [encodings safeSetObject:[[OEXVideoEncoding alloc] initWithName:OEXVideoEncodingFallback URL:videoURL size:videoSize] forKey:OEXVideoEncodingFallback];
        }
        self.encodings = encodings;

        self.videoThumbnailURL = [summary objectForKey:@"video_thumbnail_url"];
        self.videoID = [summary objectForKey:@"id"] ;

        self.duration = [OEXSafeCastAsClass([summary objectForKey:@"duration"], NSNumber) doubleValue];
        
        self.onlyOnWeb = [[summary objectForKey:@"only_on_web"] boolValue];

        self.transcripts = [summary objectForKey:@"transcripts"];
    }

    return self;
}

- (id)initWithDictionary:(NSDictionary*)dictionary videoID:(NSString*)videoID name:(NSString*)name {
    self = [self initWithDictionary:dictionary];
    if(self != nil) {
        self.videoID = videoID;
        self.name = name;
    }
    return self;
}

- (id)initWithVideoID:(NSString*)videoID name:(NSString*)name path:(NSArray*)path {
    self = [super init];
    if(self != nil) {
        self.videoID = videoID;
        self.name = name;
        self.path = path;
    }
    return self;
}

- (id)initWithVideoID:(NSString *)videoID name:(NSString *)name encodings:(NSDictionary<NSString*, OEXVideoEncoding *> *)encodings {
    self = [super init];
    if(self != nil) {
        self.name = name;
        self.videoID = videoID;
        self.encodings = encodings;
    }
    return self;
}

- (OEXVideoEncoding*)preferredEncoding {
    for(NSString* name in [OEXVideoEncoding knownEncodingNames]) {
        OEXVideoEncoding* encoding = self.encodings[name];
        if (encoding != nil) {
            return encoding;
        }
    }
    // Don't have a known encoding, so just pick one. These are in a dict, but we need to do
    // something stable, so just do it alphabetically
    return self.encodings[[self.encodings.allKeys sortedArrayUsingSelector:@selector(compare:)].firstObject];
}

- (NSString*)videoURL {
    return self.preferredEncoding.URL;
}

- (NSNumber*)size {
    return self.preferredEncoding.size;
}

- (OEXVideoPathEntry*)chapterPathEntry {
    __block OEXVideoPathEntry* result = nil;
    [self.path enumerateObjectsUsingBlock:^(OEXVideoPathEntry* entry, NSUInteger idx, BOOL* stop) {
        if(entry.category == OEXVideoPathEntryCategoryChapter) {
            result = entry;
            *stop = YES;
        }
    }];
    return result;
}

- (OEXVideoPathEntry*)sectionPathEntry {
    __block OEXVideoPathEntry* result = nil;
    [self.path enumerateObjectsUsingBlock:^(OEXVideoPathEntry* entry, NSUInteger idx, BOOL* stop) {
        if(entry.category == OEXVideoPathEntryCategorySection) {
            result = entry;
            *stop = YES;
        }
    }];
    return result;
}

- (NSArray*)displayPath {
    NSMutableArray* result = [[NSMutableArray alloc] init];
    if(self.chapterPathEntry != nil) {
        [result addObject:self.chapterPathEntry];
    }
    if(self.sectionPathEntry) {
        [result addObject:self.sectionPathEntry];
    }
    return result;
}

- (NSString*)description {
    return [NSString stringWithFormat:@"<%@: %p, video_id=%@>", [self class], self, self.videoID];
}


@end
