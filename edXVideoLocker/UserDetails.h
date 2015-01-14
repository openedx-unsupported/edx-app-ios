//
//  UserDetails.h
//  edXVideoLocker
//
//  Created by Rahul Varma on 05/06/14.
//  Copyright (c) 2014 edX. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface UserDetails : NSObject

@property (nonatomic , assign) long User_id;
@property (nonatomic , strong) NSString *username;
@property (nonatomic , strong) NSString *email;
@property (nonatomic , strong) NSString *name;
@property (nonatomic , strong) NSString *course_enrollments;
@property (nonatomic , strong) NSString *url;

+(UserDetails *)currentUser;
@end
