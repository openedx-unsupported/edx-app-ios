//
//  NSArray+OEXSafeAccess.h
//  edXVideoLocker
//
//  Created by Akiva Leffert on 1/15/15.
//  Copyright (c) 2015-2016 edX. All rights reserved.
//

NS_ASSUME_NONNULL_BEGIN

@interface NSArray (OEXSafeGetAccess)

/// Like objectAtIndex: but return nil instead of crashing if the index is out of bounds
/// Will still assert if the index is out of bounds in DEBUG builds. See oex_objectOrNilAtIndex:
/// if you want to ignore the nil case entirely.
- (id _Nullable)oex_safeObjectAtIndex:(NSUInteger)index;

/// Like objectAtIndex: but return nil instead of crashing if the index is out of bounds
/// See oex_objectOrNilAtIndex: if you want fail fast behavior for fetching out of bounds
- (id _Nullable)oex_safeObjectOrNilAtIndex:(NSUInteger)index;

@end

@interface NSMutableArray (OEXSafeSetAccess)

/// Like addObject: but won't crash if object is nil. Will still assert on DEBUG builds
/// See oex_addObjectOrNil: if you want to ignore the nil case entirely
- (void)oex_safeAddObject:(id)object;

/// Like addObject: but won't crash if object is nil. See oex_safeAddObject: if you want fail fast
/// behavior for setting nil
- (void)oex_safeAddObjectOrNil:(id)object;

@end

NS_ASSUME_NONNULL_END
