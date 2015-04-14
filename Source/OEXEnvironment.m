//
//  OEXEnvironment.m
//  edXVideoLocker
//
//  Created by Akiva Leffert on 12/29/14.
//  Copyright (c) 2014 edX. All rights reserved.
//

#import "OEXEnvironment.h"

#import "OEXAnalytics.h"
#import "OEXConfig.h"
#import "OEXPushNotificationManager.h"
#import "OEXPushSettingsManager.h"
#import "OEXRouter.h"
#import "OEXSegmentAnalyticsTracker.h"
#import "OEXSegmentConfig.h"
#import "OEXSession.h"
#import "OEXStyles.h"

@interface OEXEnvironment ()

@property (strong, nonatomic) OEXAnalytics* analytics;
@property (strong, nonatomic) OEXConfig* config;
@property (strong, nonatomic) OEXPushNotificationManager* pushNotificationManager;
@property (strong, nonatomic) OEXPushSettingsManager* pushSettingsManager;
@property (strong, nonatomic) OEXRouter* router;
@property (strong, nonatomic) OEXSession* session;
@property (strong, nonatomic) OEXStyles* styles;

@end

@implementation OEXEnvironment

+ (instancetype)shared {
    static dispatch_once_t onceToken;
    static OEXEnvironment* shared = nil;
    dispatch_once(&onceToken, ^{
        shared = [[OEXEnvironment alloc] init];
    });
    return shared;
}

- (id)init {
    self = [super init];
    if(self != nil) {
        self.analyticsBuilder = ^(OEXEnvironment* env){
            OEXAnalytics* analytics = [[OEXAnalytics alloc] init];
            OEXSegmentConfig* segmentConfig = [[OEXConfig sharedConfig] segmentConfig];
            if(segmentConfig.apiKey != nil && segmentConfig.isEnabled) {
                [analytics addTracker:[[OEXSegmentAnalyticsTracker alloc] init]];
            }
            return analytics;
        };
        self.configBuilder = ^(OEXEnvironment* env){
            return [[OEXConfig alloc] initWithAppBundleData];
        };
        self.pushNotificationManagerBuilder = ^OEXPushNotificationManager*(OEXEnvironment* env) {
            if(env.config.pushNotificationsEnabled) {
                OEXPushNotificationManager* manager = [[OEXPushNotificationManager alloc] initWithSettingsManager:env.pushSettingsManager];
                [manager addProvidersForConfiguration:env.config withSession:env.session];
                return manager;
            }
            else {
                return nil;
            }
        };
        self.pushSettingsBuilder = ^(OEXEnvironment* env) {
            return [[OEXPushSettingsManager alloc] init];
        };
        self.routerBuilder = ^(OEXEnvironment* env) {
            OEXRouterEnvironment* routerEnv = [[OEXRouterEnvironment alloc]
                                               initWithAnalytics:env.analytics
                                               config:env.config
                                               pushSettingsManager:env.pushSettingsManager
                                               styles:env.styles];
            return [[OEXRouter alloc] initWithEnvironment:routerEnv];
        };
        self.stylesBuilder = ^(OEXEnvironment* env){
            return [[OEXStyles alloc] init];
        };
        self.sessionBuilder = ^(OEXEnvironment* env){
            return [[OEXSession alloc] init];
        };
    }
    return self;
}

- (void)setupEnvironment {
    // TODO: automatically order by dependencies
    // For now, make sure this is the right order for dependencies
    self.pushSettingsManager = self.pushSettingsBuilder(self);
    self.config = self.configBuilder(self);
    self.analytics = self.analyticsBuilder(self);
    self.pushNotificationManager = self.pushNotificationManagerBuilder(self);
    self.session = self.sessionBuilder(self);
    self.styles = self.stylesBuilder(self);
    self.router = self.routerBuilder(self);
    
    [OEXConfig setSharedConfig:self.config];
    [OEXRouter setSharedRouter:self.router];
    [OEXAnalytics setSharedAnalytics:self.analytics];
    [OEXSession setSharedSession:self.session];
    [OEXStyles setSharedStyles:self.styles];
}

@end
