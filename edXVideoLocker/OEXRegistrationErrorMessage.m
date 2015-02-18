//
//  OEXRegistrationMessage.m
//  edXVideoLocker
//
//  Created by Jotiram Bhagat on 13/02/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

#import "OEXRegistrationErrorMessage.h"

@interface OEXRegistrationErrorMessage ()



@end

@implementation OEXRegistrationErrorMessage

-(instancetype)initWithDictionary:(NSDictionary *)dictionary{
    self=[super init];
    if(self){
        _maxLenght=dictionary[@"max_lenght"];
        _minLenght=dictionary[@"min_lenght"];
        _required=dictionary[@"required"];
    }
    return self;
}


@end
