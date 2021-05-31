//
//  OEXPushListener.h
//  edXVideoLocker
//
//  Created by Akiva Leffert on 4/13/15.
//  Copyright (c) 2015-2016 edX. All rights reserved.
//

NS_ASSUME_NONNULL_BEGIN

@protocol OEXPushListener <NSObject>

- (void)didReceiveLocalNotificationWithUserInfo:(NSDictionary*)userInfo;
- (void)didReceiveRemoteNotificationWithUserInfo:(NSDictionary*)userInfo application:(nullable UIApplication *)application completionHandler:(nullable void (^)(UIBackgroundFetchResult))completionHandler;

@end

NS_ASSUME_NONNULL_END
