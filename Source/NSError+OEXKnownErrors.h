//
//  NSError+OEXKnownErrors.h
//  edXVideoLocker
//
//  Created by Akiva Leffert on 3/19/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class OEXCoursewareAccess;
@class OEXCourseStartDisplayInfo;
@class OEXTextStyle;

extern NSString* const OEXErrorDomain;

typedef NS_ENUM(NSUInteger, OEXErrorCode) {
    OEXErrorCodeUnknown = -100,
    OEXErrorCodeCouldNotLoadCourseContent = -101,
    OEXErrorCodeInvalidURL = -102,
    OEXErrorCodeCoursewareAccess = -103,
    OEXErrorCodeHandoutsEmpty = -104
};

@interface NSError (OEXKnownErrors)

+ (instancetype)oex_unknownError;
+ (instancetype)oex_courseContentLoadError;
+ (instancetype)oex_invalidURLError;
+ (instancetype)oex_errorWithCode:(OEXErrorCode)code message:(NSString*)message;

@end

@protocol OEXAttributedErrorMessageCarrying <NSObject>

- (NSAttributedString*)attributedDescriptionWithBaseStyle:(OEXTextStyle*)style;

@end

@interface OEXCoursewareAccessError : NSError <OEXAttributedErrorMessageCarrying>

- (id)initWithCoursewareAccess:(OEXCoursewareAccess*)access displayInfo:(nullable OEXCourseStartDisplayInfo*)info;

@property (readonly, nonatomic) OEXCoursewareAccessError* error;

@end

NS_ASSUME_NONNULL_END
