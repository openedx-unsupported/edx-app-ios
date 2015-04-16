//
//  OEXCustomTabBarViewViewController.h
//  edXVideoLocker
//
//  Created by Nirbhay Agarwal on 16/05/14.
//  Copyright (c) 2014 edX. All rights reserved.
//

#import <UIKit/UIKit.h>

@class OEXAnalytics;
@class OEXConfig;
@class OEXCourse;
@class OEXPushSettingsManager;
@class OEXStyles;

@interface OEXCustomTabBarViewViewControllerEnvironment : NSObject

- (id)initWithAnalytics:(OEXAnalytics*)analytics
                 config:(OEXConfig*)config
    pushSettingsManager:(OEXPushSettingsManager*)pushSettingsManager
                 styles:(OEXStyles*)styles;

@property (readonly, strong, nonatomic) OEXAnalytics* analytics;
@property (readonly, strong, nonatomic) OEXConfig* config;
@property (readonly, strong, nonatomic) OEXPushSettingsManager* pushSettingsManager;
@property (readonly, strong, nonatomic) OEXStyles* styles;

@end

@interface OEXCustomTabBarViewViewController : UIViewController

@property (nonatomic, strong) OEXCustomTabBarViewViewControllerEnvironment* environment;
@property (nonatomic, strong) OEXCourse* course;

@end
