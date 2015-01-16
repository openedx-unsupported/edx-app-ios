//
//  OEXUserDetails.m
//  edXVideoLocker
//
//  Created by Rahul Varma on 05/06/14.
//  Copyright (c) 2014 edX. All rights reserved.
//

#import "OEXUserDetails.h"

@implementation OEXUserDetails
+(OEXUserDetails *)currentUser{
    NSDictionary *userDict=[[NSUserDefaults standardUserDefaults] objectForKey:@"loginUserDetails"];
    if(userDict){
        
        OEXUserDetails *user=[[OEXUserDetails alloc] init];
        user.name=[userDict objectForKey:@"name"];
        user.username=[userDict objectForKey:@"username"];
        user.email=[userDict objectForKey:@"email"];
        user.User_id=[[userDict objectForKey:@"id"] longValue];
        user.course_enrollments=[userDict objectForKey:@"course_enrollments"];
        user.url=[userDict objectForKey:@"url"];
        
        return user;
    }
   
    return nil;
}


@end
