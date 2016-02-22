//
//  NSArray+OEXFunctional.h
//  edXVideoLocker
//
//  Created by Akiva Leffert on 1/16/15.
//  Copyright (c) 2015-2016 edX. All rights reserved.
//

NS_ASSUME_NONNULL_BEGIN

@interface NSArray (OEXFunctional)

+ (NSArray*)oex_arrayWithCount:(NSUInteger)count generator:(id(^)(NSUInteger index))generator;

- (NSArray*)oex_map:(id (^)(id object))mapper;

- (NSArray*)oex_arrayByRemovingObject:(id)object;

@end

NS_ASSUME_NONNULL_END
