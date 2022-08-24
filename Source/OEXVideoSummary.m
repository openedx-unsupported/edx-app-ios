//
//  OEXVideoSummaryList.m
//  edXVideoLocker
//
//  Created by Rahul Varma on 17/06/14.
//  Copyright (c) 2014 edX. All rights reserved.
//

#import "OEXVideoSummary.h"
#import "OEXConfig.h"
#import "OEXNetworkConstants.h"

#import "edX-Swift.h"
#import "OEXVideoEncoding.h"
#import "NSArray+OEXFunctional.h"
#import "NSArray+OEXSafeAccess.h"

@interface OEXVideoSummary ()

@property (nonatomic, copy) NSString* sectionURL;       // used for OPEN IN BROWSER

@property (nonatomic, copy) NSString* category;
@property (nonatomic, copy) NSString* name;
@property (nonatomic, copy) NSString* videoThumbnailURL;
@property (nonatomic, copy) NSString* videoID;
@property (nonatomic, copy) NSString* unitURL;
@property (nonatomic, assign) BOOL onlyOnWeb;
@property (nonatomic, strong) NSDictionary* transcripts;
@property (nonatomic, strong) OEXVideoEncoding *defaultEncoding;
@property (nonatomic, strong) NSMutableArray *supportedEncodings;
@property (nonatomic, copy) NSArray *allSources;

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
        self.supportedEncodings = [[NSMutableArray alloc] initWithArray:@[
            OEXVideoEncodingHLS,
            OEXVideoEncodingDesktopMP4,
            OEXVideoEncodingMobileHigh,
            OEXVideoEncodingMobileLow
        ]];
        if (![[OEXConfig sharedConfig] isUsingVideoPipeline] ||
            [self.preferredEncoding.name isEqualToString:OEXVideoEncodingFallback]) {
            [self.supportedEncodings addObject:OEXVideoEncodingFallback];
        }
        
        self.allSources = [summary objectForKey:@"all_sources"];
    }
    
    return self;
}

