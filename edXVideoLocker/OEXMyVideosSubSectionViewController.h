//
//  OEXMyVideosSubSectionViewController.h
//  edXVideoLocker
//
//  Created by Rahul Varma on 30/06/14.
//  Copyright (c) 2014 edX. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "OEXCustomNavigationView.h"
#import "DACircularProgressView.h"
#import "OEXCustomEditingView.h"
#import "OEXCourse.h"


@interface OEXMyVideosSubSectionViewController : UIViewController <UIAlertViewDelegate>

@property (nonatomic, strong) NSMutableArray * arr_CourseData;
@property (nonatomic, strong) OEXCourse *course;
@end
