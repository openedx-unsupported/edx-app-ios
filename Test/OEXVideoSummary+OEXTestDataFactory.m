//
//  OEXVideoSummary+OEXTestDataFactory.m
//  edXVideoLocker
//
//  Created by Akiva Leffert on 1/21/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

#import "OEXVideoSummary+OEXTestDataFactory.h"

@implementation OEXVideoSummary (OEXTestDataFactory)

+ (instancetype)freshStubWithName:(NSString*)name path:(NSArray*)path {
    NSString* videoID = [NSUUID UUID].UUIDString;
    return [[OEXVideoSummary alloc] initWithVideoID:videoID name:name path:path];
}

@end
