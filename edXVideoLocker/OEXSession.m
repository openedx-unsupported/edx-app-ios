//
//  OEXSession.m
//  edXVideoLocker
//
//  Created by Abhishek Bhagat on 19/01/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

#import "OEXSession.h"
#import "OEXKeychainAccess.h"
static OEXSession *activeSession=nil;

NSString * const authTokenResponse=@"authTokenResponse";
NSString * const oauthTokenKey = @"oauth_token";
NSString * const authTokenType =@"token_type";
NSString * const loggedInUser  =@"loginUserDetails";


@interface OEXSession ()
@end



@implementation OEXSession


+(OEXSession *)activeSession{
    if(!activeSession){
        activeSession=[[OEXSession alloc] init];
        return activeSession;
    }
    return activeSession;
}

+(OEXSession *)createSessionWithAccessToken:(OEXAccessToken *)token andUserDetails:(OEXUserDetails *)userDetails{
    if(activeSession){
        [[OEXSession activeSession]closeAndClearSession];
    }
    activeSession=[[OEXSession alloc] initWithAccessToken:token
                                            andUser:userDetails];
    return activeSession;
}

-(void)closeAndClearSession{
    
    [[OEXKeychainAccess sharedKeychainAccess] endSession];
     activeSession=nil;
    
}

-(id)init{
    return [self initWithAccessToken:nil andUser:nil];
}

-(id)initWithAccessToken:(OEXAccessToken *)edxToken andUser:(OEXUserDetails *)userDetails{
    
    self=[super init];
    if(self){
        if(edxToken.accessToken && userDetails.username){
           [[OEXKeychainAccess sharedKeychainAccess] startSessionWithAccessToken:edxToken userDetails:userDetails];
        }
        [self initialize];
    }
    if((!self.edxToken.accessToken || [self.edxToken.accessToken isEqualToString:@""])&&
       (!self.currentUser.username || [self.currentUser.username isEqualToString:@""])){
        
        self=nil;
        
    }
    
    return self;
    
}

-(void)initialize{
    
    OEXAccessToken *tokenData=[[OEXKeychainAccess sharedKeychainAccess] storedAccessToken];
    OEXUserDetails  *userDetails=[[OEXKeychainAccess sharedKeychainAccess] storedUserDetails];
    
    if(tokenData && userDetails){
        _edxToken = tokenData;
        _currentUser=userDetails;
    }else{
        
        [[OEXKeychainAccess sharedKeychainAccess] endSession];

    }
    
}

+(void)migrateToKeychainIfNecessary{
    ///Remove Sensitive data from NSUserDefaults If Any
    
    NSUserDefaults *userDefaults=[NSUserDefaults standardUserDefaults];
    
    if([userDefaults objectForKey:loggedInUser] && [userDefaults objectForKey:authTokenResponse]){
    
        OEXUserDetails * userDetails=[[OEXUserDetails alloc] initWithUserDictionary:[userDefaults objectForKey:loggedInUser]];
        OEXAccessToken *edxToken=[[OEXAccessToken alloc] initWithTokenDetails:[userDefaults objectForKey:authTokenResponse]];
        [OEXSession createSessionWithAccessToken:edxToken andUserDetails:userDetails];
        
    }
    
    if([userDefaults objectForKey:loggedInUser]){
        [userDefaults removeObjectForKey:loggedInUser];
    }
    
    if([userDefaults objectForKey:authTokenResponse]){
        [userDefaults removeObjectForKey:authTokenResponse];
    }
    
    if([userDefaults objectForKey:oauthTokenKey]){
        [userDefaults removeObjectForKey:oauthTokenKey];
    }
   
    [userDefaults synchronize];
    
}

@end
