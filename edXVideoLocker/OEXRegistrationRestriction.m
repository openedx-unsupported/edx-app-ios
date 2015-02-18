//
//  OEXRegistrationRestriction.m
//  edXVideoLocker
//
//  Created by Jotiram Bhagat on 13/02/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

#import "OEXRegistrationRestriction.h"

@interface OEXRegistrationRestriction ()
@property(nonatomic,assign)NSNumber *min_length;
@property(nonatomic,assign)NSNumber *max_length;
@end

@implementation OEXRegistrationRestriction

-(instancetype)initWithDictionary:(NSDictionary *)dictionary{
    self=[super init];
    if(self){
        _max_length=dictionary[@"max_length"];
        _min_length=dictionary[@"min_length"];
    }
    return self;
}

-(NSInteger)maxLentgh{
    if(!self.min_length)
        return 0;
    return [self.max_length integerValue];
}

-(NSInteger)minLength{
    if(!self.max_length)
        return 0;
    return [self.min_length integerValue];
}

@end
