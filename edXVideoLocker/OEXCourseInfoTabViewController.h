//
//  OEXCourseInfoTabViewController.h
//  edXVideoLocker
//
//  Created by Abhradeep on 17/02/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

#import <UIKit/UIKit.h>

@class OEXCourse;
@class OEXCourseInfoTabViewController;

@protocol OEXCourseInfoTabViewControllerDelegate <NSObject>

-(void)courseInfoTabViewControllerUserTappedOnViewHandouts:(OEXCourseInfoTabViewController *)courseInfoTabViewController;

@end

@interface OEXCourseInfoTabViewController : UIViewController

@property (weak, nonatomic) id <OEXCourseInfoTabViewControllerDelegate> delegate;

-(instancetype)initWithCourse:(OEXCourse *)course;
-(void)useAnnouncements:(NSArray *)announcements;
-(void)layoutScrollView;
@end
