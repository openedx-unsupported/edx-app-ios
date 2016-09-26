//
//  OEXUserDetails.h
//  edXVideoLocker
//
//  Created by Rahul Varma on 05/06/14.
//  Copyright (c) 2014-2016 edX. All rights reserved.
//

NS_ASSUME_NONNULL_BEGIN

@interface OEXUserDetails : NSObject <NSCopying>

- (id)initWithUserDictionary:(NSDictionary*)userDetails;

- (id)initWithUserDetailsData:(NSData*)data;
- (NSData* _Nullable)userDetailsData;

@property (nonatomic, copy, nullable) NSNumber* userId;
@property (nonatomic, copy, nullable) NSString* username;
@property (nonatomic, copy, nullable) NSString* email;
@property (nonatomic, copy, nullable) NSString* name;
@property (nonatomic, copy, nullable) NSString* course_enrollments;
@property (nonatomic, copy, nullable) NSString* url;

@end

NS_ASSUME_NONNULL_END
