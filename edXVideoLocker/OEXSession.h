//
//  OEXSession.h
//  edXVideoLocker
//
//  Created by Abhishek Bhagat on 19/01/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OEXAcessToken.h"

@interface OEXSession : NSObject
@property(readonly,strong)OEXAcessToken *edxToken;
@property(readonly,strong)NSString *email;
@property(readonly,strong)NSString *username;
@property(readonly,strong)NSString *course_enrollments;
@property(readonly,strong)NSNumber *userId;
@property(readonly,strong)NSString *url;
@property(readonly,strong)NSString *name;
+(OEXSession *)getActiveSessoin;

+(OEXSession *)createSessionWithAccessToken:(OEXAcessToken *)accessToken andUserDetails:(NSDictionary *)userDetails;

+(void)closeAndClearSession;
@end
