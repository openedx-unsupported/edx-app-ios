//
//  OEXFBSocial.m
//  edXVideoLocker
//
//  Created by Prashant Kurhade on 20/11/14.
//  Copyright (c) 2014 edX. All rights reserved.
//

#import "OEXFBSocial.h"
#import "OEXConfig.h"
@interface OEXFBSocial (){
    
     OEXFBLoginCompletionHandler delegateHandler;
    
}

@end

@implementation OEXFBSocial

+ (id)sharedInstance{
    static OEXFBSocial *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
         sharedInstance = [[self alloc] init];
    });
    
    return sharedInstance;}

-(void)login:(OEXFBLoginCompletionHandler)completionHandler
{
    delegateHandler=[completionHandler copy];
    FBSession *session = [[FBSession alloc] init];
    // Set the active session
    [FBSession setActiveSession:session];
    // Open the session
    [session openWithBehavior:FBSessionLoginBehaviorWithFallbackToWebView
            completionHandler:^(FBSession *session,
                                FBSessionState status,
                                NSError *error) {
                NSString *accessToken= nil;
                if(session.state==FBSessionStateOpen)
                {
                    [FBSession setActiveSession:session];
                   accessToken= session.accessTokenData.accessToken;
                }
                if(delegateHandler)
                {
                    if(accessToken || error)
                        delegateHandler(accessToken,status,error);
                }
               
            }];
    
}

-(BOOL)isLogin{
    OEXConfig *config=[OEXConfig sharedConfig];
    OEXFacebookConfig *facebookConfig=[config facebookConfig];
    if(facebookConfig.appId){
    return [[FBSession activeSession] isOpen];
    }
    return NO;
}

-(void)clearHandler{

    [self logout];
    delegateHandler=nil;
    
}

-(void)logout
{
    if([self isLogin])
    {
        [[FBSession activeSession] closeAndClearTokenInformation];
    }
}


@end
