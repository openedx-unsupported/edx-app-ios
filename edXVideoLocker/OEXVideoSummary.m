//
//  OEXVideoSummaryList.m
//  edXVideoLocker
//
//  Created by Rahul Varma on 17/06/14.
//  Copyright (c) 2014 edX. All rights reserved.
//

#import "OEXVideoSummary.h"

#import "OEXVideoPathEntry.h"
#import "NSArray+OEXFunctional.h"
#import "NSArray+OEXSafeAccess.h"

@interface OEXVideoSummary ()

@property (nonatomic, copy) NSString *sectionURL;   // used for OPEN IN BROWSER

/// path : OEXVideoPathEntry array
@property (nonatomic, copy) NSArray *path;
@property (strong, nonatomic) OEXVideoPathEntry* chapterPathEntry;
@property (strong, nonatomic) OEXVideoPathEntry* sectionPathEntry;

@property (nonatomic, copy) NSString *category;
@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSString *videoURL;
@property (nonatomic, copy) NSString *videoThumbnailURL;
@property (nonatomic, assign) double duration;
@property (nonatomic, copy) NSString *videoID;
@property (nonatomic, copy) NSNumber *size; // in bytes
@property (nonatomic, copy) NSString *unitURL;

@property (nonatomic, strong) NSDictionary *transcripts;
@property (nonatomic, strong) NSString *srtGerman;
@property (nonatomic, strong) NSString *srtEnglish;
@property (nonatomic, strong) NSString *srtChinese;
@property (nonatomic, strong) NSString *srtSpanish;
@property (nonatomic, strong) NSString *srtPortuguese;
@property (nonatomic, strong) NSString *srtFrench;

@end

@implementation OEXVideoSummary

- (id)initWithDictionary:(NSDictionary *)dictionary {
    self = [super init];
    if(self != nil) {
        //Section url
        if ([[dictionary objectForKey:@"section_url"] isKindOfClass:[NSString class]]) {
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
        if([self.name length]==0 || self.name==nil)
        {
            self.name = NSLocalizedString(@"(Untitled)", @"Title for video without a set name");
        }
        
        
        self.videoURL = [summary objectForKey:@"video_url"];
        self.videoThumbnailURL = [summary objectForKey:@"video_thumbnail_url"];
        self.videoID = [summary objectForKey:@"id"];
        
        self.duration = [[summary objectForKey:@"duration"] doubleValue];
        self.size = [summary objectForKey:@"size"];
        
        
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


- (id)initWithVideoID:(NSString*)videoID name:(NSString*)name path:(NSArray*)path {
    self = [super init];
    if(self != nil) {
        self.videoID = videoID;
        self.name = name;
        self.path = path;
    }
    return self;
}

- (OEXVideoPathEntry*)chapterPathEntry {
    __block OEXVideoPathEntry* result = nil;
    [self.path enumerateObjectsUsingBlock:^(OEXVideoPathEntry* entry, NSUInteger idx, BOOL *stop) {
        if(entry.category == OEXVideoPathEntryCategoryChapter) {
            result = entry;
            *stop = YES;
        }
    }];
    return result;
}

- (OEXVideoPathEntry*)sectionPathEntry {
    __block OEXVideoPathEntry* result = nil;
    [self.path enumerateObjectsUsingBlock:^(OEXVideoPathEntry* entry, NSUInteger idx, BOOL *stop) {
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

@end
