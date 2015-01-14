//
//  EDXEnvironment.m
//  edXVideoLocker
//
//  Created by Akiva Leffert on 12/29/14.
//  Copyright (c) 2014 edX. All rights reserved.
//

#import "EDXEnvironment.h"

#import "EDXConfig.h"

@interface EDXEnvironment ()

@property(strong, nonatomic) EDXConfig* config;

@end

@implementation EDXEnvironment

+ (instancetype)shared {
    static dispatch_once_t onceToken;
    static EDXEnvironment* shared = nil;
    dispatch_once(&onceToken, ^{
        shared = [[EDXEnvironment alloc] init];
    });
    return shared;
}

- (id)init {
    self = [super init];
    if(self != nil) {
        self.config = [[EDXConfig alloc] initWithAppBundleData];
    }
    return self;
}

@end
