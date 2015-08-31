//
//  OEXFrontTableViewCell.h
//  edXVideoLocker
//
//  Created by Rahul Varma on 09/06/14.
//  Copyright (c) 2014-2015 edX. All rights reserved.
//

@import UIKit;

@class OEXCourse;
@class CourseDashboardCourseInfoView;

@interface OEXFrontTableViewCell : UITableViewCell

@property (weak, nonatomic) IBOutlet CourseDashboardCourseInfoView* infoView;


@end
