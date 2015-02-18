//
//  OEXRegistrationFieldTextAreaController.h
//  edXVideoLocker
//
//  Created by Jotiram Bhagat on 17/02/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OEXRegistrationFieldProtocol.h"
#import "OEXRegistrationFormField.h"
@interface OEXRegistrationFieldTextAreaController : NSObject<OEXRegistrationFieldProtocol>
-(instancetype)initWithRegistrationFormField:(OEXRegistrationFormField *)field;
@end
