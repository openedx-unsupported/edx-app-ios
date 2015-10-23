//
//  OEXCoursewareAccess.m
//  edX
//
//  Created by Linda Liu on 7/9/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

#import "OEXCoursewareAccess.h"

@interface OEXCoursewareAccess ()

@property (nonatomic) BOOL has_access;
@property (nonatomic) OEXAccessError error_code;
@property (nonatomic, copy) NSString* developer_message;
@property (nonatomic, copy) NSString* user_message;

@end

@implementation OEXCoursewareAccess

- (id)initWithDictionary:(NSDictionary *)info {
    NSDictionary* errors = @{
                             @"course_not_started" : @(OEXStartDateError),
                             @"not_visible_to_user" : @(OEXVisibilityError),
                             @"unfulfilled_milestones" : @(OEXMilestoneError)
                             };
    self = [super init];
    if(self != nil) {
        // if there's no field then there was no access error so default to YES
        self.has_access = [([info objectForKey:@"has_access"] ?: @(YES)) boolValue];
        self.developer_message = [info objectForKey:@"developer_message"];
        self.user_message = [info objectForKey:@"user_message"];
        NSString* error_code_string = [info objectForKey:@"error_code"];
        if ([error_code_string length] == 0) {
            self.error_code = OEXUnknownError;
        }
        else {
            self.error_code = [[errors objectForKey:error_code_string] intValue];
        }
    }
    
    return self;
}

@end
