//
//  OEXEnvironment.m
//  edXVideoLocker
//
//  Created by Akiva Leffert on 12/29/14.
//  Copyright (c) 2014 edX. All rights reserved.
//

#import "edX-Swift.h"

#import "OEXEnvironment.h"

#import <Analytics/SEGAnalytics.h>
#import <Segment-GoogleAnalytics/SEGGoogleAnalyticsIntegrationFactory.h>
#import "OEXAnalytics.h"
#import "OEXConfig.h"
#import "OEXInterface.h"
#import "OEXPushNotificationManager.h"
#import "OEXPushNotificationProcessor.h"
#import "OEXPushSettingsManager.h"
#import "OEXRouter.h"
#import "OEXSegmentConfig.h"
#import "OEXSession.h"
#import "OEXStyles.h"

@interface OEXEnvironment ()

@property (strong, nonatomic) OEXAnalytics* analytics;
@property (strong, nonatomic) OEXConfig* config;
@property (strong, nonatomic) DataManager* dataManager;
@property (strong, nonatomic) Logger* logger;
@property (strong, nonatomic) NetworkManager* networkManager;
@property (strong, nonatomic) OEXPushNotificationManager* pushNotificationManager;
@property (strong, nonatomic) OEXRouter* router;
@property (strong, nonatomic) OEXSession* session;
@property (strong, nonatomic) OEXStyles* styles;

