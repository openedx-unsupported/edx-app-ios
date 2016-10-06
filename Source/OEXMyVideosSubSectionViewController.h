//
//  OEXMyVideosSubSectionViewController.h
//  edXVideoLocker
//
//  Created by Rahul Varma on 30/06/14.
//  Copyright (c) 2014-2015 edX. All rights reserved.
//

@class OEXCourse;
@class RouterEnvironment;

NS_ASSUME_NONNULL_BEGIN

@interface OEXMyVideosSubSectionViewController : UIViewController <UIAlertViewDelegate>

@property (nonatomic, strong) NSMutableArray* arr_CourseData;
@property (nonatomic, strong) OEXCourse* course;
@property (strong, nonatomic) RouterEnvironment* environment;
@end

NS_ASSUME_NONNULL_END
