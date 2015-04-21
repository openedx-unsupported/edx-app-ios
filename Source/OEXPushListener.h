//
//  OEXPushListener.h
//  edXVideoLocker
//
//  Created by Akiva Leffert on 4/13/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol OEXPushListener <NSObject>

- (void)didReceiveLocalNotificationWithUserInfo:(NSDictionary*)userInfo;
- (void)didReceiveRemoteNotificationWithUserInfo:(NSDictionary*)userInfo;

@end
