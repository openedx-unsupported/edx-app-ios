//
//  OEXVideoSummaryList.m
//  edXVideoLocker
//
//  Created by Rahul Varma on 17/06/14.
//  Copyright (c) 2014 edX. All rights reserved.
//

#import "OEXVideoSummary.h"
#import "OEXConfig.h"

#import "edX-Swift.h"
#import "OEXVideoEncoding.h"
#import "OEXVideoPathEntry.h"
#import "NSArray+OEXFunctional.h"
#import "NSArray+OEXSafeAccess.h"

@interface OEXVideoSummary ()

@property (nonatomic, copy) NSString* sectionURL;       // used for OPEN IN BROWSER

/// path : OEXVideoPathEntry array
@property (nonatomic, copy) NSArray* path;
@property (strong, nonatomic) OEXVideoPathEntry* chapterPathEntry;
@property (strong, nonatomic) OEXVideoPathEntry* sectionPathEntry;

@property (nonatomic, copy) NSString* category;
@property (nonatomic, copy) NSString* name;
@property (nonatomic, copy) NSString* videoThumbnailURL;
@property (nonatomic, copy) NSString* videoID;
@property (nonatomic, copy) NSString* unitURL;
@property (nonatomic, assign) BOOL onlyOnWeb;
@property (nonatomic, strong) NSDictionary* transcripts;
@property (nonatomic, strong) OEXVideoEncoding *defaultEncoding;
@property (nonatomic, strong) NSMutableArray *supportedEncodings;

- (BOOL)isSupportedEncoding:(NSString *) encodingName;

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
        
        NSDictionary* rawEncodings = OEXSafeCastAsClass(summary[@"encoded_videos"], NSDictionary);
        NSMutableDictionary* encodings = [[NSMutableDictionary alloc] init];
        [rawEncodings enumerateKeysAndObjectsUsingBlock:^(NSString* name, NSDictionary* encodingInfo, BOOL *stop) {
            OEXVideoEncoding* encoding = [[OEXVideoEncoding alloc] initWithDictionary:encodingInfo name:name];
            [encodings setSafeObject:encoding forKey:name];
        }];
        self.encodings = encodings;
        
        self.videoThumbnailURL = [summary objectForKey:@"video_thumbnail_url"];
        self.videoID = [summary objectForKey:@"id"] ;
        
        self.duration = [OEXSafeCastAsClass([summary objectForKey:@"duration"], NSNumber) doubleValue];
        
        self.onlyOnWeb = [[summary objectForKey:@"only_on_web"] boolValue];
        
        self.transcripts = [summary objectForKey:@"transcripts"];
        
        if (_encodings.count <=0)
            _defaultEncoding = [[OEXVideoEncoding alloc] initWithName:OEXVideoEncodingFallback URL:[summary objectForKey:@"video_url"] size:[summary objectForKey:@"size"]];
        
        self.supportedEncodings = [[NSMutableArray alloc] initWithArray:@[OEXVideoEncodingMobileHigh, OEXVideoEncodingMobileLow]];
        if (![[OEXConfig sharedConfig] isUsingVideoPipeline]) {
            [self.supportedEncodings addObject:OEXVideoEncodingFallback];
        }
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
    
    // Don't have a known encoding, so return default encoding
    return self.defaultEncoding;
}

- (BOOL) isYoutubeVideo {
    for(NSString* name in [OEXVideoEncoding knownEncodingNames]) {
        OEXVideoEncoding* encoding = self.encodings[name];
        
        NSString *name = [encoding name];
        if ([self isSupportedEncoding:name]) {
            return false;
        } else if ([[encoding name] isEqualToString:OEXVideoEncodingYoutube]) {
            return true;
        }
    }
    
    return false;
}

- (BOOL)hasVideoDuration {
    
    return (self.duration > 0.0);
}

- (BOOL)hasVideoSize {
    
    return ([[self size] doubleValue] > 0.0);
}

- (BOOL) isSupportedVideo {
    BOOL isSupportedEncoding = false;
    for(NSString* name in [OEXVideoEncoding knownEncodingNames]) {
        OEXVideoEncoding* encoding = self.encodings[name];
        NSString *name = [encoding name];
        // fallback encoding can be with unsupported type like webm
        if (([encoding URL] && [OEXInterface isURLForVideo:[encoding URL]]) && [self isSupportedEncoding:name]) {
            isSupportedEncoding = true;
            break;
        }
    }
    
    return !self.onlyOnWeb && isSupportedEncoding;
}

- (NSString*)videoURL {
    return self.preferredEncoding.URL;
}

- (NSNumber*)size {
    return self.preferredEncoding.size;
}

- (NSString *)videoSize {
    return [NSString stringWithFormat:@"%.2fMB", (([[self size] doubleValue] / 1024) / 1024)];
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

- (BOOL)isSupportedEncoding:(NSString *) encodingName {
    return [self.supportedEncodings containsObject:encodingName];
}

@end
