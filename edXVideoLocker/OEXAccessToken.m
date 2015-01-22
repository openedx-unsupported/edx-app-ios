//
//  OEXAccessToken.m
//  edXVideoLocker
//
//  Created by Abhishek Bhagat on 19/01/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

#import "OEXAccessToken.h"
#import "NSMutableDictionary+OEXSafeAccess.h"

static NSString *const OEXAccessTokenKey=@"access_token";
static NSString *const OEXTokenTypeKey=@"token_type";
static NSString *const OEXExpiryDateKey=@"expires_in";
static NSString *const OEXScopeKey=@"scope";

@implementation OEXAccessToken

-(OEXAccessToken *)initWithTokenDetails:(NSDictionary *)dict{
    
    self=[super init];
    if(self){
        _accessToken=[dict objectForKey:OEXAccessTokenKey];
        _tokenType=[dict objectForKey:OEXTokenTypeKey];
        _expiryDate=[dict objectForKey:OEXExpiryDateKey];
        _scope=[dict objectForKey:OEXScopeKey];
        
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
        [dict setObjectOrNil:_accessToken forKey:OEXAccessTokenKey];
        [dict setObjectOrNil:_tokenType forKey:OEXTokenTypeKey];
        [dict setObjectOrNil:_expiryDate forKey:OEXExpiryDateKey];
        [dict setObjectOrNil:_scope forKey:OEXScopeKey];
        
    }else{
        return nil;
    }
    
    NSString *error;
    NSData *data=[NSPropertyListSerialization dataFromPropertyList:dict format:NSPropertyListXMLFormat_v1_0 errorDescription:&error];
    if(error){
        ELog(@"OEXAccessToken Error ==>> %@ " , error);
        return nil;
    }
    return data;
    
}

-(NSDictionary *)accessTokenDict{
    
    NSMutableDictionary *dict=[NSMutableDictionary dictionary];
    if(_accessToken)
    {
        [dict setObjectOrNil:_accessToken forKey:OEXAccessTokenKey];
        [dict setObjectOrNil:_tokenType forKey:OEXTokenTypeKey];
        [dict setObjectOrNil:_expiryDate forKey:OEXExpiryDateKey];
        [dict setObjectOrNil:_scope forKey:OEXScopeKey];
        
        return [dict copy];
    }else{
        return nil;
    }
}

//Abhra
+(OEXAccessToken *)accessTokenWithData:(NSData *)accessTokenData{
    if (!accessTokenData) {
        return nil;
    }
    NSDictionary *accessTokenDictionary = [NSPropertyListSerialization propertyListWithData:accessTokenData options:0 format:NULL error:NULL];
    if (!accessTokenDictionary) {
        return nil;
    }
    NSLog(@"acc: %@",accessTokenDictionary);
    OEXAccessToken *token = [[OEXAccessToken alloc] init];
    token.accessToken = accessTokenDictionary[OEXAccessTokenKey];
    token.tokenType = accessTokenDictionary[OEXTokenTypeKey];
    token.expiryDate = accessTokenDictionary[OEXExpiryDateKey];
    token.scope = accessTokenDictionary[OEXScopeKey];
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
