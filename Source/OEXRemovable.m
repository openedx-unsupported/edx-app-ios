//
//  OEXRemovable.m
//  edXVideoLocker
//
//  Created by Akiva Leffert on 3/30/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "OEXRemovable.h"

@interface OEXBlockRemovable ()

@property (copy, nonatomic) void (^action)(void);

@end

@implementation OEXBlockRemovable

- (id)initWithRemovalAction:(void (^)(void))action {
    self = [super init];
    if(self != nil) {
        self.action = action;
    }
    return self;
}

- (void)remove {
    if(self.action != nil) {
        self.action();
    }
    self.action = nil;
}

@end
