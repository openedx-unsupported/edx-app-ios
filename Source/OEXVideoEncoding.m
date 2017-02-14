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
NSString* const OEXVideoEncodingFallback = @"fallback";

@interface OEXVideoEncoding ()

@property (copy, nonatomic) NSString* name;
@property (copy, nonatomic) NSString* URL;
@property (strong, nonatomic) NSNumber* size;

@end

@implementation OEXVideoEncoding

+ (NSArray*)knownEncodingNames {
    return @[OEXVideoEncodingMobileLow, OEXVideoEncodingMobileHigh, OEXVideoEncodingFallback, OEXVideoEncodingYoutube];
}

- (id)initWithDictionary:(NSDictionary*)dictionary name:(NSString*)name {
    if(self != nil) {
        self.name = name;
        self.URL = dictionary[@"url"];
        self.size = dictionary[@"file_size"];
    }
    
    return self;
}


- (id)initWithName:(NSString*)name URL:(NSString*)URL size:(NSNumber*)size {
    self = [super init];
    if(self != nil) {
        self.name = name;
        self.URL = URL;
        self.size = size;
    }
    return self;
}

@end
