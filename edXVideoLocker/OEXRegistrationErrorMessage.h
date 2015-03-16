//
//  OEXRegistrationMessage.h
//  edXVideoLocker
//
//  Created by Jotiram Bhagat on 13/02/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface OEXRegistrationErrorMessage : NSObject
@property(nonatomic, copy, readonly) NSString* required;
@property(nonatomic, copy, readonly) NSString* maxLength;
@property(nonatomic, copy, readonly) NSString* minLength;

-(instancetype)initWithDictionary:(NSDictionary*)dictionary;

@end
