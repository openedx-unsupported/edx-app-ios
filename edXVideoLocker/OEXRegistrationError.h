//
//  OEXRegistrationError.h
//  edXVideoLocker
//
//  Created by Jotiram Bhagat on 13/02/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface OEXRegistrationError : NSObject
@property(nonatomic, copy) NSNumber* isRequired;
@property(nonatomic, copy) NSString* errMessage;
@end
