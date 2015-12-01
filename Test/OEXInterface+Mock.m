//
//  Mock+OEXInterface.m
//  edX
//
//  Created by Akiva Leffert on 11/30/15.
//  Copyright © 2015 edX. All rights reserved.
//

#import "OEXInterface+Mock.h"

#import <OCMock/OCMock.h>

@implementation OEXInterface (Mock)

+ (void)withMockedCourseList:(NSArray*)courses action:(void (^)(OEXInterface*))action {
    OCMockObject* interface = OCMStrictClassMock([OEXInterface class]);
    for(OEXCourse* course in courses) {
        id stub = [interface stub];
        [stub courseWithID:course.course_id];
        [stub andReturn:course];
    }

    NSMutableArray* views = [[NSMutableArray alloc] init];
    id stub = [interface stub];
    [stub progressViews];
    [stub andReturn:views];
    action((OEXInterface*)interface);
    [interface stopMocking];
}

@end
