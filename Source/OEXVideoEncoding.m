//
//  OEXVideoEncoding.m
//  edX
//
//  Created by Akiva Leffert on 6/2/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

#import "OEXVideoEncoding.h"

NSString* const OEXVideoEncodingYoutube = @"youtube";
NSString* const OEXVideoEncodingMobileHigh = @"mobile_high";
NSString* const OEXVideoEncodingMobileLow = @"mobile_low";
NSString* const OEXVideoEncodingDesktopMP4 = @"desktop_mp4";
NSString* const OEXVideoEncodingFallback = @"fallback";
NSString* const OEXVideoEncodingHLS = @"hls";

@interface OEXVideoEncoding ()

@property (copy, nonatomic) NSString* name;
@property (copy, nonatomic) NSString* URL;
@property (strong, nonatomic) NSNumber* size;
@property (strong, nonatomic) NSNumber* streamPriority;

@end

@implementation OEXVideoEncoding

+ (NSArray*)knownEncodingNames {
    return @[
        OEXVideoEncodingHLS,
        OEXVideoEncodingMobileLow,
        OEXVideoEncodingMobileHigh,
        OEXVideoEncodingDesktopMP4,
        OEXVideoEncodingFallback,
        OEXVideoEncodingYoutube
    ];
}

- (id)initWithDictionary:(NSDictionary*)dictionary name:(NSString*)name {
    if(self != nil) {
        self.name = name;
        self.URL = dictionary[@"url"];
        self.size = dictionary[@"file_size"];
        self.streamPriority = dictionary[@"stream_priority"];
    }
    
    return self;
}


- (id)initWithName:(NSString*)name URL:(NSString*)URL size:(NSNumber*)size streamPriority:(NSNumber*)streamPriority {
    self = [super init];
    if(self != nil) {
        self.name = name;
        self.URL = URL;
        self.size = size;
        self.streamPriority = streamPriority;
    }
    return self;
}

@end
