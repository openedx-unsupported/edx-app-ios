//
//  OEXGenericCourseTableViewController.h
//  edXVideoLocker
//
//  Created by Rahul Varma on 26/05/14.
//  Copyright (c) 2014-2016 edX. All rights reserved.
//

NS_ASSUME_NONNULL_BEGIN

@class OEXCourse;
@class OEXVideoPathEntry;

@interface OEXGenericCourseTableViewController : UIViewController

@property (strong, nonatomic) OEXCourse* course;

@property (nonatomic, strong) NSArray* arr_TableCourseData;
@property (nonatomic, strong) OEXVideoPathEntry* selectedChapter;

@end

NS_ASSUME_NONNULL_END
