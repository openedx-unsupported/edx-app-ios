//
//  OEXAcessToken.m
//  edXVideoLocker
//
//  Created by Abhishek Bhagat on 19/01/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

#import "OEXAcessToken.h"
#import "NSMutableDictionary+OEXSafeAccess.h"
NSString *const kAccessToken=@"access_token";
NSString *const kTokenType=@"token_type";
NSString *const kExpiryDate=@"expires_in";
NSString *const kScope=@"scope";

@implementation OEXAcessToken

-(OEXAcessToken *)initWithTokenDetails:(NSDictionary *)dict{
    
    self=[super init];
    if(self){
        _accessToken=[dict objectForKey:kAccessToken];
        _tokenType=[dict objectForKey:kTokenType];
        _expiryDate=[dict objectForKey:kExpiryDate];
        _scope=[dict objectForKey:kScope];
        
        if(!_accessToken){
            self=nil;
        }
    }
    
    return self;
    
    
}

-(NSData *)accessTokenData{
    
    NSMutableDictionary *dict=[NSMutableDictionary dictionary];
    if(_accessToken)
    {
        [dict setObjectOrNil:_accessToken forKey:kAccessToken];
        [dict setObjectOrNil:_tokenType forKey:kTokenType];
        [dict setObjectOrNil:_expiryDate forKey:kExpiryDate];
        [dict setObjectOrNil:_scope forKey:kScope];
        
    }else{
        return nil;
    }
    
    NSString *error;
    NSData *data=[NSPropertyListSerialization dataFromPropertyList:dict format:NSPropertyListXMLFormat_v1_0 errorDescription:&error];
    if(error){
        ELog(@"OEXAcessToken Error ==>> %@ " , error);
        return nil;
    }
    return data;
    
}

-(NSDictionary *)accessTokenDict{
    
    NSMutableDictionary *dict=[NSMutableDictionary dictionary];
    if(_accessToken)
    {
        [dict setObjectOrNil:_accessToken forKey:kAccessToken];
        [dict setObjectOrNil:_tokenType forKey:kTokenType];
        [dict setObjectOrNil:_expiryDate forKey:kExpiryDate];
        [dict setObjectOrNil:_scope forKey:kScope];
        
        return [dict copy];
    }else{
        return nil;
    }
}

//Abhra
+(OEXAcessToken *)accessTokenWithData:(NSData *)accessTokenData{
    if (!accessTokenData) {
        return nil;
    }
    NSDictionary *accessTokenDictionary = [NSPropertyListSerialization propertyListWithData:accessTokenData options:0 format:NULL error:NULL];
    if (!accessTokenDictionary) {
        return nil;
    }
    NSLog(@"acc: %@",accessTokenDictionary);
    OEXAcessToken *token = [[OEXAcessToken alloc] init];
    token.accessToken = accessTokenDictionary[kAccessToken];
    token.tokenType = accessTokenDictionary[kTokenType];
    token.expiryDate = accessTokenDictionary[kExpiryDate];
    token.scope = accessTokenDictionary[kScope];
    return token;
}

/*
 /Auth token Response/
 {
 "access_token" = a11f14d027da2eecc63e897c143fb8dfb9ecfa19;
 "expires_in" = 2591999;
 scope = "";
 "token_type" = Bearer;
 }
 */

@end
