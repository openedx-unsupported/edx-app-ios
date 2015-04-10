//
//  OEXMockKeychainAccess.m
//  edXVideoLocker
//
//  Created by Akiva Leffert on 4/10/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

#import "OEXMockKeychainAccess.h"


@implementation OEXMockKeychainAccess

- (void)saveAccessToken:(OEXAccessToken *)accessToken userDetails:(OEXUserDetails *)userDetails {
    self.storedAccessToken = accessToken;
    self.storedUserDetails = userDetails;
}

- (void)clear {
    self.storedAccessToken = nil;
    self.storedUserDetails = nil;
}

@end