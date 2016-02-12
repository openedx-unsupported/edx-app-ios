//
//  OEXRegistrationRestriction.h
//  edXVideoLocker
//
//  Created by Jotiram Bhagat on 13/02/15.
//  Copyright (c) 2015-2016 edX. All rights reserved.
//

NS_ASSUME_NONNULL_BEGIN

@interface OEXRegistrationRestriction : NSObject
@property(nonatomic, assign) NSInteger maxLength;
@property(nonatomic, assign) NSInteger minLength;
- (instancetype)initWithDictionary:(NSDictionary*)dictionary;
@end

NS_ASSUME_NONNULL_END
