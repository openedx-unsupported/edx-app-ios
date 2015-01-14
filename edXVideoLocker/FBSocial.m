//
//  FBSocial.m
//  edXVideoLocker
//
//  Created by Prashant Kurhade on 20/11/14.
//  Copyright (c) 2014 edX. All rights reserved.
//

#import "FBSocial.h"

@interface FBSocial (){
    
     LoginCompletionHandler delegateHandler;
    
}

@end

@implementation FBSocial

+ (id)sharedInstance{
    static FBSocial *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

-(void)login:(LoginCompletionHandler)completionHandler
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
    if([[FBSession activeSession] isOpen]){
        
        return YES;
        
    }else{
        return NO;
    }
}

-(void)clearHandler{

    [self logout];
    
    delegateHandler=nil;
    
}

-(void)logout
{
    if([[FBSession activeSession] isOpen])
    {
        [[FBSession activeSession] closeAndClearTokenInformation];
    }
}


@end
