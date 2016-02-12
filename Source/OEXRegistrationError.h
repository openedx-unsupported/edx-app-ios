//
//  OEXRegistrationError.h
//  edXVideoLocker
//
//  Created by Jotiram Bhagat on 13/02/15.
//  Copyright (c) 2015-2016 edX. All rights reserved.
//

NS_ASSUME_NONNULL_BEGIN

@interface OEXRegistrationError : NSObject
@property(nonatomic, copy) NSNumber* isRequired;
@property(nonatomic, copy) NSString* errMessage;
@end

NS_ASSUME_NONNULL_END
