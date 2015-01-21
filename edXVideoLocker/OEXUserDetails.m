//
//  OEXUserDetails.m
//  edXVideoLocker
//
//  Created by Rahul Varma on 05/06/14.
//  Copyright (c) 2014 edX. All rights reserved.
//

#import "OEXUserDetails.h"
#import "OEXSession.h"
static OEXUserDetails *user=nil;
@implementation OEXUserDetails
+(OEXUserDetails *)currentUser{
    OEXSession *session=[OEXSession getActiveSessoin];
    if(session){
        if([session.username isEqualToString:user.username]){
            return user;
        }else{
            user=[[OEXUserDetails alloc] init];
            user.name=session.name;
            user.username=session.username;
            user.email=session.email;
            user.User_id=session.userId;
            user.course_enrollments=session.course_enrollments;
            user.url=session.url;
            return user;
        }
    }
    return nil;
}


@end
