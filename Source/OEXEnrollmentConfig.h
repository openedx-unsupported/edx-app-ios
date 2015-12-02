//
//  OEXEnrollmentConfig.h
//  edXVideoLocker
//
//  Created by Abhradeep on 11/02/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface OEXEnrollmentConfig : NSObject

- (instancetype)initWithDictionary:(NSDictionary*)dictionary;

@property (nonatomic, assign, readonly) BOOL enabled;
@property (nullable, strong, nonatomic, readonly) NSURL* searchURL;
@property (nullable, copy, nonatomic, readonly) NSString* courseInfoURLTemplate;
@property (nullable, strong, nonatomic, readonly) NSURL* externalSearchURL;
@property (assign, nonatomic, readonly) BOOL useNativeCourseDiscovery;

@end


NS_ASSUME_NONNULL_END