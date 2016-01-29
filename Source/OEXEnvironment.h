//
//  OEXEnvironment.h
//  edXVideoLocker
//
//  Created by Akiva Leffert on 12/29/14.
//  Copyright (c) 2014-2016 edX. All rights reserved.
//

NS_ASSUME_NONNULL_BEGIN

@class DataManager;
@class Logger;
@class NetworkManager;
@class OEXAnalytics;
@class OEXConfig;
@class OEXPushNotificationManager;
@class OEXPushSettingsManager;
@class OEXRouter;
@class OEXSession;
@class OEXStyles;

@interface OEXEnvironment : NSObject

- (void)setupEnvironment;

@property (strong, nonatomic) Logger* (^ loggerBuilder)(OEXEnvironment* env);
@property (strong, nonatomic) OEXAnalytics* (^ analyticsBuilder)(OEXEnvironment* env);
@property (strong, nonatomic) OEXConfig* (^ configBuilder)(OEXEnvironment* env);
@property (strong, nonatomic) DataManager* (^ dataManagerBuilder)(OEXEnvironment* env);
@property (strong, nonatomic) NetworkManager* (^ networkManagerBuilder)(OEXEnvironment* env);
@property (strong, nonatomic) OEXPushNotificationManager* (^ pushNotificationManagerBuilder)(OEXEnvironment* env);
@property (strong, nonatomic) OEXRouter* (^ routerBuilder)(OEXEnvironment* env);
@property (strong, nonatomic) OEXSession* (^ sessionBuilder)(OEXEnvironment* env);
@property (strong, nonatomic) OEXStyles* (^ stylesBuilder)(OEXEnvironment* env);

// These will all be nil until setupEnvironment is called
@property (readonly, strong, nonatomic) OEXAnalytics* analytics;
@property (readonly, strong, nonatomic) OEXConfig* config;
@property (readonly, strong, nonatomic) DataManager* dataManager;
@property (readonly, strong, nonatomic) NetworkManager* networkManager;
@property (readonly, strong, nonatomic) OEXPushNotificationManager* pushNotificationManager;
@property (readonly, strong, nonatomic) OEXRouter* router;
@property (readonly, strong, nonatomic) OEXSession* session;
@property (readonly, strong, nonatomic) OEXStyles* styles;

@end

NS_ASSUME_NONNULL_END

