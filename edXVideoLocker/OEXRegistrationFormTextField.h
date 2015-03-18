//
//  OEXRegistrationFormTextField.h
//  edXVideoLocker
//
//  Created by Jotiram Bhagat on 17/02/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface OEXRegistrationFormTextField : UIView

@property(nonatomic, strong) NSString* errorMessage;
@property(nonatomic, strong) NSString* instructionMessage;
@property(nonatomic, strong) NSString* placeholder;

@property (strong, nonatomic) UITextField* inputView;

-(void)clearError;
-(NSString*)currentValue;

@end
