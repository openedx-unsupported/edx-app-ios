//
//  NSArray+OEXFunctional.m
//  edXVideoLocker
//
//  Created by Akiva Leffert on 1/16/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

#import "NSArray+OEXFunctional.h"

@implementation NSArray (OEXFunctional)

- (id)oex_map:(id (^)(id object))mapper {
    NSMutableArray* result = [[NSMutableArray alloc] init];
    for(id object in self) {
        id o = mapper(object);
        if(o) {
            [result addObject:o];
        }
    }
    return result;
}

@end
