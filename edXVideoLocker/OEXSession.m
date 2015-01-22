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


static NSString *const kEmail=@"email";
static NSString *const kUserName=@"username";
static NSString *const kCourseEnrollments=@"course_enrollments";
static NSString *const kName=@"name";
static NSString *const kUserId=@"id";


@implementation OEXSession


+(OEXSession *)getActiveSessoin{
    if(!activeSession){
        activeSession=[[OEXSession alloc] init];
        return activeSession;
    }
    return activeSession;
}

+(OEXSession *)createSessionWithAccessToken:(OEXAccessToken *)token andUserDetails:(NSDictionary *)userDetails{
    if(activeSession){
        [OEXSession closeAndClearSession];
    }
    activeSession=[[OEXSession alloc] initWithAccessToken:token
                                            andDictionary:userDetails];
    return activeSession;
}

+(void)closeAndClearSession{
    
    [[OEXKeychainAccess sharedKeychainAccess] endSession];
     activeSession=nil;
    NSLog(@"DEL Token: %@",[[OEXKeychainAccess sharedKeychainAccess] storedAccessToken]);
    NSLog(@"DEL User Details: %@",[[OEXKeychainAccess sharedKeychainAccess] storedUserDetails]);
    
}

-(id)init{
    return [self initWithAccessToken:nil andDictionary:nil];
}

-(id)initWithAccessToken:(OEXAccessToken *)edxToken andDictionary:(NSDictionary *)userDict{
    
    self=[super init];
    if(self){
       
        if(edxToken.accessToken && userDict){
            NSData *tokenData=[edxToken accessTokenData];
            if(!tokenData || ![userDict objectForKey:kUserName]){
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
        _email=[dict objectForKey:kEmail];
        _username=[dict objectForKey:kUserName];
        _course_enrollments=[dict objectForKey:kCourseEnrollments];
        _userId=[dict objectForKey:kUserId];
        _name=[dict objectForKey:kName];
        
    }
    
}



//
//-(void)setUserDetails:

/*
 "course_enrollments" = "http://mobile.m.sandbox.edx.org/public_api/users/staff/course_enrollments/";
 email = "staff@example.com";
 id = 4;
 name = staff;
 url = "http://mobile.m.sandbox.edx.org/public_api/users/staff";
 username = staff;
 
 
 
 Printing description of dictionary:
 
 /Auth token Response/
 {
 "access_token" = a11f14d027da2eecc63e897c143fb8dfb9ecfa19;
 "expires_in" = 2591999;
 scope = "";
 "token_type" = Bearer;
 }
 
 
 /UserDetails Response/
 Printing description of dictionary:
 {
 "course_enrollments" = "https://courses.edx.org/api/mobile/v0.5/users/AbhishekBhagat/course_enrollments/";
 email = "abhibhagat123@gmail.com";
 id = 5801657;
 name = "Abhishek Bhagat";
 username = AbhishekBhagat;
 }
 */

@end
