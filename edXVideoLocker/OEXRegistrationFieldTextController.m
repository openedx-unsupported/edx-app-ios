//
//  OEXRegistrationFieldTextController.m
//  edXVideoLocker
//
//  Created by Jotiram Bhagat on 17/02/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

#import "OEXRegistrationFieldTextController.h"
#import "OEXRegistrationFieldTextView.h"
@interface OEXRegistrationFieldTextController ()
    @property(nonatomic,strong)OEXRegistrationFormField *mField;
    @property(nonatomic,strong)OEXRegistrationFieldTextView *mView;
@end

@implementation OEXRegistrationFieldTextController

-(instancetype)initWithRegistrationFormField:(OEXRegistrationFormField *)field{
    self=[super init];
    if(self){
        self.mField=field;
        self.mView=[[OEXRegistrationFieldTextView alloc] init];
        self.mView.instructionMessage=field.instructions;
        self.mView.placeholder=field.label;
    }
    return self;
}

-(NSString *)currentValue{
    return [[self.mView currentValue] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
}

-(UIView *)view{
    
    return self.mView;
    
}

-(BOOL)hasValue{
    return [self currentValue]&& ![[self currentValue] isEqualToString:@""];
}

-(OEXRegistrationFormField *)field{
    return self.mField;
}

-(void)handleError:(NSString *)errorMsg{
    [self.mView setErrorMessage:errorMsg];
}

-(BOOL)isValidInput{
    
    if([self.mField.isRequired boolValue] && ![self hasValue]){
        [self handleError:self.mField.errorMessage.required];
        return NO;
    }
    
    NSInteger length=[[self currentValue] length];
    if(self.mField.restriction.minLength && length < self.mField.restriction.minLength ){
        [self handleError:self.mField.errorMessage.minLenght];
        return NO;
    }
    if(self.mField.restriction.maxLentgh && length > self.mField.restriction.maxLentgh ){
        [self handleError:self.mField.errorMessage.maxLenght];
        return NO;
    }
    
    return YES;
}

-(void)setEnabled:(BOOL)enabled{
    
}

@end