- (id)initWithDictionary:(NSDictionary*)dictionary videoID:(NSString*)videoID unitURL:(nullable NSString*)unitURL name:(NSString*)name {
    self = [self initWithDictionary:dictionary];
    if(self != nil) {
        self.videoID = videoID;
        self.name = name;
        self.unitURL = unitURL;
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
    OEXVideoEncoding* encoding = [self.encodingsSortedByStreamPriority firstObject];
    
    if (encoding != nil) {
        return encoding;
    }
    
    // Don't have a known encoding, so return default encoding
    return self.defaultEncoding;
}

- (NSArray*)encodingsSortedByStreamPriority {
    return [[self.encodings allValues] sortedArrayUsingComparator:^NSComparisonResult(OEXVideoEncoding *a, OEXVideoEncoding *b) {
        return [a.streamPriority compare:b.streamPriority];
    }];
}

- (BOOL)isYoutubeVideo {
    for (OEXVideoEncoding* encoding in self.encodingsSortedByStreamPriority) {
        if ([[OEXVideoEncoding knownEncodingNames] containsObject:encoding.name]) {
            if ([self isSupportedEncoding:encoding.name]) {
                return false;
            } else if ([[encoding name] isEqualToString:OEXVideoEncodingYoutube]) {
                return true;
            }
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

- (BOOL)isSupportedVideo {
    BOOL isSupportedEncoding = false;
    
    for (OEXVideoEncoding* encoding in self.encodingsSortedByStreamPriority) {
        if ([[OEXVideoEncoding knownEncodingNames] containsObject:encoding.name]) {
            if (([encoding URL] && [OEXInterface isURLForVideo:[encoding URL]]) && [self isSupportedEncoding:encoding.name]) {
                isSupportedEncoding = true;
                break;
            } else if ([[encoding name] isEqualToString:OEXVideoEncodingYoutube] && OEXConfig.sharedConfig.youtubeVideoConfig.enabled) {
                isSupportedEncoding = true;
                break;
            }
        }
    }
    
    return !self.onlyOnWeb && isSupportedEncoding;
}

+ (BOOL)isDownloadableVideoURL:(NSString*) url {
    BOOL canDownload = url.length && [OEXInterface isURLForVideo:url];
    if(canDownload) {
        for (NSString *extension in ONLINE_ONLY_VIDEO_URL_EXTENSIONS) {
            if([url localizedCaseInsensitiveContainsString:extension]){
                canDownload = NO;
                break;
            }
        }
    }
    return canDownload;
}

- (BOOL)isDownloadableVideo {
    return (BOOL)self.downloadURL;
}

- (NSString*)downloadURL {
    NSString *downloadURL = nil;
    
    if ([[OEXConfig sharedConfig] isUsingVideoPipeline]) {
        // Loop through the available encodings to find a downloadable video URL
        for(NSString* name in [self preferredEncodingSequence]) {
            OEXVideoEncoding* encoding = self.encodings[name];
            NSString *url = [encoding URL];
            if (url && [OEXVideoSummary isDownloadableVideoURL:url]) {
                downloadURL = url;
                break;
            }
        }
    }
    else {
        
        // If the preferred encoding video URL is downloadable, then allow it to be downloaded.
        if ([OEXVideoSummary isDownloadableVideoURL:self.videoURL]) {
            downloadURL = self.videoURL;
        } else {
            // Loop through the video sources to find a downloadable video URL
            for (NSString *url in self.allSources) {
                if ([OEXVideoSummary isDownloadableVideoURL:url]) {
                    downloadURL = url;
                    break;
                }
            }
        }
    }
    return downloadURL;
}

- (NSString*)videoURL {
    return self.preferredEncoding.URL;
}

- (NSNumber*)size {
    for(NSString* name in [self preferredEncodingSequence]) {
        OEXVideoEncoding* encoding = self.encodings[name];
        if (encoding.name && ![encoding.name isEqualToString:OEXVideoEncodingHLS]) {
            return encoding.size;
        }
    }
    
    return self.preferredEncoding.size;
}

- (NSString *)videoSize {
    return [NSString stringWithFormat:@"%.2fMB", (([[self size] doubleValue] / 1024) / 1024)];
}

- (NSString*)description {
    return [NSString stringWithFormat:@"<%@: %p, video_id=%@>", [self class], self, self.videoID];
}

- (BOOL)isSupportedEncoding:(NSString *) encodingName {
    return [self.supportedEncodings containsObject:encodingName];
}

- (NSArray*)preferredEncodingSequence {
    NSArray *array;
    
    VideoDownloadQuality quality = [[OEXInterface sharedInterface] getVideoDownladQuality];
    
    switch (quality) {
        case VideoDownloadQualityAuto:
            array = [NSArray arrayWithObjects:
                     OEXVideoEncodingMobileLow,
                     OEXVideoEncodingMobileHigh,
                     OEXVideoEncodingDesktopMP4,
                     OEXVideoEncodingFallback, nil];
            break;
            
        case VideoDownloadQualityMobileHigh:
            array = [NSArray arrayWithObjects:
                     OEXVideoEncodingMobileHigh,
                     OEXVideoEncodingMobileLow,
                     OEXVideoEncodingDesktopMP4,
                     OEXVideoEncodingFallback, nil];
            break;
            
        case VideoDownloadQualityMobileLow:
            array = [NSArray arrayWithObjects:
                     OEXVideoEncodingMobileLow,
                     OEXVideoEncodingMobileHigh,
                     OEXVideoEncodingDesktopMP4,
                     OEXVideoEncodingFallback, nil];
            break;
            
        case VideoDownloadQualityDesktop:
            array = [NSArray arrayWithObjects:
                     OEXVideoEncodingDesktopMP4,
                     OEXVideoEncodingMobileHigh,
                     OEXVideoEncodingMobileLow,
                     OEXVideoEncodingFallback, nil];
            break;
    }
    
    NSMutableOrderedSet *set = [NSMutableOrderedSet new];
    [set addObjectsFromArray:array];
    [set addObjectsFromArray:self.supportedEncodings];
    array = [set array];
    
    return array;
}

@end
