//
//  OEXExternalAuthProvider.h
//  edXVideoLocker
//
//  Created by Akiva Leffert on 3/24/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

#import <Foundation/Foundation.h>

@class OEXExternalAuthProviderButton;
@class OEXRegisteringUserDetails;

@protocol OEXExternalAuthProvider <NSObject>

/// Name used in the UI
@property (readonly, nonatomic) NSString* displayName;

/// Name used when communicating with the server
@property (readonly, nonatomic) NSString* backendName;

- (OEXExternalAuthProviderButton*)freshAuthButton;

- (void)authorizeServiceWithCompletion:(void(^)(NSString* accessToken, OEXRegisteringUserDetails* userProfile, NSError* error))completion;

@end