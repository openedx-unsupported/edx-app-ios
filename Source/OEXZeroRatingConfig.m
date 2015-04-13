//
//  OEXZeroRatingConfig.m
//  edXVideoLocker
//
//  Created by Jotiram Bhagat on 23/02/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

#import "OEXZeroRatingConfig.h"

@interface OEXZeroRatingConfig ()
@property(nonatomic, strong) NSArray* carriers;
@end

@implementation OEXZeroRatingConfig

- (instancetype)initWithDictionary:(NSDictionary*)dictionary {
    self = [super init];
    if(self) {
        _enabled = [dictionary[@"ENABLED"] boolValue];
        _carriers = dictionary[@"CARRIERS"];
    }
    return self;
}

@end
