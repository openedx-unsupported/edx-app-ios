//
//  OEXUserDetails+OEXTestDataFactory.m
//  edXVideoLocker
//
//  Created by Akiva Leffert on 4/10/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

#import "OEXUserDetails+OEXTestDataFactory.h"

@implementation OEXUserDetails (OEXTestDataFactory)

+ (instancetype)freshUser {
    OEXUserDetails* userDetails = [[OEXUserDetails alloc] init];
    userDetails.username = [NSUUID UUID].UUIDString;
    userDetails.email = @"test@email.com";
    // TODO: add more properties as they become useful for testing
    return userDetails;
}

@end
