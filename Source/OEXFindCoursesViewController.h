//
//  OEXFindCoursesViewController.h
//  edXVideoLocker
//
//  Created by Abhradeep on 02/02/15.
//  Copyright (c) 2015-2016 edX. All rights reserved.
//

NS_ASSUME_NONNULL_BEGIN
@class RouterEnvironment;
extern NSString* const OEXFindCoursesLinkURLScheme;

typedef NS_ENUM(NSInteger, OEXFindCoursesBaseType) {
    OEXFindCoursesBaseTypeFindCourses,
    OEXFindCoursesBaseTypeExploreSubjects
};

@interface OEXFindCoursesViewController : UIViewController
- (instancetype) initWithEnvironment:(RouterEnvironment* _Nullable)environment bottomBar:(UIView* _Nullable)bottomBar searchQuery:(nullable NSString*)searchQuery;
@property (nonatomic) OEXFindCoursesBaseType startURL;
@end

NS_ASSUME_NONNULL_END
