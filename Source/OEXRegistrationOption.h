//
//  OEXRegistrationOption.h
//  edXVideoLocker
//
//  Created by Jotiram Bhagat on 13/02/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface OEXRegistrationOption : NSObject

- (instancetype)initWithDictionary:(NSDictionary*)dictionary;

@property (readonly, nonatomic, copy) NSString* name;
@property (readonly, nonatomic, copy) NSString* value;
@property (readonly, nonatomic, assign) BOOL isDefault;

@end


NS_ASSUME_NONNULL_END