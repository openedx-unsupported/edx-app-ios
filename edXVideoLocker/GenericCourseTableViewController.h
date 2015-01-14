//
//  GenericCourseTableViewController.h
//  edXVideoLocker
//
//  Created by Rahul Varma on 26/05/14.
//  Copyright (c) 2014 edX. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CustomNavigationView.h"
#import "DACircularProgressView.h"

@interface GenericCourseTableViewController : UIViewController
@property (nonatomic , strong) NSMutableArray *arr_TableCourseData;
@property (nonatomic , strong) NSString *str_ClickedChapter;
@end
