//
//  OEXFindCoursesViewController.h
//  edXVideoLocker
//
//  Created by Abhradeep on 02/02/15.
//  Copyright (c) 2015-2016 edX. All rights reserved.
//

NS_ASSUME_NONNULL_BEGIN

extern NSString* const OEXFindCoursesLinkURLScheme;

typedef NS_ENUM(NSInteger, OEXFindCoursesBaseType) {
    OEXFindCoursesBaseTypeFindCourses,
    OEXFindCoursesBaseTypeExploreSubjects
};

@interface OEXFindCoursesViewController : UIViewController
- (instancetype) initWithBottomBar:(UIView* _Nullable)bottomBar;
@property (nonatomic) OEXFindCoursesBaseType startURL;
@end

NS_ASSUME_NONNULL_END