/// Array of actions to be executed once all the objects are wired up
/// Used to resolve what would be otherwise be circular dependencies
@property (strong, nonatomic) NSMutableArray* postSetupActions;

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
        self.postSetupActions = [[NSMutableArray alloc] init];
        
        self.loggerBuilder = ^(OEXEnvironment* env) {
            return Logger.sharedLogger;
        };
        
        self.analyticsBuilder = ^(OEXEnvironment* env){
            NSCAssert(env.config != nil, @"Config should be enabled before analytics are set up");
            OEXAnalytics* analytics = [[OEXAnalytics alloc] init];
            OEXSegmentConfig* segmentConfig = [env.config segmentConfig];
            if(segmentConfig.apiKey != nil && segmentConfig.isEnabled) {
                [[SEGAnalyticsConfiguration configurationWithWriteKey:segmentConfig.apiKey] use:[SEGGoogleAnalyticsIntegrationFactory instance]];
                [analytics addTracker:[[SegmentAnalyticsTracker alloc] init]];
            }
            
            if (env.config.isFirebaseEnabled) {
                [analytics addTracker:[[FirebaseAnalyticsTracker alloc] init]];
            }
            
            if((segmentConfig.apiKey != nil && segmentConfig.isEnabled) || env.config.isFirebaseEnabled) {
                [analytics addTracker:[[LoggingAnalyticsTracker alloc] init]];
            }
            return analytics;
        };
        self.configBuilder = ^(OEXEnvironment* env){
            return [[OEXConfig alloc] initWithAppBundleData];
        };
        self.pushNotificationManagerBuilder = ^OEXPushNotificationManager*(OEXEnvironment* env) {
            NSCAssert(env.config != nil, @"Config should be enabled before analytics are set up");
            if(env.config.pushNotificationsEnabled) {
                OEXPushNotificationManager* manager = [[OEXPushNotificationManager alloc] initWithSettingsManager:env.dataManager.pushSettings];
                [manager addProvidersForConfiguration:env.config withSession:env.session];
                
                if(env.config.pushNotificationsEnabled) {
                    [env.postSetupActions addObject:^(OEXEnvironment* env) {
                        OEXPushNotificationProcessorEnvironment* pushEnvironment = [[OEXPushNotificationProcessorEnvironment alloc] initWithAnalytics:env.analytics router:env.router];
                        [env.pushNotificationManager addListener:[[OEXPushNotificationProcessor alloc] initWithEnvironment:pushEnvironment]];
                    }];
                }
                
                return manager;
            }
            else {
                return nil;
            }
        };
        self.dataManagerBuilder = ^(OEXEnvironment* env) {
            OEXPushSettingsManager* pushSettingsManager = [[OEXPushSettingsManager alloc] init];
            EnrollmentManager* enrollmentManager =
            [[EnrollmentManager alloc] initWithInterface:[OEXInterface sharedInterface]
                                          networkManager:env.networkManager config:env.config];
            UserProfileManager* userProfileManager =
            [[UserProfileManager alloc]
             initWithNetworkManager:env.networkManager
             session:env.session];
            UserPreferenceManager* userPreferenceManager =
            [[UserPreferenceManager alloc]
             initWithNetworkManager:env.networkManager];
            CourseDataManager* courseDataManager =
            [[CourseDataManager alloc]
             initWithAnalytics:env.analytics
             enrollmentManager:enrollmentManager
             interface:[OEXInterface sharedInterface]
             networkManager:env.networkManager
             session:env.session];
            return [[DataManager alloc] initWithCourseDataManager:courseDataManager
                                                enrollmentManager:enrollmentManager
                                                        interface:[OEXInterface sharedInterface]
                                                     pushSettings:pushSettingsManager
                                               userProfileManager:userProfileManager
                                            userPreferenceManager:userPreferenceManager
                    ];
        };
        self.networkManagerBuilder = ^(OEXEnvironment* env) {
            PersistentResponseCache* cache = [[PersistentResponseCache alloc] initWithProvider: [[SessionUsernameProvider alloc] initWithSession:env.session]];
            NetworkManager* manager = [[NetworkManager alloc]
                                       initWithAuthorizationHeaderProvider:env.session
                                       credentialProvider:env.config
                                       baseURL:env.config.apiHostURL
                                       cache: cache];
            [env.postSetupActions addObject:^(OEXEnvironment* env) {
                [manager addStandardInterceptors];
                [manager addResponseInterceptors];
                [manager addRefreshTokenAuthenticatorWithRouter:env.router session:env.session clientId:env.config.oauthClientID];
            }];
            return manager;
        };
        self.routerBuilder = ^(OEXEnvironment* env) {
            RouterEnvironment* routerEnv = [[RouterEnvironment alloc]
                                            initWithAnalytics:env.analytics
                                            config:env.config
                                            dataManager:env.dataManager
                                            interface:[OEXInterface sharedInterface]
                                            networkManager:env.networkManager
                                            reachability:[[InternetReachability alloc] init]
                                            session:env.session
                                            styles:env.styles
                                            ];
            return [[OEXRouter alloc] initWithEnvironment:routerEnv];
            
        };
        self.stylesBuilder = ^(OEXEnvironment* env){
            return [[OEXStyles alloc] init];
        };
        self.sessionBuilder = ^(OEXEnvironment* env){
            OEXSession* session = [[OEXSession alloc] init];
            [env.postSetupActions addObject: ^(OEXEnvironment* env) {
                [env.session loadTokenFromStore];
            }];
            return session;
        };
    }
    return self;
}

- (void)setupEnvironment {
    // TODO: automatically order by dependencies
    // For now, make sure this is the right order for dependencies
    self.logger = self.loggerBuilder(self);
    
    self.config = self.configBuilder(self);
    self.analytics = self.analyticsBuilder(self);
    
    self.session = self.sessionBuilder(self);
    
    self.networkManager = self.networkManagerBuilder(self);
    self.dataManager = self.dataManagerBuilder(self);
    self.pushNotificationManager = self.pushNotificationManagerBuilder(self);
    
    self.styles = self.stylesBuilder(self);
    self.router = self.routerBuilder(self);
    
    // We should minimize the use of these singletons and mostly use explicitly passed in dependencies
    // But occasionally that's very inconvenient and also much existing code is not structured to deal with that
    [OEXConfig setSharedConfig:self.config];
    [OEXRouter setSharedRouter:self.router];
    [OEXAnalytics setSharedAnalytics:self.analytics];
    [OEXSession setSharedSession:self.session];
    [OEXStyles setSharedStyles:self.styles];
    
    for(void (^action)(OEXEnvironment*) in self.postSetupActions) {
        action(self);
    }
    
    [self.postSetupActions removeAllObjects];
    
    [self.styles applyGlobalAppearance];
    
}

@end
