//
//  OEXRegistrationFieldEmailView.h
//  edXVideoLocker
//
//  Created by Jotiram Bhagat on 14/02/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "OEXRegistrationFormTextField.h"
@interface OEXRegistrationFieldEmailView : OEXRegistrationFormTextField

@property(nonatomic,assign)BOOL errorEnabled;
@property(nonatomic,strong)NSString *errorMessage;
@property(nonatomic,strong)NSString *instructionMessage;
-(NSString *)currentValue;
@end
