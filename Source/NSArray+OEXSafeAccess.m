//
//  NSArray+OEXSafeAccess.m
//  edXVideoLocker
//
//  Created by Akiva Leffert on 1/15/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

#import "NSArray+OEXSafeAccess.h"

@implementation NSArray (OEXSafeAccess)

- (id)oex_safeObjectAtIndex:(NSUInteger)index {
    NSAssert(index < self.count, @"Index out of bounds");
    return [self oex_safeObjectOrNilAtIndex:index];
}

- (id)oex_safeObjectOrNilAtIndex:(NSUInteger)index {
    if(index < self.count) {
        return self[index];
    }
    return nil;
}

@end

@implementation NSMutableArray (OEXSafeSetAccess)

- (void)oex_safeAddObject:(id)object {
    NSAssert(object != nil, @"Attempting to add nil to an array");
    [self oex_safeAddObjectOrNil:object];
}

- (void)oex_safeAddObjectOrNil:(id)object {
    if(object != nil) {
        [self addObject:object];
    }
}

@end