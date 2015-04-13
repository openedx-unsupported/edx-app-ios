//
//  OEXParsePushProvider.h
//  edXVideoLocker
//
//  Created by Akiva Leffert on 4/10/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "OEXPushProvider.h"

@interface OEXParsePushProvider : NSObject <OEXPushProvider>

- (NSString*)channelForCourseID:(NSString*)courseID;

@end
