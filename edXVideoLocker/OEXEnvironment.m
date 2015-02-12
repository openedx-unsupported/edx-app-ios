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

@interface OEXEnvironment ()

@property (strong, nonatomic) OEXConfig*(^configBuilder)(void);
@property (strong, nonatomic) OEXRouter*(^routerBuilder)(void);
@property (strong, nonatomic) OEXAnalytics*(^analyticsBuilder)(void);

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
            
            if([OEXConfig sharedConfig].segmentIOKey != nil) {
                [analytics addTracker:[[OEXSegmentAnalyticsTracker alloc] init]];
            }
            return analytics;
        };
    }
    return self;
}

- (void)setupEnvironment {
    [OEXConfig setSharedConfig:self.configBuilder()];
    [OEXRouter setSharedRouter:self.routerBuilder()];
    [OEXAnalytics setSharedAnalytics:self.analyticsBuilder()];
}

@end
