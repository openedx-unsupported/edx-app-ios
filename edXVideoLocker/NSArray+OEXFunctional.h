//
//  NSArray+OEXFunctional.h
//  edXVideoLocker
//
//  Created by Akiva Leffert on 1/16/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSArray (OEXFunctional)

- (NSArray*)oex_map:(id (^)(id object))mapper;

+ (NSArray*)oex_arrayWithCount:(NSUInteger)count generator:(id(^)(NSUInteger index))generator;

@end
