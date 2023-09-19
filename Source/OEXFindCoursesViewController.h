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
};

@interface OEXFindCoursesViewController : UIViewController

@property (readonly, strong, nonatomic) UIView* bottomBar;
- (void) updateTitleViewVisibility;
- (instancetype) initWithEnvironment:(RouterEnvironment* _Nullable)environment showBottomBar:(BOOL) showBottomBar bottomBar:(UIView* _Nullable)bottomBar searchQuery:(nullable NSString*)searchQuery fromStartupScreen:(BOOL) fromStartupScreen;
@property (nonatomic) OEXFindCoursesBaseType startURL;
@property (nonatomic) BOOL fromStartupScreen;
@end

NS_ASSUME_NONNULL_END
