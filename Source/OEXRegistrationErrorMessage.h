//
//  OEXRegistrationMessage.h
//  edXVideoLocker
//
//  Created by Jotiram Bhagat on 13/02/15.
//  Copyright (c) 2015-2016 edX. All rights reserved.
//

NS_ASSUME_NONNULL_BEGIN

@interface OEXRegistrationErrorMessage : NSObject
@property(nonatomic, copy, readonly) NSString* required;
@property(nonatomic, copy, readonly) NSString* maxLength;
@property(nonatomic, copy, readonly) NSString* minLength;

- (instancetype)initWithDictionary:(NSDictionary*)dictionary;

@end

NS_ASSUME_NONNULL_END
