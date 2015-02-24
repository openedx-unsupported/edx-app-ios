//
//  OEXGoogleConfig.m
//  edXVideoLocker
//
//  Created by Jotiram Bhagat on 22/02/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

#import "OEXGoogleConfig.h"

@implementation OEXGoogleConfig

-(instancetype)initWithDictionary:(NSDictionary *)dictionary{
    self=[super init];
    if(self){
        _enabled= [dictionary[@"ENABLED"] boolValue];
        _apiKey=dictionary[@"GOOGLE_PLUS_KEY"];
    }
    return self;
}

@end
