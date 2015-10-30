//
//  OEXMockCredentialStorage.m
//  edXVideoLocker
//
//  Created by Akiva Leffert on 4/10/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

#import <DateTools/NSDate+DateTools.h>

#import "OEXMockCredentialStorage.h"

#import "OEXUserDetails+OEXTestDataFactory.h"

@implementation OEXAccessToken (OEXTestFactory)

+ (instancetype)fakeToken {
    OEXAccessToken* token = [[OEXAccessToken alloc] init];
    token.accessToken = [NSUUID UUID].UUIDString;
    token.expiryDate = [[NSDate date] dateByAddingDays:1];
    token.scope = @"sample scope";
    token.tokenType = @"sample type";
    return token;
}

@end


@implementation OEXMockCredentialStorage

+ (instancetype)freshStorage {
    OEXMockCredentialStorage* storage = [[self alloc] init];
    storage.storedUserDetails = [OEXUserDetails freshUser];
    storage.storedAccessToken = [OEXAccessToken fakeToken];
    return storage;
}

- (void)saveAccessToken:(OEXAccessToken *)accessToken userDetails:(OEXUserDetails *)userDetails {
    self.storedAccessToken = accessToken;
    self.storedUserDetails = userDetails;
}

- (void)clear {
    self.storedAccessToken = nil;
    self.storedUserDetails = nil;
}

@end