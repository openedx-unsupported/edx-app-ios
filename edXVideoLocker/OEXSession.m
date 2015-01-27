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

@end
