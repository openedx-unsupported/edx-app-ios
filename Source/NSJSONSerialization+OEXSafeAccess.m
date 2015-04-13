//
//  NSJSONSerialization+OEXSafeAccess.m
//  edXVideoLocker
//
//  Created by Jotiram Bhagat on 12/03/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

#import "NSJSONSerialization+OEXSafeAccess.h"

@implementation NSJSONSerialization (OEXSafeAccess)
+ (id)oex_JSONObjectWithData:(NSData*)data error:(NSError* __autoreleasing*)error {
    if(data) {
        return [NSJSONSerialization JSONObjectWithData:data options:0 error:error];
    }
    else {
        NSAssert(NO, @"Expecting not nil object");
    }
    return nil;
}
@end
