//
//  OEXGenericCourseTableViewController.h
//  edXVideoLocker
//
//  Created by Rahul Varma on 26/05/14.
//  Copyright (c) 2014 edX. All rights reserved.
//

#import <UIKit/UIKit.h>

@class OEXCourse;
@class OEXVideoPathEntry;

@interface OEXGenericCourseTableViewController : UIViewController

@property (strong, nonatomic) OEXCourse* course;

@property (nonatomic, strong) NSArray *arr_TableCourseData;
@property (nonatomic, strong) OEXVideoPathEntry* selectedChapter;

@end
