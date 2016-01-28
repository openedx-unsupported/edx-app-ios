//
//  OEXRegistrationDescription.h
//  edXVideoLocker
//
//  Created by Jotiram Bhagat on 13/02/15.
//  Copyright (c) 2015-2016 edX. All rights reserved.
//

NS_ASSUME_NONNULL_BEGIN

@interface OEXRegistrationDescription : NSObject

- (instancetype)initWithDictionary:(NSDictionary*)dictionary;
/// @param fields Array of OEXRegistrationFormField
- (instancetype)initWithFields:(NSArray*)fields method:(NSString*)method submitURL:(NSString*)submitURL;

/// HTTP method for registration submission. Typically POST
@property (readonly, nonatomic, copy, nullable) NSString* method;
/// URL registration submission.
@property (readonly, nonatomic, copy, nullable) NSString* submitUrl;

// Array of OEXRegistrationFormField
@property (readonly, nonatomic, copy, nullable) NSArray* registrationFormFields;

@end

NS_ASSUME_NONNULL_END
