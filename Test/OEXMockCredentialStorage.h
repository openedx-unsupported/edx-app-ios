//
//  OEXMockCredentialStorage.h
//  edXVideoLocker
//
//  Created by Akiva Leffert on 4/10/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "OEXAccessToken.h"
#import "OEXPersistentCredentialStorage.h"

NS_ASSUME_NONNULL_BEGIN

@interface OEXAccessToken (OEXTestFactory)

+ (instancetype)fakeToken;

@end

/// Pretend keychain that doesn't persist across runs
@interface OEXMockCredentialStorage : NSObject <OEXCredentialStorage>

/// @return a new instance with fake credentials
+ (instancetype)freshStorage;

@property (strong, nonatomic, nullable) OEXAccessToken* storedAccessToken;
@property (strong, nonatomic, nullable) OEXUserDetails* storedUserDetails;

@end

NS_ASSUME_NONNULL_END