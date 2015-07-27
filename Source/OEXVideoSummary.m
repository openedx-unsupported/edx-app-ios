//
//  OEXVideoSummaryList.m
//  edXVideoLocker
//
//  Created by Rahul Varma on 17/06/14.
//  Copyright (c) 2014 edX. All rights reserved.
//

#import "OEXVideoSummary.h"

#import "OEXVideoEncoding.h"
#import "OEXVideoPathEntry.h"
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
@property (nonatomic, strong) OEXVideoEncoding* preferredEncoding;

@property (nonatomic, strong) NSDictionary* transcripts;
@property (nonatomic, strong) NSString* srtGerman;
@property (nonatomic, strong) NSString* srtEnglish;
@property (nonatomic, strong) NSString* srtChinese;
@property (nonatomic, strong) NSString* srtSpanish;
@property (nonatomic, strong) NSString* srtPortuguese;
@property (nonatomic, strong) NSString* srtFrench;

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
            self.name = OEXLocalizedString(@"UNTITLED", @"Title for video without a set name");
        }
        
        // The new course outline API sends the video info as encodings instead of as a single video_url.
        // Once finish the transition to the new API we can remove setting the video url from the top level
        NSString* videoURL = [summary objectForKey:@"video_url"];
        NSNumber* videoSize = [summary objectForKey:@"size"];
        
        NSDictionary* rawEncodings = OEXSafeCastAsClass(summary[@"encoded_videos"], NSDictionary);
        NSMutableDictionary* encodings = [[NSMutableDictionary alloc] init];
        [rawEncodings enumerateKeysAndObjectsUsingBlock:^(NSString* name, NSDictionary* encodingInfo, BOOL *stop) {
            OEXVideoEncoding* encoding = [[OEXVideoEncoding alloc] initWithDictionary:encodingInfo];
            [encodings safeSetObject:encoding forKey:name];
        }];
        self.encodings = (rawEncodings != nil) ? encodings : @{@"fallback" : [[OEXVideoEncoding alloc] initWithURL: videoURL size:videoSize]};
        
        for(NSString* name in [[OEXVideoEncoding knownEncodingNames] arrayByAddingObject:[OEXVideoEncoding fallbackEncodingName]]) {
            OEXVideoEncoding* encoding = self.encodings[name];
            if (encoding != nil) {
                self.preferredEncoding = encoding;
                break;
            }
        }

        self.videoThumbnailURL = [summary objectForKey:@"video_thumbnail_url"];
        self.videoID = [summary objectForKey:@"id"] ;

        self.duration = [OEXSafeCastAsClass([summary objectForKey:@"duration"], NSNumber) doubleValue];
        
        self.onlyOnWeb = [[summary objectForKey:@"only_on_web"] boolValue];

        // Data for str files used for Closed Captioning
        //        "de"
        //        "en"
        //        "zh"
        //        "es"
        //        "pt"

        self.transcripts = [summary objectForKey:@"transcripts"];
        self.srtChinese = [self.transcripts objectForKey:@"zh"];
        self.srtEnglish = [self.transcripts objectForKey:@"en"];
        self.srtGerman = [self.transcripts objectForKey:@"de"];
        self.srtPortuguese = [self.transcripts objectForKey:@"pt"];
        self.srtSpanish = [self.transcripts objectForKey:@"es"];
        self.srtFrench = [self.transcripts objectForKey:@"fr"];
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
