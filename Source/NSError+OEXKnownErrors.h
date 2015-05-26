//
//  NSError+OEXKnownErrors.h
//  edXVideoLocker
//
//  Created by Akiva Leffert on 3/19/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString* const OEXErrorDomain;

typedef NS_ENUM(NSUInteger, OEXErrorCode) {
    OEXErrorCodeUnknown = -100,
    OEXErrorCodeCouldNotLoadCourseContent = -101,
    OEXErrorCodeInvalidURL = -102,
};

@interface NSError (OEXKnownErrors)

+ (instancetype)oex_unknownError;
+ (instancetype)oex_courseContentLoadError;
+ (instancetype)oex_invalidURLError;

- (BOOL)oex_isNoInternetConnectionError;

@end
