//
//  OEXPushSettingsManager.h
//  edX
//
//  Created by Akiva Leffert on 4/14/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString* const OEXPushSettingsChangedNotification;

@interface OEXPushSettingsManager : NSObject

- (BOOL)pushDisabledForCourseWithID:(NSString*)courseID;
- (void)setPushDisabled:(BOOL)disabled forCourseID:(NSString*)courseID;

@end
