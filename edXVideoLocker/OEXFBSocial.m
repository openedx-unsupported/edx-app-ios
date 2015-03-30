//
//  OEXFBSocial.m
//  edXVideoLocker
//
//  Created by Prashant Kurhade on 20/11/14.
//  Copyright (c) 2014 edX. All rights reserved.
//

#import "OEXFBSocial.h"
#import "OEXConfig.h"
@interface OEXFBSocial ()

@property(copy, nonatomic) void(^completionHandler)(NSString* accessToken, NSError* error);

@end

@implementation OEXFBSocial

+ (id)sharedInstance {
    static OEXFBSocial* sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

- (void)login:(void (^)(NSString *, NSError *))completionHandler {
    self.completionHandler = completionHandler;
    FBSession* session = [[FBSession alloc] initWithPermissions:@[@"email", @"public_profile"]];
    // Set the active session
    [FBSession setActiveSession:session];
    // Open the session
    [session openWithBehavior:FBSessionLoginBehaviorWithFallbackToWebView
            completionHandler:^(FBSession* session,
                                FBSessionState status,
                                NSError* error) {
        NSString* accessToken = nil;
        if(session.state == FBSessionStateOpen) {
            [FBSession setActiveSession:session];
            accessToken = session.accessTokenData.accessToken;
        }
        if(self.completionHandler) {
            if(accessToken || error) {
                switch(status) {
                    case FBSessionStateOpen:
                        self.completionHandler([FBSession.activeSession accessTokenData].accessToken, error);
                        break;
                    case FBSessionStateClosedLoginFailed:
                        self.completionHandler(nil, error);
                        break;
                    default:
                        break;
                }
            }
        }
    }];
}

- (BOOL)isLogin {
    OEXConfig* config = [OEXConfig sharedConfig];
    OEXFacebookConfig* facebookConfig = [config facebookConfig];
    if(facebookConfig.appId && facebookConfig.enabled) {
        return [[FBSession activeSession] isOpen];
    }
    return NO;
}

- (void)clearHandler {
    self.completionHandler = nil;
}

- (void)logout {
    if([self isLogin]) {
        [[FBSession activeSession] closeAndClearTokenInformation];
    }
}


- (void)requestUserProfileInfoWithCompletion:(void (^)(NSDictionary*, NSError *))completion {
    [[FBRequest requestForMe] startWithCompletionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
        completion(result, error);
    }];
}

@end
