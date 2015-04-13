//
//  OEXAnnouncement.m
//  edXVideoLocker
//
//  Created by Akiva Leffert on 12/4/14.
//  Copyright (c) 2014 edX. All rights reserved.
//

#import "OEXAnnouncement.h"

@implementation OEXAnnouncement

- (id)initWithDictionary:(NSDictionary*)dictionary {
    self = [super init];
    if(self != nil) {
        self.content = dictionary[@"content"];
        self.heading = dictionary[@"date"];     // says date on the tin, but this can be anything
    }
    return self;
}

@end
