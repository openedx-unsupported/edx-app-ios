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

@interface OEXGoogleSocial () <GIDSignInDelegate>

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
    GIDSignIn* signIn = [GIDSignIn sharedInstance];

    signIn.shouldFetchBasicProfile = YES;

    // You previously set kClientId in the "Initialize the Google+ client" step
    OEXGoogleConfig* googleConfig = [OEXConfig sharedConfig].googleConfig;
    signIn.clientID = googleConfig.apiKey;

    // Uncomment one of these two statements for the scope you chose in the previous step
    // signIn.scopes = @[ kGTLAuthScopePlusUserinfoEmail ];  // "https://www.googleapis.com/auth/plus.login" scope
    signIn.scopes = @[ @"profile" ];            // "profile" scope
    // Optional: declare signIn.actions, see "app activities"
    signIn.delegate = self;
    signIn.presentingViewController = self.presentingController;
    [signIn signIn];
}

- (BOOL)isLogin {
    OEXConfig* config = [OEXConfig sharedConfig];
    OEXGoogleConfig* googleConfig = [config googleConfig];
    if(googleConfig.apiKey && googleConfig.enabled) {
        return [[GIDSignIn sharedInstance] hasPreviousSignIn];
    }

    return NO;
}

- (void)logout {
    [self clearHandler];
    OEXConfig* config = [OEXConfig sharedConfig];
    OEXGoogleConfig* googleConfig = [config googleConfig];
    if(googleConfig.apiKey && googleConfig.enabled) {
        [[GIDSignIn sharedInstance] signOut];
    }
}

- (void)clearHandler {
    self.completionHandler = nil;
    self.presentingController = nil;
}

- (void)signIn:(GIDSignIn *)signIn didSignInForUser:(GIDGoogleUser *)user withError:(NSError *)error {
    OEXLogInfo(@"SOCIAL", @"Google Auth Received error %@ and auth object %@", error, signIn);
    NSString* serverCode = signIn.currentUser.authentication.accessToken;
    
    if(self.completionHandler != nil) {
        self.completionHandler(serverCode, error);
    }
    [self clearHandler];
}

- (void)requestUserProfileInfoWithCompletion:(void (^)(GIDProfileData*))completion {
    completion([GIDSignIn sharedInstance].currentUser.profile);
}

- (void)signIn:(GIDSignIn *)signIn presentViewController:(UIViewController *)viewController {
    [self.presentingController presentViewController:viewController animated:YES completion:nil];
}

- (void)signIn:(GIDSignIn *)signIn dismissViewController:(UIViewController *)viewController {
    [viewController dismissViewControllerAnimated:YES completion:nil];
}

@end
