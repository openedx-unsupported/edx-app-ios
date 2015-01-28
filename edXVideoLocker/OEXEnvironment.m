//
//  OEXEnvironment.m
//  edXVideoLocker
//
//  Created by Akiva Leffert on 12/29/14.
//  Copyright (c) 2014 edX. All rights reserved.
//

#import "OEXEnvironment.h"

#import "OEXConfig.h"

@interface OEXEnvironment ()

@property(strong, nonatomic) OEXConfig* config;

@end

@implementation OEXEnvironment

+ (instancetype)shared {
    static dispatch_once_t onceToken;
    static OEXEnvironment* shared = nil;
    dispatch_once(&onceToken, ^{
        shared = [[OEXEnvironment alloc] init];
    });
    return shared;
}

- (id)init {
    self = [super init];
    if(self != nil) {
        self.config = [[OEXConfig alloc] initWithAppBundleData];
    }
    return self;
}

@end
