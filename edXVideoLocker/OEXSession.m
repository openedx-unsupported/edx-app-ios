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


static NSString *const OEXEmailKey=@"email";
static NSString *const OEXUserNameKey=@"username";
static NSString *const OEXCourseEnrollmentsKey=@"course_enrollments";
static NSString *const OEXNameKey=@"name";
static NSString *const OEXUserIdKey=@"id";


@implementation OEXSession


+(OEXSession *)activeSession{
    if(!activeSession){
        activeSession=[[OEXSession alloc] init];
        return activeSession;
    }
    return activeSession;
}

+(OEXSession *)createSessionWithAccessToken:(OEXAccessToken *)token andUserDetails:(NSDictionary *)userDetails{
    if(activeSession){
        [[OEXSession activeSession]closeAndClearSession];
    }
    activeSession=[[OEXSession alloc] initWithAccessToken:token
                                            andDictionary:userDetails];
    return activeSession;
}

-(void)closeAndClearSession{
    
    [[OEXKeychainAccess sharedKeychainAccess] endSession];
     activeSession=nil;
}

-(id)init{
    return [self initWithAccessToken:nil andDictionary:nil];
}

-(id)initWithAccessToken:(OEXAccessToken *)edxToken andDictionary:(NSDictionary *)userDict{
    
    self=[super init];
    if(self){
       
        if(edxToken.accessToken && userDict){
            NSData *tokenData=[edxToken accessTokenData];
            if(!tokenData || ![userDict objectForKey:OEXUserNameKey]){
                self=nil;
                return nil;
            }
           [[OEXKeychainAccess sharedKeychainAccess] startSessionWithAccessToken:edxToken userDetails:userDict];
        }
        
        [self initialize];
    }
    if(!self.edxToken.accessToken || [self.edxToken.accessToken isEqualToString:@""]){
        self=nil;
    }
    
    return self;
    
}

-(void)initialize{
    
    OEXAccessToken *tokenData=[[OEXKeychainAccess sharedKeychainAccess] storedAccessToken];
    NSDictionary  *dict=[[OEXKeychainAccess sharedKeychainAccess] storedUserDetails];
    
    if(tokenData && dict){
                
        _edxToken = tokenData;
        _email=[dict objectForKey:OEXEmailKey];
        _username=[dict objectForKey:OEXUserNameKey];
        _course_enrollments=[dict objectForKey:OEXCourseEnrollmentsKey];
        _userId=[dict objectForKey:OEXUserIdKey];
        _name=[dict objectForKey:OEXNameKey];
        
    }
    
}

@end
