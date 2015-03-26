//
//  OEXFBSocial.h
//  edXVideoLocker
//
//  Created by Prashant Kurhade on 20/11/14.
//  Copyright (c) 2014 edX. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <FacebookSDK/FacebookSDK.h>

@interface OEXFBSocial : NSObject

+ (instancetype)sharedInstance;
- (void)login:(void(^)(NSString* accessToken,NSError* error))completionHandler;
- (void)logout;
- (void)clearHandler;
- (BOOL)isLogin;

- (void)requestUserProfileInfoWithCompletion:(void(^)(NSDictionary* userProfile, NSError* error))completion;

@end
