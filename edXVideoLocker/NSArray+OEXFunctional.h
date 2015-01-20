//
//  NSArray+OEXFunctional.h
//  edXVideoLocker
//
//  Created by Akiva Leffert on 1/16/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSArray (OEXFunctional)

- (id)oex_map:(id (^)(id object))mapper;

@end
