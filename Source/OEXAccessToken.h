//
//  OEXAccessToken.h
//  edXVideoLocker
//
//  Created by Abhishek Bhagat on 19/01/15.
//  Copyright (c) 2015-2016 edX. All rights reserved.
//

NS_ASSUME_NONNULL_BEGIN

@interface OEXAccessToken : NSObject <NSCopying>

- (OEXAccessToken*)initWithTokenDetails:(NSDictionary*)dict;

/// data should have been previously created by the -accessTokenData method
+ (OEXAccessToken*)accessTokenWithData:(NSData*)accessTokenData;

@property(nonatomic, strong) NSDate* expiryDate;
@property(nonatomic, copy) NSString* accessToken;
@property(nonatomic, copy) NSString* tokenType;
@property(nonatomic, copy) NSString* scope;

/// Provides a persistent representation of an access token
- (NSData*)accessTokenData;

/// We used to use session tokens in some cases instead of oauth tokens
/// Check if our token is one of those deprecated tokens
@property (readonly, nonatomic) BOOL isDeprecatedSessionToken;


@end

NS_ASSUME_NONNULL_END
