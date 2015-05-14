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
    OEXErrorCodeCouldNotLoadCourseContent = -100
};

@interface NSError (OEXKnownErrors)

+ (instancetype)oex_courseContentLoadError;

- (BOOL)oex_isNoInternetConnectionError;

@end
