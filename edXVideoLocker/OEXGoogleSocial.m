//
//  GoogleSocial.m
//  edXVideoLocker
//
//  Created by Prashant Kurhade on 21/11/14.
//  Copyright (c) 2014 edX. All rights reserved.
//

#import <GoogleOpenSource/GoogleOpenSource.h>
#import <GooglePlus/GooglePlus.h>
#import "OEXGoogleSocial.h"
#import "OEXConfig.h"

@interface OEXGoogleSocial () <GPPSignInDelegate>

@property (copy, nonatomic) OEXGoogleOEXLoginCompletionHandler completionHandler;

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

- (void)login:(OEXGoogleOEXLoginCompletionHandler)completionHandler {
    self.handledOpenUrl = NO;
    self.completionHandler = completionHandler;
    GPPSignIn* signIn = [GPPSignIn sharedInstance];

    signIn.shouldFetchGooglePlusUser = YES;
    signIn.shouldFetchGoogleUserEmail = YES;

    // You previously set kClientId in the "Initialize the Google+ client" step
    OEXGoogleConfig* googleConfig = [OEXConfig sharedConfig].googleConfig;
    signIn.clientID = googleConfig.apiKey;

    // Uncomment one of these two statements for the scope you chose in the previous step
    // signIn.scopes = @[ kGTLAuthScopePlusUserinfoEmail ];  // "https://www.googleapis.com/auth/plus.login" scope
    signIn.scopes = @[ @"profile" ];            // "profile" scope
    // Optional: declare signIn.actions, see "app activities"
    signIn.delegate = self;
    [signIn authenticate];
}

- (BOOL)isLogin {
    OEXConfig* config = [OEXConfig sharedConfig];
    OEXGoogleConfig* googleConfig = [config googleConfig];
    if(googleConfig.apiKey && googleConfig.enabled) {
        return [[GPPSignIn sharedInstance]hasAuthInKeychain];
    }

    return NO;
}

- (void)logout {
    [self clearHandler];
    OEXConfig* config = [OEXConfig sharedConfig];
    OEXGoogleConfig* googleConfig = [config googleConfig];
    if(googleConfig.apiKey && googleConfig.enabled) {
        [[GPPSignIn sharedInstance] signOut];
    }
}

- (void)clearHandler {
    self.completionHandler = nil;
}

- (void)finishedWithAuth:(GTMOAuth2Authentication*)auth
                   error:(NSError*)error {
    NSLog(@"Received error %@ and auth object %@", error, auth);
    NSString* serverCode = auth.accessToken;

    if(self.completionHandler != nil) {
        self.completionHandler(serverCode, error);
    }
    [self clearHandler];
}

- (void)requestUserProfileInfoWithCompletion:(void (^)(GTLPlusPerson*, NSString* profileEmail, NSError*))completion {
    GTLServicePlus* service = [[GTLServicePlus alloc] init];
    service.authorizer = [GPPSignIn sharedInstance].authentication;
    GTLQueryPlus* query = [GTLQueryPlus queryForPeopleGetWithUserId:@"me"];
    [service executeQuery:query completionHandler:^(GTLServiceTicket *ticket, id object, NSError *error) {
        completion(object, [[GPPSignIn sharedInstance] userEmail], error);
    }];
}

@end
