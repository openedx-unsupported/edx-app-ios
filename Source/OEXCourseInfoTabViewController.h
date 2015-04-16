//
//  OEXCourseInfoTabViewController.h
//  edXVideoLocker
//
//  Created by Abhradeep on 17/02/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

#import <UIKit/UIKit.h>

@class OEXConfig;
@class OEXCourse;
@class OEXCourseInfoTabViewController;
@class OEXPushSettingsManager;
@class OEXStyles;

@interface OEXCourseInfoTabViewControllerEnvironment : NSObject

- (id)initWithConfig:(OEXConfig*)config
 pushSettingsManager:(OEXPushSettingsManager*)pushSettingsManager
              styles:(OEXStyles*)styles;

@property (readonly, strong, nonatomic) OEXConfig* config;
@property (readonly, strong, nonatomic) OEXPushSettingsManager* pushSettingsManager;
@property (readonly, strong, nonatomic) OEXStyles* styles;

@end

@protocol OEXCourseInfoTabViewControllerDelegate <NSObject>

- (void)courseInfoTabViewControllerUserTappedOnViewHandouts:(OEXCourseInfoTabViewController*)courseInfoTabViewController;

@end

@interface OEXCourseInfoTabViewController : UIViewController

@property (weak, nonatomic) id <OEXCourseInfoTabViewControllerDelegate> delegate;

- (id)initWithCourse:(OEXCourse*)course environment:(OEXCourseInfoTabViewControllerEnvironment*)environment;
- (void)useAnnouncements:(NSArray*)announcements;
- (void)scrollToTop;

@end
