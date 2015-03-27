//
//  OEXEnvironment.m
//  edXVideoLocker
//
//  Created by Akiva Leffert on 12/29/14.
//  Copyright (c) 2014 edX. All rights reserved.
//

#import "OEXEnvironment.h"

#import "OEXConfig.h"
#import "OEXRouter.h"
#import "OEXSegmentAnalyticsTracker.h"
#import "OEXSession.h"
#import "OEXStyles.h"

@interface OEXEnvironment ()

@property (strong, nonatomic) OEXAnalytics* (^ analyticsBuilder)(void);
@property (strong, nonatomic) OEXConfig* (^ configBuilder)(void);
@property (strong, nonatomic) OEXRouter* (^ routerBuilder)(void);
@property (strong, nonatomic) OEXSession* (^ sessionBuilder)(void);
@property (strong, nonatomic) OEXStyles* (^ stylesBuilder)(void);

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
        self.configBuilder = ^{
            return [[OEXConfig alloc] initWithAppBundleData];
        };
        self.routerBuilder = ^{
            return [[OEXRouter alloc] init];
        };
        self.analyticsBuilder = ^{
            OEXAnalytics* analytics = [[OEXAnalytics alloc] init];
            OEXSegmentConfig* segmentConfig = [[OEXConfig sharedConfig] segmentConfig];
            if(segmentConfig.apiKey != nil && segmentConfig.isEnabled) {
                [analytics addTracker:[[OEXSegmentAnalyticsTracker alloc] init]];
            }
            return analytics;
        };
        self.stylesBuilder = ^{
            return [[OEXStyles alloc] init];
        };
        self.sessionBuilder = ^{
            return [[OEXSession alloc] init];
        };
    }
    return self;
}

- (void)setupEnvironment {
    [OEXConfig setSharedConfig:self.configBuilder()];
    [OEXRouter setSharedRouter:self.routerBuilder()];
    [OEXAnalytics setSharedAnalytics:self.analyticsBuilder()];
    [OEXSession setSharedSession:self.sessionBuilder()];
    [OEXStyles setSharedStyles:self.stylesBuilder()];
}
@end
