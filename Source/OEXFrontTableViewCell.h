//
//  OEXFrontTableViewCell.h
//  edXVideoLocker
//
//  Created by Rahul Varma on 09/06/14.
//  Copyright (c) 2014-2016 edX. All rights reserved.
//

@class OEXCourse;
@class CourseCardView;

NS_ASSUME_NONNULL_BEGIN

@interface OEXFrontTableViewCell : UITableViewCell

@property (weak, nonatomic, nullable) IBOutlet CourseCardView* infoView;


@end

NS_ASSUME_NONNULL_END
