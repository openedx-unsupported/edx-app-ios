//
//  OEXLatestUpdates.m
//  edXVideoLocker
//
//  Created by Rahul Varma on 05/06/14.
//  Copyright (c) 2014 edX. All rights reserved.
//

#import "OEXLatestUpdates.h"

@implementation OEXLatestUpdates

- (id)initWithDictionary:(NSDictionary *)info {
    self = [super init];
    if(self != nil) {
        self.video = [info objectForKey:@"video"];
    }
    return self;
}

@end
