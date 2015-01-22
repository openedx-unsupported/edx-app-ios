//
//  OEXAccessToken.h
//  edXVideoLocker
//
//  Created by Abhishek Bhagat on 19/01/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString *const kAccessToken;
extern NSString *const kTokenType;
extern NSString *const kExpiryDate;
extern NSString *const kScope;

@interface OEXAccessToken : NSObject
@property(nonatomic,strong)NSString *accessToken;
@property(nonatomic,strong)NSDate *expiryDate;
@property(nonatomic,strong)NSString *tokenType;
@property(nonatomic,strong)NSString *scope;

-(NSData *)accessTokenData;

-(OEXAccessToken *)initWithTokenDetails:(NSDictionary *)dict;

-(NSDictionary *)accessTokenDict;

+(OEXAccessToken *)accessTokenWithData:(NSData *)accessTokenData;

@end

