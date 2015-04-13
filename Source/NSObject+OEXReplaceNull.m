//
//  NSObject+OEXReplaceNull.m
//  edXVideoLocker
//
//  Created by Jotiram Bhagat on 04/07/14.
//  Copyright (c) 2014 edX. All rights reserved.
//

#import "NSObject+OEXReplaceNull.h"

const static NSString* OEXEmptyString = @"";

@implementation NSObject (OEXReplaceNull)

- (instancetype)oex_replaceNullsWithEmptyStrings {
    return self;
}

@end

@implementation NSArray (OEXReplaceNull)

- (instancetype)oex_replaceNullsWithEmptyStrings {
    NSMutableArray* result = [[NSMutableArray alloc] initWithCapacity:self.count];
    for(id object in self) {
        if([object isKindOfClass:[NSNull class]]) {
            [result addObject:OEXEmptyString];
        }
        else {
            [result addObject:[object oex_replaceNullsWithEmptyStrings]];
        }
    }
    return result;
}

@end

@implementation NSDictionary (OEXReplaceNull)
- (NSDictionary*)oex_replaceNullsWithEmptyStrings {
    NSMutableDictionary* result = [[NSMutableDictionary alloc] initWithCapacity:self.count];

    [self enumerateKeysAndObjectsUsingBlock:^(id key, id object, BOOL* stop) {
        if([object isKindOfClass:[NSNull class]]) {
            result[key] = OEXEmptyString;
        }
        else {
            result[key] = [object oex_replaceNullsWithEmptyStrings];
        }
    }];

    return result;
}

@end
