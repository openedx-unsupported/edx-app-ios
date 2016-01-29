//
//  NSString+OEXValidation.h
//  edXVideoLocker
//
//  Created by Akiva Leffert on 1/26/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

NS_ASSUME_NONNULL_BEGIN

@interface NSString (OEXValidation)

/// Tests, roughly speaking, if something is a valid email address.
/// Some things that are not email addresses will get through,
/// but the actual valid email regex from the RFC is a nightmare
- (BOOL)oex_isValidEmailAddress;

@end

NS_ASSUME_NONNULL_END
