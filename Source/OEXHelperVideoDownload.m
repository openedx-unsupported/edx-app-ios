//
//  HelperVideoDownload.m
//  edXVideoLocker
//
//  Created by Rahul Varma on 28/05/14.
//  Copyright (c) 2014 edX. All rights reserved.
//

#import "OEXHelperVideoDownload.h"

#import "OEXVideoSummary.h"

double const OEXMaxDownloadProgress = 100;

@implementation OEXHelperVideoDownload

- (NSString*)description {
    return [NSString stringWithFormat:@"<%@: %p, video_id=%@>", [self class], self, self.summary.videoID];
}

@end
