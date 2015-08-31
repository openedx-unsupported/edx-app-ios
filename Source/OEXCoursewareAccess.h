//
//  OEXCoursewareAccess.h
//  edX
//
//  Created by Linda Liu on 7/9/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface OEXCoursewareAccess : NSObject

- (id)initWithDictionary:(nullable NSDictionary*)info;


typedef NS_ENUM(NSInteger, OEXAccessError) {
    OEXStartDateError,
    OEXVisibilityError,
    OEXMilestoneError,
    OEXUnknownError
};

@property (readonly, nonatomic, assign) BOOL has_access;
@property (readonly, nonatomic, assign) OEXAccessError error_code;
@property (readonly, nonatomic, copy, nullable) NSString* developer_message;
@property (readonly, nonatomic, copy, nullable) NSString* user_message;

@end

NS_ASSUME_NONNULL_END