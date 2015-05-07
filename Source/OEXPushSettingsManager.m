//
//  OEXPushSettingsManager.m
//  edX
//
//  Created by Akiva Leffert on 4/14/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

#import "OEXPushSettingsManager.h"

#import "NSArray+OEXFunctional.h"

static NSString* const OEXPushSettingsDisabledCoursesKey = @"OEXPushSettingsDisabledCoursesKey";

NSString* const OEXPushSettingsChangedNotification = @"OEXPushSettingsChangedNotification";

@interface OEXPushSettingsManager ()

@property (copy, nonatomic) NSArray* disabledCourses;

@end

@implementation OEXPushSettingsManager

- (BOOL)isPushDisabledForCourseWithID:(NSString*)courseID {
    return [[self disabledCourses] containsObject:courseID];
}

- (NSArray*)disabledCourses {
    return [[NSUserDefaults standardUserDefaults] objectForKey:OEXPushSettingsDisabledCoursesKey] ?: @[];
}

- (void)setDisabledCourses:(NSArray*)courses {
    [[NSUserDefaults standardUserDefaults] setObject:courses forKey:OEXPushSettingsDisabledCoursesKey];
    [[NSNotificationCenter defaultCenter] postNotificationName:OEXPushSettingsChangedNotification object:nil];
}

- (void)setPushDisabled:(BOOL)disabled forCourseID:(NSString *)courseID {
    if(disabled) {
        self.disabledCourses = [self.disabledCourses arrayByAddingObject:courseID];
    }
    else {
        self.disabledCourses = [self.disabledCourses oex_arrayByRemovingObject:courseID];
    }
}

@end
