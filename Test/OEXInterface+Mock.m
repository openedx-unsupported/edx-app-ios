//
//  Mock+OEXInterface.m
//  edX
//
//  Created by Akiva Leffert on 11/30/15.
//  Copyright © 2015 edX. All rights reserved.
//

#import "OEXInterface+Mock.h"

#import "edX-Swift.h"
#import <OCMock/OCMock.h>

@implementation OEXInterface (Mock)

+ (void)withMockedCourseList:(NSArray<UserCourseEnrollment*>*)enrollments action:(void (^)(OEXInterface*))action {
    OCMockObject* interface = OCMStrictClassMock([OEXInterface class]);
    
    for(UserCourseEnrollment* enrollment in enrollments) {
        id stub = [interface stub];
        [stub enrollmentForCourseWithID:enrollment.course.course_id];
        [stub andReturn:enrollment];
        
        id courseStub = [interface stub];
        [courseStub courseWithID:enrollment.course.course_id];
        [courseStub andReturn:enrollment.course];
    }

    NSMutableArray* views = [[NSMutableArray alloc] init];
    id stub = [interface stub];
    [stub progressViews];
    [stub andReturn:views];
    action((OEXInterface*)interface);
    [interface stopMocking];
}

@end
