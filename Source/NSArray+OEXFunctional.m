//
//  NSArray+OEXFunctional.m
//  edXVideoLocker
//
//  Created by Akiva Leffert on 1/16/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

#import "NSArray+OEXFunctional.h"

@implementation NSArray (OEXFunctional)

- (NSArray*)oex_map:(id (^)(id object))mapper {
    NSMutableArray* result = [[NSMutableArray alloc] init];
    for(id object in self) {
        id o = mapper(object);
        if(o) {
            [result addObject:o];
        }
    }
    return result;
}

+ (NSArray*)oex_arrayWithCount:(NSUInteger)count generator:(id(^)(NSUInteger index))generator {
    NSMutableArray* result = [[NSMutableArray alloc] initWithCapacity:count];
    for(NSUInteger i = 0; i < count; i++) {
        id object = generator(i);
        if(object) {
            [result addObject:object];
        }
    }
    return result;
}

- (NSArray*)oex_arrayByRemovingObject:(id)object {
    NSMutableArray* result = [self mutableCopy];
    [result removeObject:object];
    return result;
}

@end
