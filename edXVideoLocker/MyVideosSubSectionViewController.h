//
//  MyVideosSubSectionViewController.h
//  edXVideoLocker
//
//  Created by Rahul Varma on 30/06/14.
//  Copyright (c) 2014 edX. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CustomNavigationView.h"
#import "DACircularProgressView.h"
#import "CustomEditingView.h"
#import "Course.h"


@interface MyVideosSubSectionViewController : UIViewController <UIAlertViewDelegate>

@property (nonatomic, strong) NSMutableArray * arr_CourseData;
@property (nonatomic, strong) Course *obj_Course;
@end
