//
//  OEXRegistrationDescription.h
//  edXVideoLocker
//
//  Created by Jotiram Bhagat on 13/02/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface OEXRegistrationDescription : NSObject

- (instancetype)initWithDictionary:(NSDictionary*)dictionary;
/// @param fields Array of OEXRegistrationFormField
- (instancetype)initWithFields:(NSArray*)fields method:(NSString*)method submitURL:(NSString*)submitURL;

/// HTTP method for registration submission. Typically POST
@property (readonly, nonatomic, copy) NSString* method;
/// URL registration submission.
@property (readonly, nonatomic, copy) NSString* submitUrl;

// Array of OEXRegistrationFormField
@property (readonly, nonatomic, copy) NSArray* registrationFormFields;

@end
