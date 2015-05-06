//
//  OEXCourseDashboardViewController.h
//  edX
//
//  Created by Akiva Leffert on 4/28/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

#import <UIKit/UIKit.h>

@class OEXConfig;
@class OEXCourse;
@class OEXRouter;

@interface OEXCourseDashboardViewControllerEnvironment : NSObject

- (id)initWithConfig:(OEXConfig*)config router:(OEXRouter*)router;

@property (strong, readonly, nonatomic) OEXConfig* config;
@property (weak, readonly, nonatomic) OEXRouter* router;

@end

@interface OEXCourseDashboardViewController : UIViewController

- (id)initWithEnvironment:(OEXCourseDashboardViewControllerEnvironment*)environment course:(OEXCourse*)course;

@end

@interface OEXCourseDashboardViewController (Testing)

- (BOOL)t_canVisitDicussions;

@end