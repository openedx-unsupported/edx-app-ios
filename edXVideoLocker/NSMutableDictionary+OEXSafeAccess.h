//
//  NSMutableDictionary+OEXSafeAccess.h
//  edXVideoLocker
//
//  Created by Akiva Leffert on 12/8/14.
//  Copyright (c) 2014 edX. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSMutableDictionary (OEXSafeAccess)

/// Variant of setObject:forKey: that doesn't crash if the object is nil.
/// Instead, it will just do nothing.
/// This is for cases where you may or may not have an object.
/// Contrast with -[NSMutableDictionary safeSetObject:forKey:]
- (void)setObjectOrNil:(id )object forKey:(id<NSCopying>)key;

/// Variant of setObject:forKey: that doesn't crash if the object is nil.
/// Instead, it will assert on DEBUG builds and console log on RELEASE builds
/// This is for cases where you're expecting to have an object
/// but you don't want to crash if for some reason you don't.
/// Contrast with -[NSMutableDictionary setObjectOrNil:forKey:]
- (void)safeSetObject:(id)object forKey:(id<NSCopying>)key;

@end
