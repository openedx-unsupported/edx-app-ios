//
//  OEXFBSocial.m
//  edXVideoLocker
//
//  Created by Prashant Kurhade on 20/11/14.
//  Copyright (c) 2014 edX. All rights reserved.
//

#import "OEXFBSocial.h"
#import <FBSDKLoginKit/FBSDKLoginKit.h>

#import "edX-Swift.h"
#import "Logger+OEXObjC.h"

#import "NSNotificationCenter+OEXSafeAccess.h"
#import "OEXConfig.h"
#import "OEXFacebookConfig.h"
#import "OEXSession.h"

@interface OEXFBSocial ()


@end

@implementation OEXFBSocial

- (id)init {
    self = [super init];
    if(self != nil) {
        [[NSNotificationCenter defaultCenter] oex_addObserver:self notification:OEXSessionEndedNotification action:^(NSNotification *notification, OEXFBSocial* observer, id<OEXRemovable> removable) {
            [observer logout];
        }];
    }
    return self;
}

- (void)loginFromController:(UIViewController *)controller completion:(void (^)(NSString *, NSError *))completionHandler {
    FBSDKLoginManager* fbLoginManager = [[FBSDKLoginManager alloc]init];
    [fbLoginManager logInWithReadPermissions:@[@"email", @"public_profile"] fromViewController:controller handler:^(FBSDKLoginManagerLoginResult *result, NSError *error) {
        FBSDKAccessToken* accessToken = [FBSDKAccessToken currentAccessToken];
        
        if (error) {
            completionHandler(nil, error);
        } else if (result.isCancelled) {
            completionHandler(nil, error); //Reflecting as an error for now, before further discussion
        } else {
            if (![result.grantedPermissions containsObject:@"email"]) {
                OEXLogInfo(@"SOCIAL", @"Email permission is missing");
            }
            if (![result.grantedPermissions containsObject:@"public_profile"]) {
                OEXLogInfo(@"SOCIAL", @"Public profile permission is missing");
            }
            completionHandler([accessToken tokenString],error);
        }
    }];
}

- (BOOL)isLogin {
    OEXConfig* config = [OEXConfig sharedConfig];
    OEXFacebookConfig* facebookConfig = [config facebookConfig];
    if(facebookConfig.appId && facebookConfig.enabled) {
        return [FBSDKAccessToken currentAccessToken] != nil;
    }
    return NO;
}

- (void)logout {
    if([self isLogin]) {
        FBSDKLoginManager* fbLoginManager = [[FBSDKLoginManager alloc]init];
        [fbLoginManager logOut];
    }
}

- (void)requestUserProfileInfoWithCompletion:(void (^)(NSDictionary*, NSError *))completion {
    if([FBSDKAccessToken currentAccessToken])
    {
        [[[FBSDKGraphRequest alloc]initWithGraphPath:@"me" parameters:nil] startWithCompletionHandler:^(FBSDKGraphRequestConnection *connection, id result, NSError *error) {
            completion(result, error);
        }];
    }
}

@end

