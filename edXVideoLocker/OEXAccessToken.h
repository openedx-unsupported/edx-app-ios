//
//  OEXAccessToken.h
//  edXVideoLocker
//
//  Created by Abhishek Bhagat on 19/01/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface OEXAccessToken : NSObject <NSCopying>
@property(nonatomic,copy)NSString *accessToken;
@property(nonatomic,copy)NSDate *expiryDate;
@property(nonatomic,copy)NSString *tokenType;
@property(nonatomic,copy)NSString *scope;

-(NSData *)accessTokenData;

-(OEXAccessToken *)initWithTokenDetails:(NSDictionary *)dict;

-(NSDictionary *)accessTokenDict;

+(OEXAccessToken *)accessTokenWithData:(NSData *)accessTokenData;

@end

