//
//  GoogleSocial.m
//  edXVideoLocker
//
//  Created by Prashant Kurhade on 21/11/14.
//  Copyright (c) 2014 edX. All rights reserved.
//

#import <GoogleSignIn/GoogleSignIn.h>

#import "edX-Swift.h"
#import "Logger+OEXObjC.h"

#import "NSNotificationCenter+OEXSafeAccess.h"
#import "OEXConfig.h"
#import "OEXGoogleConfig.h"
#import "OEXGoogleSocial.h"
#import "OEXRouter.h"
#import "OEXSession.h"

@interface OEXGoogleSocial ()

@property (copy, nonatomic) OEXGoogleOEXLoginCompletionHandler completionHandler;
@property (strong, nonatomic) UIViewController* presentingController;

@end

@implementation OEXGoogleSocial
+ (id)sharedInstance {
    static OEXGoogleSocial* sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

- (id)init {
    self = [super init];
    if(self != nil) {
        [[NSNotificationCenter defaultCenter] oex_addObserver:self notification:OEXSessionEndedNotification action:^(NSNotification *notification, OEXGoogleSocial* observer, id<OEXRemovable> removable) {
            [observer logout];
        }];
    }
    return self;
}

- (void)loginFromController:(UIViewController *)controller withCompletion:(OEXGoogleOEXLoginCompletionHandler)completionHandler {
    self.handledOpenUrl = NO;
    self.completionHandler = completionHandler;
    self.presentingController = controller;
    
    GIDConfiguration *config = [[GIDConfiguration alloc] initWithClientID:[OEXConfig sharedConfig].googleConfig.apiKey];
    GIDSignIn.sharedInstance.configuration = config;
    GIDSignIn* signIn = GIDSignIn.sharedInstance;
    
    __weak __auto_type weakSelf = self;
    [signIn signInWithPresentingViewController:self.presentingController completion:^(GIDSignInResult * _Nullable signInResult, NSError * _Nullable error) {
        __auto_type strongSelf = weakSelf;
        if (strongSelf == nil) { return; }
        
        NSString* serverCode = signInResult.user.accessToken.tokenString;
        
        if(strongSelf.completionHandler != nil) {
            strongSelf.completionHandler(serverCode, error);
        }
        [self clearHandler];
    }];
}

- (BOOL)isLogin {
    OEXConfig* config = [OEXConfig sharedConfig];
    OEXGoogleConfig* googleConfig = [config googleConfig];
    if(googleConfig.apiKey && googleConfig.enabled) {
        return [GIDSignIn.sharedInstance hasPreviousSignIn];
    }

    return NO;
}

- (void)logout {
    [self clearHandler];
    OEXConfig* config = [OEXConfig sharedConfig];
    OEXGoogleConfig* googleConfig = [config googleConfig];
    if(googleConfig.apiKey && googleConfig.enabled) {
        [GIDSignIn.sharedInstance signOut];
    }
}

- (void)clearHandler {
    self.completionHandler = nil;
    self.presentingController = nil;
}

- (void)requestUserProfileInfoWithCompletion:(void (^)(GIDProfileData*))completion {
    completion(GIDSignIn.sharedInstance.currentUser.profile);
}

@end
