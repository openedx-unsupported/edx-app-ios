//
//  OEXAccessToken.m
//  edXVideoLocker
//
//  Created by Abhishek Bhagat on 19/01/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

#import "OEXAccessToken.h"
#import "edX-Swift.h"

static NSString* const OEXAccessTokenKey = @"access_token";
static NSString* const OEXTokenTypeKey = @"token_type";
static NSString* const OEXExpiryDateKey = @"expires_in";
static NSString* const OEXScopeKey = @"scope";
static NSString* const OEXRefreshTokenKey = @"refresh_token";

@implementation OEXAccessToken

- (id)copyWithZone:(NSZone*)zone {
    id copy = [[OEXAccessToken alloc] initWithAccessToken:self.accessToken
                                                tokenType:self.tokenType
                                               expiryDate:self.expiryDate
                                               tokenScope:self.scope
                                             refreshToken:self.refreshToken]
    ;
    return copy;
}

- (id)initWithAccessToken:(NSString*)accessToken
                tokenType:(NSString*)tokenType
               expiryDate:(NSDate*)expiryDate
               tokenScope:(NSString*)scope
             refreshToken:(NSString*)refreshToken {
    if((self = [super init])) {
        _accessToken = [accessToken copy];
        _tokenType = [tokenType copy];
        _expiryDate = [expiryDate copy];
        _scope = [scope copy];
        _refreshToken = [refreshToken copy];
    }

    return self;
}

- (OEXAccessToken*)initWithTokenDetails:(NSDictionary*)dict {
    self = [super init];
    if(self) {
        _accessToken = [dict objectForKey:OEXAccessTokenKey];
        _tokenType = [dict objectForKey:OEXTokenTypeKey];
        _expiryDate = [dict objectForKey:OEXExpiryDateKey];
        _scope = [dict objectForKey:OEXScopeKey];
        _refreshToken = [dict objectForKey:OEXRefreshTokenKey];
        if(!_accessToken) {
            self = nil;
        }
    }

    return self;
}

- (NSData*)accessTokenData {
    NSMutableDictionary* dict = [NSMutableDictionary dictionary];
    if(_accessToken) {
        [dict setSafeObject:_accessToken forKey:OEXAccessTokenKey];
        [dict setObjectOrNil:_tokenType forKey:OEXTokenTypeKey];
        [dict setObjectOrNil:_expiryDate forKey:OEXExpiryDateKey];
        [dict setObjectOrNil:_scope forKey:OEXScopeKey];
        [dict setObjectOrNil:_refreshToken forKey:OEXRefreshTokenKey];
    }
    else {
        return nil;
    }

    NSError* error = nil;
    NSData* data = [NSPropertyListSerialization dataWithPropertyList:dict format:NSPropertyListXMLFormat_v1_0 options:0 error:&error];
    if(error) {
        NSAssert(NO, @"AccessTokenData error => %@ ", [error description]);
        return nil;
    }
    return data;
}

+ (OEXAccessToken*)accessTokenWithData:(NSData*)accessTokenData {
    if(!accessTokenData || ![accessTokenData isKindOfClass:[NSData class]]) {
        return nil;
    }

    NSDictionary* accessTokenDictionary = [NSPropertyListSerialization propertyListWithData:accessTokenData options:0 format:NULL error:NULL];

    OEXAccessToken* token = [[OEXAccessToken alloc] init];

    NSString* dictionaryAccessToken = accessTokenDictionary[OEXAccessTokenKey];
    if(dictionaryAccessToken == nil || [dictionaryAccessToken stringByTrimmingCharactersInSet:
                                        [NSCharacterSet whitespaceCharacterSet]].length == 0) {
        return nil;
    }
    token.accessToken = dictionaryAccessToken;
    token.tokenType = accessTokenDictionary[OEXTokenTypeKey];
    token.expiryDate = accessTokenDictionary[OEXExpiryDateKey];
    token.scope = accessTokenDictionary[OEXScopeKey];
    token.refreshToken = accessTokenDictionary[OEXRefreshTokenKey];
    return token;
}

- (BOOL)isDeprecatedSessionToken {
    return self.tokenType.length == 0;
}

@end
