//
//  EDXEnvironment.h
//  edXVideoLocker
//
//  Created by Akiva Leffert on 12/29/14.
//  Copyright (c) 2014 edX. All rights reserved.
//

#import <Foundation/Foundation.h>

@class EDXConfig;

@interface EDXEnvironment : NSObject

+ (instancetype)shared;
// In the future, if, and only if, we need it for testing
// We could add a +setShared: method, and potentially +testEnvironment and +prodEnvironment methods
// To make appropriate environments

@property (readonly, strong, nonatomic) EDXConfig* config;

@end
