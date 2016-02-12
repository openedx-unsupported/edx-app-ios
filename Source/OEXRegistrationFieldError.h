//
//  OEXRegistrationFieldError.h
//  edXVideoLocker
//
//  Created by Akiva Leffert on 3/13/15.
//  Copyright (c) 2015-2016 edX. All rights reserved.
//

NS_ASSUME_NONNULL_BEGIN

@interface OEXRegistrationFieldError : NSObject

- (id)initWithDictionary:(NSDictionary*)info;

@property (copy, nonatomic, readonly) NSString* userMessage;

@end

NS_ASSUME_NONNULL_END
