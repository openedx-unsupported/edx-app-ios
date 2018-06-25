//
//  OEXUserDetails.m
//  edXVideoLocker
//
//  Created by Rahul Varma on 05/06/14.
//  Copyright (c) 2014 edX. All rights reserved.
//

#import "OEXUserDetails.h"
#import "OEXSession.h"
#import "edX-Swift.h"

static OEXUserDetails* user = nil;

static NSString* const OEXUserDetailsEmailKey = @"email";
static NSString* const OEXUserDetailsUserNameKey = @"username";
static NSString* const OEXUserDetailsCourseEnrollmentsKey = @"course_enrollments";
static NSString* const OEXUserDetailsNameKey = @"name";
static NSString* const OEXUserDetailsUserIdKey = @"id";
static NSString* const OEXUserDetailsUrlKey = @"url";

@implementation OEXUserDetails

- (id)copyWithZone:(NSZone*)zone {
    id copy = [[OEXUserDetails alloc] initWithUserName:self.username email:self.email courseEnrollments:self.course_enrollments name:self.name userId:self.userId andUrl:self.url];
    ;
    return copy;
}

- (id)initWithUserName:(NSString*)username email:(NSString*)email courseEnrollments:(NSString*)course_enrollments name:(NSString*)name userId:(NSNumber*)userId andUrl:(NSString*)url {
    if((self = [super init])) {
        _username = [username copy];
        _email = [email copy];
        _course_enrollments = [course_enrollments copy];
        _name = [name copy];
        _userId = [userId copy];
        _url = [url copy];
    }
    return self;
}

- (id)initWithUserDictionary:(NSDictionary*)userDetailsDictionary {
    self = [super init];
    if(self) {
        NSString* dictionaryUserName = userDetailsDictionary[OEXUserDetailsUserNameKey];
        NSString* dictionaryCourseEnrollments = userDetailsDictionary[OEXUserDetailsCourseEnrollmentsKey];
        if(dictionaryUserName == nil || [dictionaryUserName stringByTrimmingCharactersInSet:
                                         [NSCharacterSet whitespaceCharacterSet]].length == 0) {
            return nil;
        }

        if(dictionaryCourseEnrollments == nil || [dictionaryCourseEnrollments stringByTrimmingCharactersInSet:
                                                  [NSCharacterSet whitespaceCharacterSet]].length == 0) {
            return nil;
        }

        _email = [userDetailsDictionary objectForKey:OEXUserDetailsEmailKey];
        _username = [userDetailsDictionary objectForKey:OEXUserDetailsUserNameKey];
        _course_enrollments = [userDetailsDictionary objectForKey:OEXUserDetailsCourseEnrollmentsKey];
        _userId = [userDetailsDictionary objectForKey:OEXUserDetailsUserIdKey];
        _name = [userDetailsDictionary objectForKey:OEXUserDetailsNameKey];
        _url = [userDetailsDictionary objectForKey:OEXUserDetailsUrlKey];
    }

    return self;
}

- (NSData*)userDetailsData {
    NSMutableDictionary* dict = [NSMutableDictionary dictionary];
    if(_username && _course_enrollments) {
        [dict setSafeObject:_username forKey:OEXUserDetailsUserNameKey];
        [dict setObjectOrNil:_email forKey:OEXUserDetailsEmailKey];
        [dict setSafeObject:_course_enrollments forKey:OEXUserDetailsCourseEnrollmentsKey];
        [dict setObjectOrNil:_userId forKey:OEXUserDetailsUserIdKey];
        [dict setObjectOrNil:_url forKey:OEXUserDetailsUrlKey];
        [dict setObjectOrNil:_name forKey:OEXUserDetailsNameKey];
    }
    else {
        return nil;
    }

    NSError* error = nil;
    NSData* data = [NSPropertyListSerialization dataWithPropertyList:dict format:NSPropertyListXMLFormat_v1_0 options:0 error:&error];
    NSAssert(error == nil, @"UserDetails error => %@ ", [error description]);
    return data;
}

- (id)initWithUserDetailsData:(NSData *)data {
    NSError* error = nil;
    NSDictionary* userDetailsDictionary = [NSPropertyListSerialization propertyListWithData:data options:0 format:NULL error:&error];
    NSAssert(error == nil, @"Error extracting user details: %@", error);
    
    return [self initWithUserDictionary:userDetailsDictionary];
}

@end
