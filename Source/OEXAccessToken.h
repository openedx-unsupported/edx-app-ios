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
+ (OEXAccessToken* _Nullable)accessTokenWithData:(NSData*)accessTokenData;

@property(nonatomic, strong, nullable) NSDate* expiryDate;
@property(nonatomic, copy, nullable) NSString* accessToken;
@property(nonatomic, copy, nullable) NSString* tokenType;
@property(nonatomic, copy, nullable) NSString* scope;
@property(nonatomic, copy, nullable) NSString* refreshToken;

/// Provides a persistent representation of an access token
- (NSData* _Nullable)accessTokenData;

/// We used to use session tokens in some cases instead of oauth tokens
/// Check if our token is one of those deprecated tokens
@property (readonly, nonatomic) BOOL isDeprecatedSessionToken;


@end

NS_ASSUME_NONNULL_END
