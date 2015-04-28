//
//  OEXUserDetails.h
//  edXVideoLocker
//
//  Created by Rahul Varma on 05/06/14.
//  Copyright (c) 2014 edX. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface OEXUserDetails : NSObject <NSCopying>

- (id)initWithUserDictionary:(NSDictionary*)userDetails;

- (id)initWithUserDetailsData:(NSData*)data;
- (NSData*)userDetailsData;

@property (nonatomic, copy) NSNumber* userId;
@property (nonatomic, copy) NSString* username;
@property (nonatomic, copy) NSString* email;
@property (nonatomic, copy) NSString* name;
@property (nonatomic, copy) NSString* course_enrollments;
@property (nonatomic, copy) NSString* url;

@end
