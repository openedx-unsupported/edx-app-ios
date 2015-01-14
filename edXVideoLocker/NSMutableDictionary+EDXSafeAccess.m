//
//  NSMutableDictionary+EDXSafeAccess.m
//  edXVideoLocker
//
//  Created by Akiva Leffert on 12/8/14.
//  Copyright (c) 2014 edX. All rights reserved.
//

#import "NSMutableDictionary+EDXSafeAccess.h"

@implementation NSMutableDictionary (EDXSafeAccess)

- (void)setObjectOrNil:(id)object forKey:(id<NSCopying>)key {
    if(object) {
        self[key] = object;
    }
}

- (void)safeSetObject:(id)object forKey:(id<NSCopying>)key {
    [self setObjectOrNil:object forKey:key];
    if(!object) {
#if DEBUG
        NSAssert(@"Expecting object for key:%@", key);
#else
        NSLog(@"Expecting object for key:%@", key);
#endif
    }
}

@end
