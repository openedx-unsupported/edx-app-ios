//
//  OEXRegistrationFieldError.h
//  edXVideoLocker
//
//  Created by Akiva Leffert on 3/13/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface OEXRegistrationFieldError : NSObject

- (id)initWithDictionary:(NSDictionary*)info;

@property (copy, nonatomic, readonly) NSString* userMessage;

@end
