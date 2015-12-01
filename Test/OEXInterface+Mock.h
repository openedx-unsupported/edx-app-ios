//
//  OEXInterface+Mock.h
//  edX
//
//  Created by Akiva Leffert on 11/30/15.
//  Copyright © 2015 edX. All rights reserved.
//

#import "OEXInterface.h"

@interface OEXInterface (Mock)

+ (void)withMockedCourseList:(NSArray*)courses action:(void (^)(OEXInterface*))action;

@end
