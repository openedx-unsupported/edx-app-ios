//
//  OEXFacebookConfig.m
//  edXVideoLocker
//
//  Created by Jotiram Bhagat on 22/02/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

#import "OEXFacebookConfig.h"

@implementation OEXFacebookConfig

-(instancetype)initWithDictionary:(NSDictionary *)dictionary{
    self=[super init];
    if(self){
        _enabled=[dictionary[@"ENABLED"] boolValue];
        _appId=dictionary[@"FACEBOOK_APP_ID"];
    }
    return self;
}
@end
