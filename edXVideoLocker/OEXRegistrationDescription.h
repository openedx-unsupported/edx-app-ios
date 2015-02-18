//
//  OEXRegistrationDescription.h
//  edXVideoLocker
//
//  Created by Jotiram Bhagat on 13/02/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface OEXRegistrationDescription : NSObject
@property(nonatomic,copy)NSString *endpoints;
@property(nonatomic,copy)NSString *method;

-(instancetype)initWithDictionary:(NSDictionary *)dictionary;

//array: OEXRegistrationFormField
-(NSArray*)registrationFormFields;

@end
