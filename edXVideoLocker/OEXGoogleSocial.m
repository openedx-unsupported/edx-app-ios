//
//  GoogleSocial.m
//  edXVideoLocker
//
//  Created by Prashant Kurhade on 21/11/14.
//  Copyright (c) 2014 edX. All rights reserved.
//

#import <GoogleOpenSource/GoogleOpenSource.h>
#import "OEXGoogleSocial.h"
#import "EDXConfig.h"
#import "EDXEnvironment.h"

@interface OEXGoogleSocial ()
{
    OEXGoogleOEXFBLoginCompletionHandler delegateHandler;
}

@end


@implementation OEXGoogleSocial
+ (id)sharedInstance{
    static OEXGoogleSocial *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}


-(void)googleLogin:(OEXGoogleOEXFBLoginCompletionHandler)completionHandler
{
    delegateHandler = completionHandler;
    GPPSignIn *signIn = [GPPSignIn sharedInstance];
    //signIn.shouldFetchGooglePlusUser = YES;
    signIn.shouldFetchGoogleUserEmail = YES;  // Uncomment to get the user's email
    
    // You previously set kClientId in the "Initialize the Google+ client" step
    signIn.clientID = [EDXEnvironment shared].config.googlePlusKey;
    
    // Uncomment one of these two statements for the scope you chose in the previous step
   // signIn.scopes = @[ kGTLAuthScopePlusUserinfoEmail ];  // "https://www.googleapis.com/auth/plus.login" scope
    signIn.scopes = @[ @"profile" ];            // "profile" scope
    // Optional: declare signIn.actions, see "app activities"
    signIn.delegate = self;
    
    [signIn authenticate];

}

-(BOOL)isLogin
{
    if([[GPPSignIn sharedInstance]hasAuthInKeychain])
    {
        return YES;
    }
    return NO;
}

-(void)logout
{
      delegateHandler=nil;
     [[GPPSignIn sharedInstance] signOut];
}

-(void)clearGoogleSession
{
    GPPSignIn *signIn = [GPPSignIn sharedInstance];
    [signIn disconnect];
}
-(void)clearHandler
{
    [self clearGoogleSession];
    delegateHandler=nil;
}
- (void)finishedWithAuth: (GTMOAuth2Authentication *)auth
                   error: (NSError *) error {
    NSLog(@"Received error %@ and auth object %@", error, auth);
    NSString *serverCode=nil;
    if (error) {
        // Do some error handling here.
        [self clearGoogleSession];
    } else {
        serverCode = auth.accessToken;
    }
    if(delegateHandler)
    {
        delegateHandler(serverCode,error);
    }
    else
    {
        [self clearGoogleSession];
    }
}


@end
