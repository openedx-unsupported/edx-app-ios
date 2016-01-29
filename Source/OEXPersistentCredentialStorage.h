//
//  OEXPersistentCredentialStorage.h
//  edXVideoLocker
//
//  Created by Abhradeep on 20/01/15.
//  Copyright (c) 2015-2016 edX. All rights reserved.
//

NS_ASSUME_NONNULL_BEGIN

@class OEXAccessToken, OEXUserDetails;

@protocol OEXCredentialStorage <NSObject>

@property (nonatomic, strong, readonly, nullable) OEXAccessToken* storedAccessToken;
@property (nonatomic, strong, readonly, nullable) OEXUserDetails* storedUserDetails;

- (void)saveAccessToken:(OEXAccessToken*)accessToken userDetails:(OEXUserDetails*)userDetails;
- (void)clear;

@end

@interface OEXPersistentCredentialStorage : NSObject <OEXCredentialStorage>

@end

NS_ASSUME_NONNULL_END
