//
//  OEXPushSettingsManager.h
//  edX
//
//  Created by Akiva Leffert on 4/14/15.
//  Copyright (c) 2015-2016 edX. All rights reserved.
//

NS_ASSUME_NONNULL_BEGIN

extern NSString* const OEXPushSettingsChangedNotification;

@interface OEXPushSettingsManager : NSObject

- (BOOL)isPushDisabledForCourseWithID:(NSString*)courseID;
- (void)setPushDisabled:(BOOL)disabled forCourseID:(NSString*)courseID;

@end

NS_ASSUME_NONNULL_END
