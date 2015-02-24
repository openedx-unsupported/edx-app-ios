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
    @property(nonatomic,strong)OEXRegistrationFormField *field;
    @property(nonatomic,strong)OEXRegistrationFieldTextView *view;
@end

@implementation OEXRegistrationFieldTextController

-(instancetype)initWithRegistrationFormField:(OEXRegistrationFormField *)field{
    self=[super init];
    if(self){
        self.field=field;
        self.view=[[OEXRegistrationFieldTextView alloc] init];
        self.view.instructionMessage=field.instructions;
        self.view.placeholder=field.label;
    }
    return self;
}

-(NSString *)currentValue{
    return [[self.view currentValue] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
}

-(BOOL)hasValue{
    return [self currentValue]&& ![[self currentValue] isEqualToString:@""];
}

-(void)handleError:(NSString *)errorMsg{
    [self.view setErrorMessage:errorMsg];
}

-(BOOL)isValidInput{
    
    if(self.field.isRequired && ![self hasValue]){
        [self handleError:self.field.errorMessage.required];
        return NO;
    }
    
    NSInteger length=[[self currentValue] length];
    if(self.field.restriction.minLength && length < self.field.restriction.minLength ){
        [self handleError:self.field.errorMessage.minLength];
        return NO;
    }
    if(self.field.restriction.maxLength && length > self.field.restriction.maxLength ){
        [self handleError:self.field.errorMessage.maxLength];
        return NO;
    }
    
    return YES;
}
@end
